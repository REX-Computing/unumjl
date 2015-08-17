#unum-comparison.jl

#test equality on unums.

function ==(a::Unum, b::Unum)
  #first compare the ubits.... These must be the same or else they aren't equal.
  if (a.flags & UBIT_MASK) != (b.flags & UBIT_MASK)
    return false
  end
  #next, compare the sign bits...  The only one that spans is zero.
  if (a.flags & SIGN_MASK) != (b.flags & SIGN_MASK)
    #check to make sure they're both zero
    return (iszero(a) && iszero(b))
  end
  #because of the phantom bit ensuring a one at the head, the decoded exponent must be identical
  if (decode_exp(a) != decode_exp(b))
    return false
  end
  #the fractions must also be identical
  if (a.fraction != b.fraction)
    return false
  end
  #the ubit on case is simple - the fsizes must be equal
  if ((a.flags & UBIT_MASK) == UBIT_MASK) && (!(a.fsize == b.fsize))
    return true
  end
  #so we are left with exact floats at any resolution, ok, or uncertain floats
  #with the same resolution.  These must be equal.
  return true
end
