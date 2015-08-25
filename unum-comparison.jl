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

  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  #make sure the exponents are the same, otherwise not equal unless subnormal...
  #but if one of them has a positive exponent, subnormality is impossible.
  if (_aexp != _bexp)
    ((_aexp > 0) || (_bexp > 0)) && return false
    #moreover, at least one of them
    (a.exponent != 0) && (b.exponent != 0) && return false
    #now we do a fairly complicated test
    ashift = (a.exponent == 0) ? 63 - msb(a.fraction) : 0
    bshift = (b.exponent == 0) ? 63 - msb(b.fraction) : 0
    #check to make sure we have compatible shifts
    ((_aexp - ashift) != (_bexp - bshift)) && return false
    #then shift and compare.
    return lsh(a.fraction, ashift) == lsh(b.fraction, bshift)
  end
  #now that we know that the exponents are the same,
  #the fractions must also be identical
  (a.fraction != b.fraction) && return false
  #the ubit on case is simple - the fsizes must be equal
  if ((a.flags & UNUM_UBIT_MASK) == UNUM_UBIT_MASK)
    (a.fsize != b.fsize) && return false
  end
  #so we are left with exact floats at any resolution, ok, or uncertain floats
  #with the same resolution.  These must be equal.
  return true
end
