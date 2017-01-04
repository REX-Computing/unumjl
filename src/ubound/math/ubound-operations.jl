
@universal function abs!(x::Ubound)
  if (x.lower.flags & UNUM_SIGN_MASK) != (x.upper.flags & UNUM_SIGN_MASK)
    #number straddles zero.
    x.upper = is_inward(x.lower, x.upper) ? x.upper : x.lower
    #ensure that the upper branch is positive.
    abs!(x.upper)
    #set the lower branch to zero.
    x.lower = zero(U)
  elseif (x.upper.flags & UNUM_SIGN_MASK) != 0  #we might be negative-definite
    (x.lower, x.upper) = (x.upper, x.lower)     #swap 'em
    x.lower.flags $= UNUM_SIGN_MASK
    x.upper.flags $= UNUM_SIGN_MASK
  end  #otherwise do nothing
end

@universal Base.abs(x::Ubound) = abs!(deepcopy(x))
