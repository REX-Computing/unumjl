#unum-comparison.jl

#test equality on unums.

function =={ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #first compare the ubits.... These must be the same or else they aren't equal.
  ((a.flags & UNUM_UBIT_MASK) != (b.flags & UNUM_UBIT_MASK)) && return false
  #next, compare the sign bits...  The only one that spans is zero.
  ((a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK)) && (return (iszero(a) && iszero(b)))
  #because of the phantom bit ensuring a one at the head, the decoded exponent must be identical
  #check if either is nan
  (isnan(a) || isnan(b)) && return false

  _aexp::Int16 = decode_exp(a)
  _bexp::Int16 = decode_exp(b)
  #make sure the exponents are the same, otherwise not equal unless subnormal...
  #but if one of them has a positive exponent, subnormality is impossible.

  issubnormal(a) && (_aexp >= min_exponent(ESS)) && (a = __resolve_subnormal(a))
  issubnormal(b) && (_bexp >= min_exponent(ESS)) && (b = __resolve_subnormal(b))

  (_aexp != _bexp) && return false
  #now that we know that the exponents are the same,
  #the fractions must also be identical
  (a.fraction != b.fraction) && return false
  #the ubit on case is simple - the fsizes must be equal
  ((a.flags & UNUM_UBIT_MASK) == UNUM_UBIT_MASK) && return (a.fsize == b.fsize)
  #so we are left with exact floats at any resolution, ok, or uncertain floats
  #with the same resolution.  These must be equal.
  return true
end

#make sure we have an isequal function that is equivalent to main one.
import Base.isequal
function isequal{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  if isnan(a) && isnan(b)
    return true
  else
    return a == b
  end
end
export isequal

import Base.min
import Base.max
function min{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #adjust them in case they are subnormal
  is_strange_subnormal(a) && (a = __resolve_subnormal(a))
  is_strange_subnormal(b) && (b = __resolve_subnormal(b))

  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    isnegative(a) && return a
    return b
  end
  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    ((_aexp > _bexp) != isnegative(a)) && return a
    return b
  end
  #next criteria, check the fractions
  if (a.fraction != b.fraction)
    ((a.fraction > b.fraction) != isnegative(a)) && return a
    return b
  end
  #finally, check the ubit
  (is_ulp(a) != isnegative(a)) && return a
  return b
end

function max{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #adjust them in case they are subnormal
  is_strange_subnormal(a) && (a = __resolve_subnormal(a))
  is_strange_subnormal(b) && (b = __resolve_subnormal(b))

  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    isnegative(a) && return b
    return a
  end
  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    ((_aexp > _bexp) != isnegative(a)) && return b
    return a
  end
  #next criteria, check the fractions
  if (a.fraction != b.fraction)
    ((a.fraction > b.fraction) != isnegative(a)) && return b
    return a
  end
  #finally, check the ubit
  (is_ulp(a) != isnegative(a)) && return b
  return a
end
export min, max
