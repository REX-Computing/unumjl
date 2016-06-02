#unum-convert.jl
#implements conversions between unums and ints, floats.

################################################################################
## UNUM TO UNUM conversion

function __subnormal_ubit_trim{ESS,FSS}(::Type{Unum{ESS,FSS}}, esize::UInt16, fsize::UInt16)
  #this function handles the situation where we're trying to convert a zero ulp
  #into a zero ulp of another size, which may or may not have the appropriate
  #capacity to handle the ulp.
  #calculate the (negative) exponent + 1 on the high value of the subnormal number
  high_value_rep::UInt16 = (0x0001 << esize) + fsize
  #find the appropriate esize to rerepresent this value.

  suggested_esize::UInt16 = 0x000F - leading_zeros(high_value_rep)
  esize::UInt16 = min(suggested_esize, max_esize(ESS))

  suggested_fsize::UInt16 = high_value_rep - (0x0001 << esize)
  fsize::UInt16 = min(suggested_fsize, max_fsize(FSS))

  (esize, fsize)
end

function check_lower_cells{ESS,FSS, DEST_FSS}(x::Unum{ESS,FSS}, ::Type{Val{DEST_FSS}})
  if (DEST_FSS < 7)
    start_idx = 2
    accum = (FSS < 7) ? (x.fraction & mask_bot(DEST_FSS)) : (x.fraction.a[1] & mask_bot(DEST_FSS))
  else
    (__cell_length(DEST_FSS) + 1)
    accum = z64
  end

  for idx = start_idx:__cell_length(FSS)
    accum |= x.fraction.a[idx]
  end

  UNUM_UBIT_MASK * (accum == z64)
end

#int the case that DEST_FSS is strictly less than src FSS, then the opration is to pull the single
#value (if DEST_FSS requires an int64)
function pull_upper_cells{ESS,FSS, DEST_FSS}(src::Unum{ESS,FSS}, ::Type{Val{DEST_FSS}})
  if (DEST_FSS < 7)
    return (FSS < 7) ? src.fraction : src.fraction.a[1]
  else
    return ArrayNum{DEST_FSS}(src.fraction.a[1:__cell_length(DEST_FSS)])
  end
end

#in the case that the DEST_FSS is bigger than or equal to the src FSS, then the relevant operation
#is to simply copy over the cells into a blank array with zeros in the rest of the slots.
function copy_cells{ESS, FSS, DEST_FSS}(src::Unum{ESS,FSS}, ::Type{Val{DEST_FSS}})
  (DEST_FSS < 7) && return src.fraction
  result = zero(ArrayNum{DEST_FSS})
  (FSS < 7) ? (result.a[1] = src.fraction) : (result.a[1:__cell_length(FSS)] = src.fraction.a)
  return result
end

doc"""
  `Unums.full_decode(::Unum,::Type{Val{DEST_FSS}})` decodes a unum value into a
  normalized int64 exponent, fraction, fsize, and ubit.  This can be a costly
  operation, since we don't expect too many conversions between unum types.
"""
function full_decode{ESS, FSS, DEST_FSS}(temp::Unum{ESS, FSS}, ::Type{Val{DEST_FSS}})
  #first, copy x into a new variable.
  leftshift = 0
  if (temp.exponent == 0) #then we have a strictly subnormal (strange or regular) number.  Be prepared to shift left.
    #now, count leading zeros.
    leftshift = clz(temp.fraction) + 1
    #next, shift the shadow fraction to the left appropriately.
    frac_lsh!(temp, leftshift)
  end

  #set exponent and fsize, and a default ubit value.
  exponent = decode_exp(temp) - leftshift
  fsize = min(temp.fsize - leftshift, max_fsize(DEST_FSS))
  ubit = z16

  #reshape the fraction as necessary.
  (DEST_FSS < FSS) && (ubit |= check_lower_cells(temp, Val{DEST_FSS}))
  fraction = (DEST_FSS < FSS) ? pull_upper_cells(temp, Val{DEST_FSS}) : copy_cells(temp, Val{DEST_FSS})

  #full_decode returns the exponent and fraction
  return (exponent, fraction, fsize, ubit)
end


function Base.convert{DEST_ESS,DEST_FSS,SRC_ESS,SRC_FSS}(::Type{Unum{DEST_ESS,DEST_FSS}}, x::Unum{SRC_ESS,SRC_FSS})
  (DEST_ESS == SRC_ESS) && (DEST_FSS == SRC_FSS) && throw(ArgumentError("error attempting to convert the same Unum"))

  #set the type.
  T = (DEST_FSS < 7) ? UnumSmall{DEST_ESS, DEST_FSS} : UnumLarge{DEST_ESS, DEST_FSS}

  #deal with NaN and inf, because those have unusual rules.
  is_nan(x) && return nan(T)
  is_inf(x) && return inf(T, @signof(x))
  is_zero(x) && return zero(T)

  temp = copy(x)

  #first convert to a "universal" format that doesn't have restrictions, or
  #subnormals).  be sure to pass the DEST_FSS, so true_fraction can be the
  #needed type
  (true_exponent, true_fraction, true_fsize, ubit) = full_decode{DEST_FSS}(temp, Val{DEST_FSS})

  #first, do the exponent part..
  (SRC_ESS <= DEST_ESS) && is_mmr(x) && return nan(T)

  #use the buildunum function to build the unum
  buildunum(true_exponent, true_fraction, x.flags | ubit, true_fsize)
end


################################################################################
# convert trampoline: splits a generic unum convert into a specific convert.
function Base.convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Integer)
  (FSS < 7) ? convert(UnumSmall{ESS,FSS}, x) : convert(UnumLarge{ESS,FSS}, x)
end
##################################################################
## INTEGER TO UNUM

const __unsupported_int_types = [BigInt, Int128, UInt128]
#CONVERSIONS - INTEGER -> UNUM
@universal function Base.convert(T::Type{Unum}, i::Integer)
  #currently unsupported:  BigInt, Int128, UInt128
  (typeof(i) in __unsupported_int_types) && throw(ArgumentError("conversion from int type $(typeof(x)) still unsupported"))

  i64val::UInt64 = zero(UInt64)

  #in ESS = 0 we are required to use subnormal one, so this requires
  #special code.
  if (ESS == 0)
    (i == 1) && return one(T)
  end
  #do a zero check
  if (i == 0)
    return zero(T)
  elseif (i < 0)
    #flip the sign and promote the integer to Unt64
    i64val = UInt64(-i)
    flags = UNUM_SIGN_MASK
  else
    #promote to UInt64
    i64val = UInt64(i)
    flags = z16
  end

  #find the msb of x, this will tell us how much to move things
  msbx = 63 - leading_zeros(i64val)
  frac = i64val << (64 - msbx)
  fsize = 0x003f  #set it to 63

  r = buildunum(T, msbx, frac, flags, fsize)

  #check for the "infinity hack" where we accidentally generate infinity by having
  #just the right set of bits.
  res = is_inf(r) ? mmr(T, flags & UNUM_SIGN_MASK) : r

  res
end

#=
##################################################################
## FLOATING POINT CONVERSIONS

#create a type for floating point properties
immutable FProp
  intequiv::Type
  ESS::Int
  FSS::Int
  esize::UInt16
  fsize::UInt16
end

#store floating point properties in a dict
__fp_props = Dict{Type,FProp}(
  Float16 => FProp(UInt16, 3, 4, UInt16(4),  UInt16(9)),
  Float32 => FProp(UInt32, 4, 5, UInt16(7),  UInt16(22)),
  Float64 => FProp(UInt64, 4, 6, UInt16(10), UInt16(51)))

##################################################################
## FLOATS TO UNUM

doc"""
`default_convert` takes floating point numbers and converts them to the equivalent
unums, using the trivial bitshifiting transformation.
"""
@generated function default_convert(x::AbstractFloat)
  (x == BigFloat) && throw(ArgumentError("bigfloat conversion not yet supported"))

  props = __fp_props[x]
  I = props.intequiv
  esize = props.esize
  fsize = props.fsize
  ESS = props.ESS
  FSS = props.FSS

  #generate some bit masks & corresponding shifts
  signbit = (one(UInt64) << (esize + fsize + 2))
  signshift = (esize + fsize + 1)

  exponentbits = (signbit - (1 << (fsize + 1)))
  exponentshift = fsize + 1

  fractionbits = (one(UInt64) << (fsize + 1)) - 1
  fractionshift = 64 - fsize - 1

  quote
    i::UInt64 = reinterpret($I,x)

    flags::UInt16 = (i & $signbit) >> ($signshift)

    exponent = (i & $exponentbits) >> ($exponentshift)

    fraction = (i & $fractionbits) << ($fractionshift)

    isnan(x) && return nan(Unum{$ESS,$FSS})
    isinf(x) && return inf(Unum{$ESS,$FSS}, flags)
    Unum{$ESS,$FSS}($fsize, $esize, flags, fraction, exponent)
  end
end
export default_convert

#helper function to convert from different floating point types.
function Base.convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::AbstractFloat)
  #basically convert to the default unum first as an intermediate, and then
  #convert into the desired unum.
  convert(Unum{ESS,FSS}, default_convert(x))
end

##################################################################
## UNUMS TO FLOAT

for F in [Float16, Float32, Float64]
  @generated function Base.convert{ESS,FSS}(T::Type{F}, x::Unum{ESS,FSS})

    fp = __fp_props[F]
    I = fp.intequiv            #the integer type of the same width as the Float64
    fsize = fp.fsize       #how many bits in the fraction
    esize = fp.esize
    bits = esize + fsize + 1     #how many total bits
    ebias = 2 ^ (esize) - 1   #exponent bias (= _emax)
    emin = -(ebias) + 1           #minimum exponent, not including subnormals.

    quote
      isnan(x) && return convert(T, NaN)
      is_pos_inf(x) && return convert(T, Inf)
      is_neg_inf(x) && return -convert(T, Inf)
      is_zero(x) && return zero(T)

      #create a dummy value that will hold our result.
      res = zero($I)

      #first, transfer the sign bit over.
      res |= (convert($I, x.flags & UNUM_SIGN_MASK) << $bits)

      (unbiased_exp, src_frac, _, __) = decode_exp_frac(x)

      #check to see that unbiased_exp is within appropriate bounds for Float32
      (unbiased_exp > $ebias) && return inf(F) * ((x.flags & UNUM_SIGN_MASK == 0) ? 1 : -1)
      if (unbiased_exp < $emin)
        delta = $emin - unbiased_exp
        unbiased_exp = $emin
        fraction = src_frac[1] >> delta
      else
        fraction = src_frac[1]
      end

      #calculate the rebiased exponent and push it into the result.
      res |= convert($I, unbiased_exp + $ebias) << ($fsize + 1)

      #transfer the fraction bits.
      res |= convert($I, fraction >> (63 - $fsize))
      reinterpret(T, res)
    end
  end
end
=#
