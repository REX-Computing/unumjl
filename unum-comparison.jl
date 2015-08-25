#unum-comparison.jl

#test equality on unums.

function ==(a::Unum, b::Unum)
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

  #strange subnormal checking
  if (a.exponent == 0) || (b.exponent == 0)
    if (_aexp <= 0) && (_bexp <= 0)
      #set shifters, only if they happen to be
      clz_a = clz(a.fraction)
      clz_b = clz(b.fraction)
      #assign a 'shift' value which is how much we would have to shift to
      #align these things.
      ashift::Int16 = (a.exponent == 0) ? clz_a + 1 : 0
      bshift::Int16 = (b.exponent == 0) ? clz_b + 1 : 0
      #reassign _aexp to reflect exponent value of the first position.
      _a_firstpos = ((a.exponent == 0) ? _aexp - ashift + 1 : _aexp)
      _b_firstpos = ((b.exponent == 0) ? _bexp - bshift + 1 : _bexp)
      (_a_firstpos != _b_firstpos) && return false

      if (a.flags & UNUM_UBIT_MASK != 0)
        #calculate the position of the uncertainty bit.  This must also be
        #identical, if they're ULPs
        _a_ubitpos = _aexp - a.fsize
        _b_ubitpos = _bexp - b.fsize

        (_a_ubitpos != _b_ubitpos) && return false
      end

      #then shift and compare.
      (lsh(a.fraction, ashift) != lsh(b.fraction, bshift)) && return false

      return true
    end
  end

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
