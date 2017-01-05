#ubound-division.jl

#division on ubounds.

################################################################################
## division

@universal function udiv(a::Ubound, b::Unum)
  aln = is_negative(a.lower)
  ahn = is_negative(a.upper)
  bn = is_negative(b)

  is_zero(b) && return nan(U)

  (aln != ahn) && return (bn ? B(a.upper / b, a.lower / b) : B(a.lower / b, a.upper / b))

  outer_result = a.upper / b
  inner_result = a.lower / b

  if is_negative(resolve_lower(outer_result))
    outer_result = resolve_lower(outer_result)
    inner_result = resolve_upper(inner_result)
  else
    outer_result = resolve_upper(outer_result)
    inner_result = resolve_lower(inner_result)
  end

  if is_ulp(inner_result) && is_ulp(outer_result)
    bn ? resolve_as_utype!(outer_result, inner_result) : resolve_as_utype!(inner_result, outer_result)
  else
    bn ? B(outer_result, inner_result) : B(inner_result, outer_result)
  end
end

@universal function udiv(a::Unum, b::Ubound)
  #throw nans for division by zero on either side.
  is_zero(b.lower) && return nan(U)
  is_zero(b.upper) && return nan(U)

  blp = is_pos_def(b.lower)
  bup = is_pos_def(b.upper)
  #if the dividend straddles, then we have nan.
  (blp != bup) && return nan(U)
  #check for zero values in the upper part.
  is_zero(a) && return zero(U)

  if is_inf(a)
    #double infs are no fun.
    is_inf(b.lower) && return nan(U)
    is_inf(b.upper) && return nan(U)

    #match the inf with the sign of the product.
    return inf(U, @signof(a) $ @signof(b.lower))
  end

  (b_inner, b_outer) = blp ? (b.lower, b.upper) : (b.upper, b.lower)


  if (is_negative(a) != blp)
    #result should resolve to a positive number.
    lower_result = resolve_lower(a / b_outer)
    upper_result = resolve_upper(a / b_inner)
    (is_ulp(lower_result) && is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  else
    #result should resolve to a negative number.
    lower_result = resolve_lower(a / b_inner)
    upper_result = resolve_upper(a / b_outer)
    (is_ulp(lower_result) && is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  end
end

@universal function udiv(a::Ubound, b::Ubound)
  signcode::UInt16 = 0

  #check some divisions by exact zero, which gives exact infinite bounds.
  is_zero(b.lower) && return nan(U)
  is_zero(b.upper) && return nan(U)

  is_negative(a.lower) && (signcode += 1)
  is_negative(a.upper) && (signcode += 2)
  is_negative(b.lower) && (signcode += 4)
  is_negative(b.upper) && (signcode += 8)

  if (signcode == 0) #everything is positive
    lower_result = resolve_lower(a.lower / b.upper)
    upper_result = resolve_upper(a.upper / b.lower)

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 1) #only a.lowbound is negative
    B(a.lower / b.lower, a.upper / b.lower)
  #signcode 2 is not possible
  elseif (signcode == 3) #a is negative and b is positive
    lower_result = resolve_lower(a.upper / b.lower)
    upper_result = resolve_upper(a.lower / b.upper)

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 4) #only b.lowbound is negative
    #b straddles zero so we'll output NaN
    return nan(U)
  elseif (signcode == 5) #a.lowbound and b.lowbound are negative
    #b straddles zero so we'll output NaN
    return nan(U)
  #signcode 6 is not possible
  elseif (signcode == 7) #only b.highbound is positive
    #b straddles zero so we'll output NaN
    return nan(U)
  #signcode 8, 9, 10, 11 are not possible
  elseif (signcode == 12) #b is negative, a is positive
    lower_result = resolve_lower(a.upper / b.lower)
    upper_result = resolve_upper(a.lower / b.upper)

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 13) #b is negative, a straddles
    B(a.upper / b.upper, a.lower / b.upper)
  #signcode 14 is not possible
  elseif (signcode == 15) #everything is negative
    lower_result = resolve_lower(a.upper / b.lower)
    upper_result = resolve_upper(a.lower / b.upper)

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  else
    throw(ArgumentError("error dividing ubounds $a and $b, throws invalid signcode $signcode."))
  end
end
