#unum-convert.jl
#implements conversions between unums and ints, floats.

################################################################################
## UNUM TO UNUM

function __rightshift_with_underflow_check(f::UInt64, s::UInt16, flags::UInt16)
  #first generate the mask.
  mask = (1 << s) - 1
  ((f & mask) != 0) && (flags |= UNUM_UBIT_MASK)
  f >>= s
  (f,  flags)
end

function __rightshift_with_underflow_check{FSS}(f::ArrayNum{FSS}, s::UInt16, flags::UInt16)
  #generate the mask holder.
  mask = zero(ArrayNum{FSS})
  #actually generate the mask.
  mask_bot!(mask, max_fsize(FSS) - s)  #double check that this is correct.
  #compare the mask with the target.
  fill_mask!(mask, f)
  is_not_zero(mask) && (flags |= UNUM_UBIT_MASK)
  #right shift.
  rsh!(f, s)
  (f, flags)
end

function Base.convert{DEST_ESS,DEST_FSS,SRC_ESS,SRC_FSS}(::Type{Unum{DEST_ESS,DEST_FSS}}, x::Unum{SRC_ESS,SRC_FSS})

  ############################################
  # TODO:  TURN THIS INTO A GENERATED FUNCTION
  ############################################

  #check for NaN, because that doesn't really follow the rules you expect
  is_nan(x) && return nan(Unum{DEST_ESS, DEST_FSS})

  #and then handle flags
  flags::UInt16 = x.flags

  if (SRC_FSS < 7)
    (destination_exp, src_frac, fsize) = decode_exp_frac(x)
  else
    (destination_exp, src_frac, fsize) = decode_exp_frac(x, ArrayNum{SRC_FSS}(zeros(UInt64, __cell_length(SRC_FSS))))
  end

  #first, do the exponent part..
  (SRC_ESS <= DEST_ESS) && is_mmr(x) && return nan(Unum{DEST_ESS, DEST_FSS})

  #determine properties of the destination type.
  min_exp_subnormal = min_exponent(DEST_ESS, DEST_FSS)
  min_exp_normal = min_exponent(DEST_ESS)
  max_exp = max_exponent(DEST_ESS)

  #check to see if we are beyond the extremes of the numerical range.
  (destination_exp > max_exp) && return mmr(Unum{DEST_ESS,DEST_FSS}, x.flags & UNUM_SIGN_MASK)
  (destination_exp < min_exp_subnormal) && return sss(Unum{DEST_ESS,DEST_FSS}, x.flags & UNUM_SIGN_MASK)

  if (destination_exp < min_exp_normal)
    #set the exponent and esize to be the smallest possible exponent
    esize = max_esize(DEST_ESS)
    exponent = z64
    shft = UInt16(min_exp_normal - destination_exp)
    #change fsize.  If fraction starts out as zero, we're just shifting the virtual
    #one over.
    if (src_frac == 0)
      fsize = shft - o16
      src_frac = t64 >> (shft - 0x0001)
    else
      #recalculate fsize
      fsize = min(fsize + shft, max_fsize(DEST_FSS))
      #rightshift the fraction
      (src_frac, flags) = __rightshift_with_underflow_check(src_frac, shft, flags)
      #add in the the
      set_bit!(src_frac, shft)
    end
  else
    #do the default exponent encoding.  No mucking with fractions necessary.
    (esize, exponent) = encode_exp(destination_exp)
  end

  #set cell_length values
  LENGTH_DEST = __cell_length(DEST_FSS)
  LENGTH_SRC =  __cell_length(SRC_FSS)

  #next, transcribe the fraction.  First, allocate the space necessary for the
  #result.
  fraction = (DEST_FSS > 6) ? zero(ArrayNum{FSS}) : z64

  #First, go through everything between destination length and source length and check to make sure it's zero.
  if (DEST_FSS > 6)
    accum = z64
    for idx = (LENGTH_DEST + 1):LENGTH_SRC
      @inbounds accum |= src_frac[idx]
    end
    (accum != 0) && (flags |= UNUM_UBIT_MASK)
  end

  #next, if DEST_FSS < 7, then do a masking operation.
  if (DEST_FSS < 7)
    @inbounds fraction = mask_top(DEST_FSS) & src_frac[1]
    @inbounds flags |= ((mask_bot(DEST_FSS) & src_frac[1]) != 0) ? UNUM_UBIT_MASK : z16
  else
    for idx = (1:LENGTH_DEST)
      @inbounds fraction[idx] = src_frac[idx]
    end
  end
  #trim fsize, if necessary.
  fsize = min(max_fsize(DEST_FSS), fsize)

  Unum{DEST_ESS, DEST_FSS}(fsize, esize, flags, fraction, exponent)
end


##################################################################
## INTEGER TO UNUM

#CONVERSIONS - INTEGER -> UNUM
@gen_code function Base.convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Integer)
  #in ESS = 0 we are required to use subnormal one, so this requires
  #special code.
  if (ESS == 0)
    @code :((x == 1) && return one(Unum{ESS,FSS}))
  end

  @code quote
    #do a zero check
    if (x == 0)
      return zero(Unum{ESS,FSS})
    elseif (x < 0)
      #flip the sign and promote the integer to Unt64
      x = UInt64(-x)
      flags = UNUM_SIGN_MASK
    else
      #promote to UInt64
      x = UInt64(x)
      flags = z16
    end

    #find the msb of x, this will tell us how much to move things
    msbx = 63 - leading_zeros(x)
    #do a check to see if we should release almost_infinite
    (msbx > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, flags & UNUM_SIGN_MASK)

    #move it over.  One bit should spill over the side.
    frac = x << (64 - msbx)
    #pass the whole shebang to unum_easy.
    r = unum(Unum{ESS,FSS}, flags, frac, msbx)

    #check for the "infinity hack" where we accidentally generate infinity by having
    #just the right set of bits.
    is_inf(r) ? mmr(Unum{ESS,FSS}, flags & UNUM_SIGN_MASK) : r
  end
end

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
__fp_props = Dict{Type{AbstractFloat},FProp}(
  Float16 => FProp(UInt16, 3, 4, UInt16(4),  UInt16(9)),
  Float32 => FProp(UInt32, 4, 5, UInt16(7),  UInt16(22)),
  Float64 => FProp(UInt64, 4, 6, UInt16(10), UInt16(51)))

##################################################################
## FLOATS TO UNUM

doc"""
`default_convert` takes floating point numbers and converts them to the equivalent
unums, using the trivial bitshifiting transformation.
"""
@gen_code function default_convert(x::AbstractFloat)
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

  @code quote
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
@gen_code function convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::AbstractFloat)
  #currently converting from bigfloat is not allowed.
  #retrieve the floating point properties of the type to convert from.
end

##################################################################
## UNUMS TO FLOAT
#=
#a generator that makes float conversion functions, to DRY production of conversions
function __u_to_f_generator(T::Type)
  #grab and/or calculate things from the properties dictionary.
  fp = __fp_props[T]
  I = fp.intequiv            #the integer type of the same width as the Float64
  _esize = fp.esize       #how many bits in the exponent
  _fsize = fp.fsize       #how many bits in the fraction
  _bits = _esize + _fsize + 1     #how many total bits
  _ebias = 2 ^ (_esize - 1) - 1   #exponent bias (= _emax)
  _emin = -(_ebias) + 1           #minimum exponent

  #generates an anonymous function that releases a floating point for an unum
  function(x::Unum)
    #DEAL with Infs, NaNs, and subnormals.
    isnan(x) && return nan(T)
    is_pos_inf(x) && return inf(T)
    is_neg_inf(x) && return -inf(T)
    is_zero(x) && return zero(T)

    #create a dummy value that will hold our result.
    res = zero(I)
    #first, transfer the sign bit over.
    res |= (convert(I, x.flags) & convert(I, 2)) << (_bits - 2)

    #check to see if the unum is subnormal
    if is_exp_zero(x)
      #measure the msb significant bit of x.fraction and we'll move the exponent to that.
      shift::UInt16 = leading_zeros(x.fraction) + 1
      #shift the fraction over
      fraction = x.fraction << shift
      #remember, subnormal exponents have +1 to their 'actual' exponent.
      unbiased_exp = decode_exp(x) - shift + 1
    else
      #next, transfer the exponent
      fraction = x.fraction
      unbiased_exp = decode_exp(x)
    end

    #check to see that unbiased_exp is within appropriate bounds for Float32
    (unbiased_exp > _ebias) && return inf(T) * ((x.flags & UNUM_SIGN_MASK == 0) ? 1 : -1)
    (unbiased_exp < _emin) && return zero(T) * ((x.flags & UNUM_SIGN_MASK == 0) ? 1 : -1)

    #calculate the rebiased exponent and push it into the result.
    res |= convert(I, unbiased_exp + _ebias) << _fsize

    #finally, transfer the fraction bits.
    res |= convert(I, last(fraction) & mask(x.fsize + 1 > _bits ? -_bits : -(x.fsize + 1)) >> (64 - _fsize))
    reinterpret(T,res)[1]
  end
end

#create the generator functions
__u_to_16f = __u_to_f_generator(Float16)
__u_to_32f = __u_to_f_generator(Float32)
__u_to_64f = __u_to_f_generator(Float64)

#bind these to the convert for multiple dispatch purposes.
convert(::Type{Float16}, x::Unum) = __u_to_16f(x)
convert(::Type{Float32}, x::Unum) = __u_to_32f(x)
convert(::Type{Float64}, x::Unum) = __u_to_64f(x)
=#
