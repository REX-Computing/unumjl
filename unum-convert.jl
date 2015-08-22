#unum-convert.jl
#implements conversions between unums and ints, floats.
import Base.convert

#PROMOTIONS
#defined promoted versions of this thing.

#CONVERSIONS - INTEGER -> UNUM
function convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Integer)
  #for now, don't handle the uint128 case
  #do a zero check
  if (x == 0)
    return zero(Unum{ESS,FSS})
  elseif (x < 0)
    #promote the integer to int64
    x = uint64(-x)
    flags = UNUM_SIGN_MASK
  else
    #promote to uint64
    x = uint64(x)
    flags = z16
  end

  #find the msb of x, this will tell us how much to move things
  msbx = msb(x)
  #do a check to see if we should release almost_infinite
  (msbx > (1 << (1 << ESS + 1))) && unum_unsafe(maxreal(Unum{ESS,FSS}), UNUM_SIGN_MASK)

  #move it over.  One bit should spill over the side.
  frac = x << (64 - msbx)
  #pass the whole shebang to unum_easy.
  unum_easy(Unum{ESS,FSS}, flags, frac, msbx)
end

#create a type for floating point properties
immutable FProp
  intequiv::Type
  esize::Integer
  fsize::Integer
end

#store floating point properties in a dict
__fp_props = {
  Float16 => FProp(Uint16, uint16(5),  uint16(10)),
  Float32 => FProp(Uint32, uint16(8),  uint16(23)),
  Float64 => FProp(Uint64, uint16(11), uint16(52))
}

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

    #check subnormals.  Is the entire exponent zero?
    #if (issubnormal(x))
      #is the entire fraction zero?  Then drop a zero down.
    #  if (isfraczero(x))
    #    return zero(T)
    #  end
    #  return zero(T)
    #end

    #create a dummy value that will hold our result.
#    res = zero(I)
    #first, transfer the sign bit over.
#    res |= (convert(I, x.flags) & convert(I, 2)) << (_bits - 2)
    #next, transfer the exponent
#    unbiased_exp = int(first(x.exponent)) - (2 ^ x.esize)
    #check to see that unbiased_exp is within appropriate bounds for Float32
#    if (unbiased_exp < _emin) || (unbiased_exp > _ebias)
      #throw an error
#      throw(TypeError)
#    end
    #calculate the rebiased exponent and push it into the result.
#    res |= convert(I, unbiased_exp + _ebias) << _fsize
    #finally, transfer the fraction bits.
#    res |= convert(I, last(x.fraction) & mask(x.fsize + 1 > _bits ? -_bits : -(x.fsize + 1)) >> (64 - _fsize))
#    reinterpret(T,res)[1]
  end
end

#create the generator functions (so that we don't trigger the compiler every time)
#__u_to_16f = __u_to_f_generator(Float16)
#__u_to_32f = __u_to_f_generator(Float32)
#__u_to_64f = __u_to_f_generator(Float64)

#bind these to the convert for multiple dispatch purposes.
#convert(::Type{Float16}, x::Unum) = __u_to_16f(x)
#convert(::Type{Float32}, x::Unum) = __u_to_32f(x)
#convert(::Type{Float64}, x::Unum) = __u_to_64f(x)

#for some reason we need a shim that provides issubnormal support to Float16
import Base.issubnormal
issubnormal(x::Float16) = (x != 0) && ((reinterpret(Uint16, x) & 0x7c00) == 0)
export issubnormal

#helper function to convert from different floating point types.
function __f_to_u(ESS::Integer, FSS::Integer, x::FloatingPoint, T::Type)
  #retrieve the floating point properties of the type to convert from.
  fp = __fp_props[T]

  #some checks for special values
  (isnan(x)) && return nan(Unum{ESS,FSS})
  (isinf(x)) && return ((x < 0) ? ninf(Unum{ESS,FSS}) : pinf(Unum{ESS,FSS}))

  #convert the floating point x to its integer equivalent
  I = fp.intequiv                 #the integer type of the same width
  _esize = fp.esize               #how many bits in the exponent
  _fsize = fp.fsize               #how many bits in the fraction
  _bits = _esize + _fsize + 1     #how many total bits
  _ebias = 2 ^ (_esize - 1) - 1   #exponent bias (= _emax)
  _emin = -(_ebias) + 1           #minimum exponent

  ibits = uint64(reinterpret(I, x)[1])

  fraction = ibits & mask(_fsize) << (64 - _fsize)
  #make some changes to the data for subnormal numbers.
  (x == 0) && return zero(Unum{ESS,FSS})

  #grab the sign
  flags = (ibits & (one(I) << (_esize + _fsize))) != 0 ? UNUM_SIGN_MASK : z16
  #grab the exponent part
  biased_exp::Int16 = ibits & mask(_fsize:(_fsize + _esize - 1)) >> _fsize
  #generate the unbiased exponent and remember to take frac_move into account.
  unbiased_exp::Int16 = biased_exp - _ebias + ((biased_exp == 0) ? 1 : 0)

  if issubnormal(x)
    #keeping in mind that the fraction bits are now left-aligned, calculate
    #how much further we have to push the fraction bits.
    frac_move::Int16 = 64 - msb(fraction)
    fraction = fraction << frac_move
    unbiased_exp -= frac_move
  end

  (esize, exponent) = encode_exp(unbiased_exp)
  #grab the fraction part

  unum(Unum{ESS,FSS}, _fsize, esize, flags, fraction, exponent)
end

#bind to convert for multiple dispatch
convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float16) = __f_to_u(ESS, FSS, x, Float16)
convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float32) = __f_to_u(ESS, FSS, x, Float32)
convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float64) = __f_to_u(ESS, FSS, x, Float64)

export convert
