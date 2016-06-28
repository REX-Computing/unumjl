#unum-comparison.jl

import Base:  ==, <, >, <=, >=  #this statement is necessary to redefine these functions directly

@universal function ==(a::Unum, b::Unum)
  #first compare the ubits.... These must be the same or else they aren't equal.
  ((a.flags & UNUM_UBIT_MASK) != (b.flags & UNUM_UBIT_MASK)) && return false
  #next, compare the sign bits...  The only one that spans is zero.
  ((a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK)) && (return (is_zero(a) && is_zero(b)))
  #check if either is nan.  Note that NaN != NaN.
  (isnan(a) || isnan(b)) && return false

  #resolve degenerate forms.
  resolve_degenerates!(a)
  resolve_degenerates!(b)

  #first calculate the exponents.
  _aexp::Int64 = decode_exp(a)
  _bexp::Int64 = decode_exp(b)

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

#note that unlike IEEE floating points, 0 === -0 for Unums.  So the only isequal
#exception should be the NaN exception.  In order to achieve this, we take negative
#zero and make it the degenerate zero.  We also collapse fsize and esize to the
#most reasonable value.
@universal function Base.hash(a::Unum, h::UInt)
  #use the full_decode function to extract
  resolve_degenerates!(a)
  is_zero(a) && is_negative(a) && (a.flags &= ~UNUM_SIGN_MASK)

  #now generate the hash.
  h = hash(a.esize << 32 | a.fsize << 16 | a.flags, h)
  h = hash(a.fraction, h)
  h = hash(a.exponent, h)
  h
end

#the corresponding isequal function.
@universal Base.isequal(a::Unum, b::Unum) = (hash(a) == hash(b))

doc"""
  `Unums.is_inward(a::Unum, b::Unum)` tells if a is inward of b.  If
  a and b are both positive,` is_inward(a, b) === a < b`, and if
  a and b are both negative, `is_inward(a, b) === b < a`.
"""
@universal function is_inward(a::Unum, b::Unum)
  #resolve degeneracies to make comparison much much easier..
  resolve_degenerates!(a)
  resolve_degenerates!(b)

  _aexp = decode_exp(a)
  _bexp = decode_exp(b)

  #so now we know that these two have the same sign.
  (_bexp > _aexp) && return true
  (_bexp < _aexp) && return false
  #check fractions.

  #in the case that b is an ulp and a is exact, then exact equality means a is
  #less, otherwise exact equality does not.
  orequal = is_ulp(b) & is_exact(a)

  lessthanwithubit(a.fraction, b.fraction, a.fsize, orequal)
end

@universal function >(a::Unum, b::Unum)
  (is_nan(a) || is_nan(b)) && return false
  _b_pos::Bool = (is_positive(b))
  _a_pos::Bool = (is_positive(a))
  _b_zer::Bool = is_zero(b)
  _a_zer::Bool = is_zero(a)

  (_b_pos) && (!_a_pos) && return false
  (!_b_pos) && (_a_pos) && return (!(_a_zer && _b_zer))

  #zero can cause problems down the line.
  _a_zer && return !(_b_pos || _b_zer)
  _b_zer && return _a_pos

  #use this as a trampoline for is_inward.
  _a_pos && return is_inward(b, a)

  return is_inward(a, b)
end
#hopefully the julia compiler knows what to do here.
@universal <(a::Unum, b::Unum) = (b > a)
@universal <=(a::Unum, b::Unum) = !(a > b)
@universal >=(a::Unum, b::Unum) = !(b > a)

@universal function Base.min(a::Unum, b::Unum)
  #adjust them in case they are subnormal
  resolve_subnormal!(a)
  resolve_subnormal!(b)

  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    is_negative(a) && return a
    return b
  end

  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    ((_aexp > _bexp) != is_negative(a)) && return a
    return b
  end
  #next criteria, check the fractions
  if (a.fraction != b.fraction)
    ((a.fraction > b.fraction) != is_negative(a)) && return a
    return b
  end
  #finally, check the ubit
  (is_ulp(a) != is_negative(a)) && return a
  return b
end

@universal function Base.max(a::Unum, b::Unum)
  #adjust them in case they are subnormal
  resolve_subnormal!(a)
  resolve_subnormal!(b)

  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    isnegative(a) && return b
    return a
  end
  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    ((_aexp > _bexp) != is_negative(a)) && return b
    return a
  end
  #next criteria, check the fractions
  if (a.fraction != b.fraction)
    ((a.fraction > b.fraction) != is_negative(a)) && return b
    return a
  end
  #finally, check the ubit
  (is_ulp(a) != is_negative(a)) && return b
  return a
end

doc"""
  `Unums.mag_greater_than_one(a::Unum)`
  outputs true if the magnitude of the passed unum is greater than one.
"""
@universal mag_greater_than_one(a::Unum) = decode_exp(a) >= 0
mag_greater_than_one{FSS}(a::UnumSmall{0,FSS}) = (a.exponent != z64) | frac_top_bit(a)
mag_greater_than_one{FSS}(a::UnumLarge{0,FSS}) = (a.exponent != z64) | frac_top_bit(a)
