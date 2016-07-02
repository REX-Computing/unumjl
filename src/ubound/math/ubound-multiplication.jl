#ubound-multiplication.jl

################################################################################
## multiplication

@universal function mul(a::Unum, b::Ubound)
  b * a
end

@universal function mul(a::Ubound, b::Unum)
    lbp = a.lower * b
    hbp = a.upper * b

    if is_ulp(lbp) && is_ulp(hbp)
      is_negative(b) ? resolve_as_utype!(hbp, lbp) : resolve_as_utype!(lbp, hbp)
    else
      is_negative(b) ? B(hbp, lbp) : B(lbp, hbp)
    end
end

@universal function mul(a::Ubound, b::Ubound)
  signcode::UInt16 = 0

  is_negative(a.upper) && (signcode += 1)
  is_negative(a.lower) && (signcode += 2)
  is_negative(b.upper) && (signcode += 4)
  is_negative(b.lower) && (signcode += 8)

  if (signcode == 0) #everything is positive
    lower_result = resolve_lower(a.lower * b.lower)
    upper_result = resolve_upper(a.upper * b.upper)
    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 1) #only a.lowbound is negative
    B(a.lower * b.upper, a.upper * b.upper)
  #signcode 2 is not possible
  elseif (signcode == 3) #a is negative and b is positive
    lower_result = resolve_lower(a.lower * b.lower)
    upper_result = resolve_upper(a.upper * b.upper)

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 4) #only b.lowbound is negative
    B(b.lower * a.upper, b.upper * a.lower)
  elseif (signcode == 5) #a.lowbound and b.lowbound are negative
    minchoice1 = resolve_lower(b.lower * a.upper)
    minchoice2 = resolve_lower(b.upper * a.lower)
    maxchoice1 = resolve_upper(b.lower * a.lower)
    maxchoice2 = resolve_upper(b.upper * a.upper)

    B(min(minchoice1, minchoice2), max(maxchoice1, maxchoice2))
  #signcode 6 is not possible
  elseif (signcode == 7) #only b.highbound is positive
    B(b.upper * a.lower, b.lower * a.lower)
  #signcode 8, 9, 10, 11 are not possible
  elseif (signcode == 12) #b is negative, a is positive
    lower_result = resolve_lower(b.lower * a.upper)
    upper_result = resolve_upper(b.upper * a.lower)
    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 13) #b is negative, a straddles
    B(b.lower * a.upper, b.lower * a.lower)
  #signcode 14 is not possible
  elseif (signcode == 15) #everything is negative
    lower_result = resolve_lower(a.upper * b.upper)
    upper_result = resolve_upper(a.lower * b.lower)
    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  else
    throw(ArgumentError("error multiplying ubounds $a and $b, throws invalid signcode $signcode."))
  end
end
