
################################################################################
## addition

macro ejectsolutions()
  esc(quote
    (isnan(lower_result) || isnan(upper_result)) && return nan(U)

    println(upper_result)
    println(lower_result)
    describe(upper_result)
    describe(lower_result)
    println(upper_result == lower_result)

    (upper_result == lower_result) && return upper_result
  end)
end

@universal function add(a::Ubound, b::Unum)
  lower_result = resolve_lower(a.lower + b)
  upper_result = resolve_upper(a.upper + b)

  @ejectsolutions

  (is_ulp(lower_result) && is_ulp(upper_result)) && return resolve_as_utype!(lower_result, upper_result)
  return B(lower_result, upper_result)
end

@universal add(a::Unum, b::Ubound) = add(b, a)

@universal function add(a::Ubound, b::Ubound)
  lower_result = resolve_lower(a.lower + b.lower)
  upper_result = resolve_upper(a.upper + b.upper)

  @ejectsolutions

  (is_ulp(lower_result) && is_ulp(upper_result)) ? resolve_as_utype!(lower_result, upper_result) : B(lower_result, upper_result)
end
