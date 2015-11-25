#unum-convert.jl
#implements conversions between unums and ints, floats.

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
  (x == BigFloat) && throw(ArgumentError("bigfloat conversion not yet supported"))
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
