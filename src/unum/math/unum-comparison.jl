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

  (is_exp_zero(a) != is_exp_zero(b)) && return false

  (_aexp != _bexp) && return false
  #now that we know that the exponents are the same,
  #the fractions must also be identical
  (a.fraction != b.fraction) && return false

  #the ubit on case is simple - the fsizes must be equal, except if one is mmr.
  if ((a.flags & UNUM_UBIT_MASK) == UNUM_UBIT_MASK)
    is_inf_ulp(a) || return (a.fsize == b.fsize)
    (a.fsize == b.fsize) && return true
    #mmr is categorically going to be equal to the inf_ulp with fsize one less
    #than max_fsize
    _mfsize = max_fsize(FSS)
    (a.fsize == _mfsize) && (b.fsize == _mfsize - o16) && return true
    (b.fsize == _mfsize) && (a.fsize == _mfsize - o16) && return true
    return false
  end
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
  (_aexp < _bexp) && return true
  (_aexp > _bexp) && return false
  #check fractions.

  is_exact(a) & is_exact(b) && return (a.fraction < b.fraction)

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
  _a_inf::Bool = is_inf(a)

  (_b_pos) & (!_a_pos) && return false
  (!_b_pos) & (_a_pos) && return (!(_a_zer & _b_zer))

  #zero can cause problems down the line.
  _a_zer && return !(_b_pos | _b_zer)
  _b_zer && return _a_pos

  #infinity has strange interactions with some inf_ulp values.
  (_a_inf & _a_pos) && return !(is_inf(b) & _b_pos)  #if a is positive infinity, greater than only if b is not.
  (_a_inf & !_a_pos) && return false  #if a is negative infinity, never greater than

  #use this as a trampoline for is_inward.
  _a_pos && return is_inward(b, a)

  return is_inward(a, b)
end
#hopefully the julia compiler knows what to do here.
@universal <(a::Unum, b::Unum) = (b > a)
@universal <=(a::Unum, b::Unum) = !(a > b)
@universal >=(a::Unum, b::Unum) = !(b > a)

@universal function inner(a::Unum, b::Unum)
  #adjust them in case they are subnormal
  resolve_degenerates!(a)
  resolve_degenerates!(b)

  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    return (_aexp < _bexp) ? a : b
  end

  #next criteria, check the fractions
  if (a.fraction != b.fraction)
    return (a.fraction < b.fraction) ? a : b
  end

  #finally, check the ubit
  return is_ulp(a) ? a : b
end

@universal function outer(a::Unum, b::Unum)
  #adjust them in case they are subnormal
  resolve_degenerates!(a)
  resolve_degenerates!(b)

  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    return (_aexp > _bexp) ? a : b
  end

  #next criteria, check the fractions
  lessthanwithubit(a.fraction, b.fraction, min(a.fsize, b.fsize)) ? b : a
end

@universal function Base.min(a::Unum, b::Unum)
  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    return is_negative(a) ? a : b
  end

  return is_negative(a) ? outer(a, b) : inner(a, b)
end

@universal function Base.max(a::Unum, b::Unum)
  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    return is_negative(a) ? b : a
  end

  return is_negative(a) ? inner(a, b) : outer(a, b)
end

doc"""
  `Unums.mag_greater_than_one(a::Unum)`
  outputs true if the magnitude of the passed unum is greater than one.
"""
@universal mag_greater_than_one(a::Unum) = decode_exp(a) >= 0
mag_greater_than_one{FSS}(a::UnumSmall{0,FSS}) = (a.exponent != z64) | frac_top_bit(a)
mag_greater_than_one{FSS}(a::UnumLarge{0,FSS}) = (a.exponent != z64) | frac_top_bit(a)

@universal function ≊(a::Unum, b::Unum)
  !(a < b) && !(b < a)
end

#simless
@universal function simless(a::Unum, b::Unum)
  !(b < a)
end
⪝ = simless
#simgtr
@universal function simgtr(a::Unum, b::Unum)
  !(b > a)
end
⪞ = simgtr

export ≊,⪝,⪞
