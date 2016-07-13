#ubound-division.jl

#division on ubounds.

################################################################################
## division

@universal function udiv(a::Ubound, b::Unum)
  aln = is_negative(a.lower)
  ahn = is_negative(a.upper)
  bn = is_negative(b)

  (aln != ahn) && return (bn ? B(a.upper / b, a.lower / b) : B(a.lower / b, a.upper / b))

  outer_result = a.upper / b
  inner_result = a.lower / b

  if is_ulp(inner_result) && is_ulp(outer_result)
    bn ? resolve_as_utype!(outer_result, inner_result) : resolve_as_utype!(inner_result, outer_result)
  else
    bn ? B(outer_result, inner_result) : B(inner_result, outer_result)
  end
end

@universal function udiv(a::Unum, b::Ubound)
  bln = is_negative(b.lower)

  #if the dividend straddles, then we have nan.
  (bln != is_negative(b.upper)) && return nan(U)

  if (is_negative(a) != bln)
    lower_result = resolve_lower(a / b.lower)
    upper_result = resolve_upper(a / b.upper)
    (is_ulp(lower_result) && is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  else
    lower_result = resolve_lower(a / b.upper)
    upper_result = resolve_upper(a / b.lower)
    (is_ulp(lower_result) && is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  end
end

@universal function udiv(a::Ubound, b::Ubound)
  signcode::UInt16 = 0

  #check some divisions by exact zero, which gives exact infinite bounds.
  if is_zero(b.lower)
    #dividing by positive bounds.
    is_positive(a.lower) && return B(a.lower / b.upper, pos_inf(U))
    is_negative(a.upper) && return B(neg_inf(U), a.upper / b.upper)
    is_zero(a.lower) && return B(zero(U), pos_inf(U))
    is_zero(a.upper) && return B(neg_inf(U), zero(U))
    return B(neg_inf(U), pos_inf(U))
  end
  if is_zero(b.upper)
    #dividing by negative bounds
    is_pos_def(a.lower) && return B(neg_inf(U), a.lower / b.lower)
    is_neg_def(a.upper) && return B(a.upper / b.lower, pos_inf(U))
    is_zero(a.lower) && return B(neg_inf(U), zero(U))
    is_zero(a.upper) && return B(zero(U), pos_inf(U))
    return B(neg_inf(U), pos_inf(U))
  end

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
    lower_result = resolve_lower(a.lower / b.upper)
    upper_result = resolve_upper(a.upper / b.lower)

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  else
    throw(ArgumentError("error dividing ubounds $a and $b, throws invalid signcode $signcode."))
  end
end
