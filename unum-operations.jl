#unum-oddsandends.jl
#mathematical odds and ends

#literally calculate the value of the Unum.  Please don't use this for Infs and NaNs

function calculate(x::Unum)
  sign = (x.flags & UNUM_SIGN_MASK != 0) ? -1 : 1
  #the sub`normal case
  if (x.exponent == 0)
    2.0^(x.exponent - 2.0^(x.esize) + 1) * sign * (big(x.fraction) / 2.0^64)
  else #the normalcase
    2.0^(x.exponent - 2.0^(x.esize)) * sign * (1 + big(x.fraction) / 2.0^64)
  end
end
export calculate

#sorts two unums by magnitude (distance from zero), and throws in the calculated
#exponents, while we're at it.  NB.  MAGSORT ignores sign.
function magsort{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)

  if (_aexp < _bexp)                #first parse through the exponents
    (b, a, _bexp, _aexp)
  elseif (_aexp > _bexp)
    (a, b, _aexp, _bexp)
  elseif (a.fraction < b.fraction)  #then parse through the fractions
    (b, a, _bexp, _aexp)
  elseif (a.fraction > b.fraction)
    (a, b, _aexp, _bexp)
  elseif (isulp(a) && !isulp(b))
    (a, b, _aexp, _bexp)
  else
    (b, a, _bexp, _aexp)
  end
end

#note the difference between "more/less", and "next/prev" - next/prev refers
#to position along the number line, "more/less" refers to magnitude along the
#number line.  NB:  __bigger_exact and __smaller_exact do *not* perform checks
#on the properties of their passed values so should be used with caution.

function __more_exact{ESS,FSS}(a::Unum{ESS,FSS})
  #set the location of the added bit:  remember that fsize is the actual length - 1
  location = (isulp(a)) ? a.fsize + 1 : max_fsize(FSS)
  #generate a new superint that represents what we're going to add in.
  delta = __bit_from_top(location, length(a.fraction))
  #add the delta in, making it a
  (carry, fraction) = __carried_add(z64, a.fraction, delta)

  #check the two cases.
  if (carry != 0)
    (esize, exponent) = encode_exp(decode_exp(a) + 1)
    fraction = fraction >> o16
  else
    esize = a.esize
    exponent = a.exponent
  end
  #recalculate fsize, since this is exact, we can deal with ULPs as needed.
  fsize = max_fsize(FSS) - ctz(fraction)

  Unum{ESS,FSS}(fsize, esize, a.flags & UNUM_SIGN_MASK, fraction, exponent)
end

function __resolve_subnormal{ESS,FSS}(a::Unum{ESS,FSS})
  #resolves a subnormal with an "unusual exponent", i.e. when esize is not
  #max_esize.  This is an "unsafe" operation, in that it does not check
  #if the passed value is actually subnormal, or that esize isn't pushed to the brim.
  _aexp::Int16 = decode_exp(a)
  #don't forget to add one, because in theory we're going to want to move that
  #first one PAST the left end of the fraction value.
  _ashl::Uint16 = clz(a.fraction) + 1

  if (_aexp - _ashl) >= min_exponent(ESS)
    (esize, exponent) = encode_exp(_aexp - _ashl + 1) #don't forget the +1 because decode_exp on a subnormal is
    #one off of the actual exponent.
    #constrain the fsize to zero.
    fsize::Uint16 = (_ashl > a.fsize) ? 0 : a.fsize - _ashl
    Unum{ESS,FSS}(fsize, esize, a.flags, (a.fraction << _ashl), exponent)
  else  #then all we have to do is encode it as the deeper exponent.
    #reassign _ashl to be the most we can shift it over.
    _ashl = _aexp - min_exponent(ESS) + 1
    Unum{ESS,FSS}(uint16(a.fsize - _ashl), uint16(1 << ESS - 1), a.flags, a.fraction << _ashl, z64)
  end
end

function __less_exact{ESS,FSS}(a::Unum{ESS,FSS})
  #TODO:  throw in a zero check here.  Maybe?
  #if we're a zero, just return that, otherwise return the result minus 1.

  if (isulp(a))
    #all we have to do is strip the ubit mask.
    unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK)
  else
    #check if it's a subnormal number.  If so, try to move it to the right.
    delta = __bit_from_top(max_fsize(FSS), length(a.fraction))

    #resolve a from (possibly inoptimal subnormal) to optimal subnormal or normal
    canonical_a = issubnormal(a) ? __resolve_subnormal(a) : unum_unsafe(a)
    carry = 1

    (carry, res) = __carried_diff(carry, canonical_a, delta)
    #figure out the exponent.
    _aexp = decode_exp(canonical_a)
    flags = canonical_a.flags & UNUM_SIGN_MASK

    if (carry == 0)
      if (_aexp == min_exponent(ESS))
        #set ourselves to subnormal.
        (esize, exponent) = (mask(ESS), z64)
        fraction = res
      elseif (_aexp > min_exponent(ESS))
        (esize, exponent) = encode_exp(_aexp - 1) #reset it to one below.
        #shift over the fraction by one.
        fraction = res << 1maxintfloat

      else #we must have started off as subnormal.
        (esize, exponent) = (canonical_a.esize, canonical_a.exponent)
        fraction = res
      end
      Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
    else
      Unum{ESS,FSS}(fsize, canonical_a.esize, flags, res, canonical_a.exponent)
    end
  end
end

#next_exact and last_exact operate on the number line as a well-ordered set, so
#they function to run tests on the input and then, if appropriate, pass to the
#repsecting more/less function.  Because these have input tests, they are exported
#and don't have the doubleunderscore prefix.
function next_exact{ESS,FSS}(x::Unum{ESS,FSS})
  is_n_inf(x) && return neg_maxreal(Unum{ESS,FSS})
  iszero(x) && return eps(Unum{ESS,FSS})
  is_pos_mmr(x) && return pos_inf(Unum{ESS,FSS})
  is_pos_inf(x) && return nan(Unum{ESS,FSS})
  (x.flags & UNUM_SIGN_FLAG != 0) && return __less_exact(x)
  return __more_exact(x)
end
function last_exact{ESS,FSS}(x::Unum{ESS,FSS})
  is_neg_inf(x) && return nan(Unum{ESS,FSS})
  is_neg_mmr(x) && return neg_inf(Unum{ESS,FSS})
  is_zero(x) && return neg_eps(Unum{ESS,FSS})
  is_pos_inf(x) && return maxreal(Unum{ESS,FSS})
  (x.flags & UNUM_SIGN_FLAG != 0) && return __more_exact(x)
  return __less_exact(x)
end
export next_exact, last_exact
