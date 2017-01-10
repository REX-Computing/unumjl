#ubound-multiplication.jl

################################################################################
## multiplication

@universal function mul(a::Unum, b::Ubound)
  mul(b, a)
end

@universal function mul(a::Ubound, b::Unum)

  neg_b = is_negative(b)

  lower_result = resolve_lower((neg_b ? a.upper : a.lower) * b)
  upper_result = resolve_upper((neg_b ? a.lower : a.upper) * b)

  @ejectsolutions

  if is_ulp(lower_result) && is_ulp(upper_result)
    resolve_as_utype!(lower_result, upper_result)
  else
    B(lower_result, upper_result)
  end
end

@universal function mul(a::Ubound, b::Ubound)

  signcode::UInt16 = 0

  is_negative(a.lower) && (signcode += 1)
  is_negative(a.upper) && (signcode += 2)
  is_negative(b.lower) && (signcode += 4)
  is_negative(b.upper) && (signcode += 8)

  if (signcode == 0) #everything is positive
    lower_result = resolve_lower(a.lower * b.lower)
    upper_result = resolve_upper(a.upper * b.upper)

    @ejectsolutions

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 1) #only a.lowbound is negative
    lower_result = resolve_lower(a.lower * b.upper)
    upper_result = resolve_upper(a.upper * b.upper)

    @ejectsolutions

    B(lower_result, upper_result)
  #signcode 2 is not possible
  elseif (signcode == 3) #a is negative and b is positive
    lower_result = resolve_lower(a.lower * b.upper)
    upper_result = resolve_upper(a.upper * b.lower)

    @ejectsolutions

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 4) #only b.lowbound is negative
    lower_result = resolve_lower(b.lower * a.upper)
    upper_result = resolve_upper(b.upper * a.lower)

    @ejectsolutions

    B(lower_result, upper_result)
  elseif (signcode == 5) #a.lowbound and b.lowbound are negative
    minchoice1 = resolve_lower(b.lower * a.upper)
    minchoice2 = resolve_lower(b.upper * a.lower)
    maxchoice1 = resolve_upper(b.lower * a.lower)
    maxchoice2 = resolve_upper(b.upper * a.upper)

    (isnan(minchoice1) || isnan(minchoice2) || isnan(maxchoice1) || isnan(maxchoice2)) && return nan(U)

    B(min(minchoice1, minchoice2), max(maxchoice1, maxchoice2))
  #signcode 6 is not possible
  elseif (signcode == 7) #only b.highbound is positive
    lower_result = resolve_lower(b.upper * a.lower)
    upper_result = resolve_upper(b.lower * a.lower)

    @ejectsolutions

    B(lower_result, upper_result)
  #signcode 8, 9, 10, 11 are not possible
  elseif (signcode == 12) #b is negative, a is positive
    lower_result = resolve_lower(b.lower * a.upper)
    upper_result = resolve_upper(b.upper * a.lower)

    @ejectsolutions

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 13) #b is negative, a straddles
    lower_result = resolve_lower(b.lower * a.upper)
    upper_result = resolve_upper(b.lower * a.lower)

    @ejectsolutions

    B(lower_result, upper_result)
  #signcode 14 is not possible
  elseif (signcode == 15) #everything is negative
    lower_result = resolve_lower(a.upper * b.upper)
    upper_result = resolve_upper(a.lower * b.lower)

    @ejectsolutions

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  else
    throw(ArgumentError("error multiplying ubounds $a and $b, throws invalid signcode $signcode."))
  end
end
