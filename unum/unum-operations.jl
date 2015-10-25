#unum-oddsandends.jl
#mathematical odds and ends

#literally calculate the value of the Unum.  Please don't use this for Infs and NaNs

function superintval(v::SuperInt)
  (typeof(v) == Uint64) && return big(v)
  sum = big(0)
  for i = 1:length(v)
    sum += big(v[i]) * (big(1) << ((i - 1) * 64))
  end
  sum
end

function calculate(x::Unum)
  sign = (x.flags & UNUM_SIGN_MASK != 0) ? -1 : 1
  #the sub`normal case
  if (x.exponent == 0)
    2.0^(decode_exp(x) + 1) * sign * (superintval(x.fraction)) / 2.0^(64 * length(x.fraction))
  else #the normalcase
    2.0^(decode_exp(x)) * sign * (1 + superintval(x.fraction) / 2.0^(64 * length(x.fraction)))
  end
end
export calculate

#sorts two unums by magnitude (distance from zero), and throws in the calculated
#exponents, while we're at it.  NB.  MAGSORT ignores sign.
function magsort{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  _aexp::Int64 = decode_exp(a)
  _bexp::Int64 = decode_exp(b)

  if (_aexp < _bexp)                #first parse through the exponents
    (b, a, _bexp, _aexp)
  elseif (_aexp > _bexp)
    (a, b, _aexp, _bexp)
  elseif (a.fraction < b.fraction)  #then parse through the fractions
    (b, a, _bexp, _aexp)
  elseif (a.fraction > b.fraction)
    (a, b, _aexp, _bexp)
  elseif (is_ulp(a) && !is_ulp(b))
    (a, b, _aexp, _bexp)
  else
    (b, a, _bexp, _aexp)
  end
end

#note the difference between "more/less", and "next/prev" - next/prev refers
#to position along the number line, "more/less" refers to magnitude along the
#number line.  NB:  __bigger_exact and __smaller_exact do *not* perform checks
#on the properties of their passed values so should be used with caution.

function __outward_exact{ESS,FSS}(a::Unum{ESS,FSS})
  #set the location of the added bit:  remember that fsize is the actual length - 1
  location = (is_ulp(a)) ? a.fsize + 1 : max_fsize(FSS)
  #generate a new superint that represents what we're going to add in.
  delta = __bit_from_top(location, length(a.fraction))
  #add the delta in, making it a
  (carry, fraction) = __carried_add(z64, a.fraction, delta)

  #check the two cases.
  if (carry != 0)
    (esize, exponent) = encode_exp(decode_exp(a) + 1)
    fraction = lsh(fraction, o16)
  else
    esize = a.esize
    exponent = a.exponent
  end
  #recalculate fsize, since this is exact, we can deal with ULPs as needed.
  fsize::Uint16 = __minimum_data_width(fraction)

  Unum{ESS,FSS}(fsize, esize, a.flags & UNUM_SIGN_MASK, fraction, exponent)
end

function __resolve_subnormal{ESS,FSS}(a::Unum{ESS,FSS})
  #resolves a unum with an "unusual exponent", i.e. when esize is not
  #max_esize.  This is an "unsafe" operation, in that it does not check
  #if the passed value is actually subnormal, or that esize isn't pushed to the brim.
  _aexp::Int64 = decode_exp(a)
  #don't forget to add one, because in theory we're going to want to move that
  #first one PAST the left end of the fraction value.
  _ashl::Uint16 = clz(a.fraction) + 1

  is_zero(a) && return zero(Unum{ESS,FSS})

  if (_aexp - _ashl) >= min_exponent(ESS)
    (esize, exponent) = encode_exp(_aexp - _ashl + 1) #don't forget the +1 because decode_exp on a subnormal is
    #one off of the actual exponent.
    #constrain the fsize to zero.
    fsize::Uint16 = (_ashl > a.fsize) ? 0 : a.fsize - _ashl
    Unum{ESS,FSS}(fsize, esize, a.flags, lsh(a.fraction, _ashl), exponent)
  else  #then all we have to do is encode it as the deeper exponent.
    #reassign _ashl to be the most we can shift it over.
    _ashl = _aexp - min_exponent(ESS) + 1
    #take care of the corner case where thete's a single one that we're disappearing
    if (a.fsize + 1 == _ashl)
      Unum{ESS,FSS}(z16, uint16(1 << ESS - 1), a.flags, z64, z64)
    else
      Unum{ESS,FSS}(uint16(a.fsize - _ashl), uint16(1 << ESS - 1), a.flags, a.fraction << _ashl, z64)
    end
  end
end

function __inward_exact{ESS,FSS}(a::Unum{ESS,FSS})
  #TODO:  throw in a zero check here.  Maybe?
  l::Uint16 = length(a.fraction)
  if (is_ulp(a))
    #all we have to do is strip the ubit mask.
    unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK)
  else
    #check if it's a subnormal number.  If so, try to move it to the right.
    #resolve a from (possibly inoptimal subnormal) to optimal subnormal or normal
    is_exp_zero(a) && (a = __resolve_subnormal(a))
    #the next step is pretty trivial.  First, check if a is all zeros.
    if is_frac_zero(a)
      #in which case just make it a bunch of ones, decrement the exponent, and
      #make sure we aren't subnormal, in which case, we just encode as subnormal.
      _aexp::Int64 = decode_exp(a)
      fraction::SuperInt = fillbits(-(max_fsize(FSS) + 1), l)
      fsize::Uint16 = max_fsize(FSS)
      (esize, exponent) = (_aexp == min_exponent(ESS)) ? (max_esize(ESS), z64) : encode_exp(_aexp - 1)
    else
      #even easire.  Just do a direct subtraction.
      fraction = a.fraction - __bit_from_top(max_fsize(FSS) + 1, l)
      fsize = __minimum_data_width(a.fraction)
      esize = a.esize
      exponent = a.exponent
    end
    Unum{ESS,FSS}(fsize, esize, a.flags & UNUM_SIGN_MASK, fraction, exponent)
  end
end

#next_exact and last_exact operate on the number line as a well-ordered set, so
#they function to run tests on the input and then, if appropriate, pass to the
#repsecting more/less function.  Because these have input tests, they are exported
#and don't have the doubleunderscore prefix.
function next_exact{ESS,FSS}(x::Unum{ESS,FSS})
  is_neg_inf(x) && return neg_maxreal(Unum{ESS,FSS})
  is_zero(x) && return eps(Unum{ESS,FSS})
  is_pos_mmr(x) && return pos_inf(Unum{ESS,FSS})
  is_pos_inf(x) && return nan(Unum{ESS,FSS})
  (x.flags & UNUM_SIGN_MASK != 0) && return __inward_exact(x)
  return __outward_exact(x)
end

function prev_exact{ESS,FSS}(x::Unum{ESS,FSS})
  is_neg_inf(x) && return nan(Unum{ESS,FSS})
  is_neg_mmr(x) && return neg_inf(Unum{ESS,FSS})
  is_zero(x) && return neg_eps(Unum{ESS,FSS})
  is_pos_inf(x) && return maxreal(Unum{ESS,FSS})
  (x.flags & UNUM_SIGN_MASK != 0) && return __outward_exact(x)
  return __inward_exact(x)
end
export next_exact, prev_exact

function outward_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_ulp(x) && throw(ArgumentError("function only for exact numbers"))
  #note that infinity will throw NAN, which is just fine.
  is_neg_inf(x) && return nan(Unum{ESS,FSS})
  Unum{ESS,FSS}(max_fsize(FSS), x.esize, x.flags | UNUM_UBIT_MASK, x.fraction, x.exponent)
end
function inward_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_ulp(x) && throw(ArgumentError("function only for exact numbers"))
  is_zero(x) && return nan(Unum{ESS,FSS})
  is_pos_inf(x) && return pos_mmr(Unum{ESS,FSS})
  is_neg_inf(x) && return neg_mmr(Unum{ESS,FSS})
  tx = __inward_exact(x)
  Unum{ESS,FSS}(max_fsize(FSS), tx.esize, x.flags | UNUM_UBIT_MASK, tx.fraction, tx.exponent)
end
function next_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_zero(x) && return pos_sss(Unum{ESS,FSS})
  is_negative(x) && return inward_ulp(x)
  outward_ulp(x)
end
function prev_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_zero(x) && return neg_sss(Unum{ESS,FSS})
  is_negative(x) && return outward_ulp(x)
  inward_ulp(x)
end

export outward_ulp, inward_ulp, next_ulp, prev_ulp
