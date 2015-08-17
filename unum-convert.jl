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
    x = uint64(-x)
    flags = uint16(0b10)
  else
    x = uint64(x)
    flags = uint16(0b0)
  end

  #find the msb and lsb
  (lsbx, msbx) = lsbmsb(x)

  #work with the exponent
  esize = msbx == 0 ? zero(Uint16) : msb(msbx)
  exponent = msbx + 1 << esize #add in the bias

  #work with the fraction
  fsize = (lsbx == msbx) ? zero(Uint16) : uint16(msbx - lsbx - 1)
  fraction = uint64(x) << (64 - msbx) #just push it way over the edge

  Unum{ESS,FSS}(fsize, esize, flags, fraction, uint64(exponent))
end

#create a type for floating point properties
immutable FProp
  intequiv::Type
  esize::Integer
  fsize::Integer
end

#store floating point properties in a dict
__fp_props = {
  Float16 => FProp(Uint16, 5, 10),
  Float32 => FProp(Uint32, 8, 23),
  Float64 => FProp(Uint64, 11, 52)
}

#a generator that makes float conversion functions, to DRY production of conversions
function __u2fgenerator(T::Type)
  #grab and/or calculate things from the properties dictionary.
  fp = __fp_props[T]
  I = fp.intequiv            #the integer type of the same width as the Float64
  _esize = fp.esize       #how many bits in the exponent
  _fsize = fp.fsize       #how many bits in the fraction
  _bits = _esize + _fsize + 1     #how many total bits
  _ebias = 2 ^ (_esize - 1) - 1   #exponent bias (= _emax)
  _emin = -(_ebias) + 1           #minimum exponent

  function(x::Unum)
    #DEAL with Infs, NaNs, and subnormals.

    #check subnormals.  Is the entire exponent zero?
    if (issubnormal(x))
      #is the entire fraction zero?  Then drop a zero down.
      if (isfraczero(x))
        return zero(T)
      end
      return zero(T)
    end

    #create a dummy value that will hold our result.
    res = zero(I)
    #first, transfer the sign bit over.
    res |= (convert(I, x.flags) & convert(I, 2)) << (_bits - 2)
    #next, transfer the exponent
    unbiased_exp = int(first(x.exponent)) - (2 ^ x.esize)
    #check to see that unbiased_exp is within appropriate bounds for Float32
    if (unbiased_exp < _emin) || (unbiased_exp > _ebias)
      #throw an error
      throw(TypeError)
    end
    #calculate the rebiased exponent and push it into the result.
    res |= convert(I, unbiased_exp + _ebias) << _fsize
    #finally, transfer the fraction bits.
    res |= convert(I, last(x.fraction) & mask(x.fsize + 1 > _bits ? -_bits : -(x.fsize + 1)) >> (64 - _fsize))
    reinterpret(T,res)[1]
  end
end

#create the generator functions (so that we don't trigger the compiler every time)
__convu216 = __u2fgenerator(Float16)
__convu232 = __u2fgenerator(Float32)
__convu264 = __u2fgenerator(Float64)

#bind these to the convert for multiple dispatch purposes.
function convert(::Type{Float16}, x::Unum)
  __convu216(x)
end
function convert(::Type{Float32}, x::Unum)
  __convu232(x)
end
function convert(::Type{Float64}, x::Unum)
  __convu264(x)
end

function __convf2u(ESS,FSS,x)
  fp = __fp_props[typeof(x)]
  #convert the floating point x to its integer equivalent
  I = fp.intequiv            #the integer type of the same width as the Float64
  _esize = fp.esize       #how many bits in the exponent
  _fsize = fp.fsize       #how many bits in the fraction
  _bits = _esize + _fsize + 1     #how many total bits
  _ebias = 2 ^ (_esize - 1) - 1   #exponent bias (= _emax)
  _emin = -(_ebias) + 1           #minimum exponent

  ibits = uint64(reinterpret(I, x)[1])
  #grab the sign
  flags = uint16(ibits & (one(I) << (_esize + _fsize)) >> (_esize + _fsize - 1))
  #grab the exponent part

  (esize, exponent) = encode_exp(int64(ibits & mask(_fsize:(_fsize + _esize - 1)) >> _fsize) - _ebias)

  #grab the fraction part
  fraction = ibits & mask(_fsize) << (64 - _fsize)
  #calculate the fsize from the lsb of the fraction
  fsize = uint16(63 - lsb(fraction))

  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end

#bind to convert for multiple dispatch
function convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float16)
  __convf2u(ESS, FSS, x)
end
function convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float32)
  __convf2u(ESS, FSS, x)
end
function convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float64)
  __convf2u(ESS, FSS, x)
end

export convert
