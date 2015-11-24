#unum-convert.jl
#implements conversions between unums and ints, floats.
import Base.convert

##################################################################
## INTEGER TO UNUM

#CONVERSIONS - INTEGER -> UNUM
@gen_code function convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Integer)
  if (ESS == 0)
    @code :((x == 1) && return one(Unum{ESS,FSS}))
  end
  
  @code quote
    #do a zero check
    if (x == 0)
      return zero(Unum{ESS,FSS})
    elseif (x < 0)
      #promote the integer to int64
      x = UInt64(-x)
      flags = UNUM_SIGN_MASK
    else
      #promote to UInt64
      x = UInt64(x)
      flags = z16
    end

  #the "one exception" to this is if ESS == 0 and x == 1, where 1 is a subnormal
  #integer.
  (ESS == 0) && (x == 1) && return Unum{ESS,FSS}(z16, z16, flags, t64, z64)

  #find the msb of x, this will tell us how much to move things
  msbx = 63 - leading_zeros(x)
  #do a check to see if we should release almost_infinite
  (msbx > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, flags & UNUM_SIGN_MASK)

  #move it over.  One bit should spill over the side.
  frac = x << (64 - msbx)
  #pass the whole shebang to unum_easy.
  r = unum_easy(Unum{ESS,FSS}, flags, frac, msbx)

  #check for the "infinity hack" where we accidentally generate infinity by having
  #just the right set of bits.
  is_inf(r) ? mmr(Unum{ESS,FSS}, flags & UNUM_SIGN_MASK) : r
end

##################################################################
## FLOATING POINT CONVERSIONS

#create a type for floating point properties
immutable FProp
  intequiv::Type
  esize::Int
  fsize::Int
end

#store floating point properties in a dict
__fp_props = {
  Float16 => FProp(UInt16, UInt16(5),  UInt16(10)),
  Float32 => FProp(UInt32, UInt16(8),  UInt16(23)),
  Float64 => FProp(UInt64, UInt16(11), UInt16(52))
}


##################################################################
## FLOATS TO UNUM

#for some reason we need a shim that provides is_exp_zero support to Float16
import Base.issubnormal
issubnormal(x::Float16) = (x != 0) && ((reinterpret(UInt16, x) & 0x7c00) == 0)
export issubnormal

#helper function to convert from different floating point types.
function __f_to_u(ESS::Int, FSS::Int, x::FloatingPoint, T::Type)
  #retrieve the floating point properties of the type to convert from.
  fp = __fp_props[T]

  #some checks for special values
  (isnan(x)) && return nan(Unum{ESS,FSS})
  (isinf(x)) && return ((x < 0) ? neg_inf(Unum{ESS,FSS}) : pos_inf(Unum{ESS,FSS}))

  #convert the floating point x to its integer equivalent
  I = fp.intequiv                 #the integer type of the same width
  _esize = fp.esize               #how many bits in the exponent
  _fsize = fp.fsize               #how many bits in the fraction
  _bits = _esize + _fsize + 1     #how many total bits
  _ebias = 1 << (_esize - 1) - 1   #exponent bias (= _emax)
  _emin = -(_ebias) + 1           #minimum exponent

  ibits = UInt64(reinterpret(I, x)[1])

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
    frac_move::Int16 = leading_zeros(fraction) + 1
    fraction = fraction << frac_move
    unbiased_exp -= frac_move
  end

  #grab the fraction part

  #check to see if the exponent is too low.
  if (unbiased_exp < min_exponent(ESS))
    #right shift the fraction by the requisite amount.
    shift = min_exponent(ESS) - unbiased_exp
    #make sure we don't have any bits in the shifted segment.
    #first, are there more bits in the shift than the width?
    if (shift > 64)
      ((fraction != 0) || ((shift > 65) && (unbiased_exp != 0))) && (flags |= UNUM_UBIT_MASK)
    else
      ((fraction & mask(shift)) == 0) || (flags |= UNUM_UBIT_MASK)
    end
    #shift fraction by the amount.
    fraction = fraction >> shift
    #punch in the one
    fraction |= ((biased_exp == 0) ? 0 : t64 >> (shift - 1))
    #set to subnormal settings.
    esize = UInt16((1 << ESS) - 1)
    exponent = z64
  elseif (unbiased_exp > max_exponent(ESS))
    return mmr(Unum{ESS,FSS}, flags & UNUM_SIGN_MASK)
  else
    (esize, exponent) = encode_exp(unbiased_exp)
  end

  #for really large FSS fractions pad some zeroes in front.
  (__frac_cells(FSS) > 1) && (fraction = [zeros(UInt64, __frac_cells(FSS) - 1),fraction])

  r = unum(Unum{ESS,FSS}, min(_fsize, max_fsize(FSS)), esize, flags, fraction, exponent)
  #check for the "infinity hack" where we "accidentally" create inf.
  is_inf(r) ? mmr(Unum{ESS,FSS}, flags & UNUM_SIGN_MASK) : r
end

#bind to convert for multiple dispatch
convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float16) = __f_to_u(ESS, FSS, x, Float16)
convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float32) = __f_to_u(ESS, FSS, x, Float32)
convert{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float64) = __f_to_u(ESS, FSS, x, Float64)

##################################################################
## UNUMS TO FLOAT

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

export convert
