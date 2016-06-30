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
      is_negative(b) ? resolve_utype!(hbp, lbp) : resolve_utype!(lbp, hbp)
    else
      is_negative(b) ? B(hbp, lbp) : B(lbp, hbp)
    end
end

@universal function *{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  signcode::UInt16 = 0

  is_negative(a.upper) && (signcode += 1)
  is_negative(a.lower) && (signcode += 2)
  is_negative(b.upper) && (signcode += 4)
  is_negative(b.lower) && (signcode += 8)

  if (signcode == 0) #everything is positive
    lower_result = resolve_lower(a.lower * b.lower)
    upper_result = resolve_upper(a.upper * b.upper)
    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 1) #only a.lowbound is negative
    B(resolve_lower(a.lower * b.upper), resolve_upper(a.upper * b.upper))
  #signcode 2 is not possible
  elseif (signcode == 3) #a is negative and b is positive
    lower_result = resolve_lower(a.lower * b.lower)
    upper_result = resolve_upper(a.upper * b.upper)

    (is_ulp(lower_result) & is_ulp(upper_result)) ? resolve_utype!(lower_result, upper_result) : B(lower_result, upper_result)
  elseif (signcode == 4) #only b.lowbound is negative
    B(resolve_lower(b.lowbound * a.highbound), resolve_upper(b.highbound * a.highbound))
  elseif (signcode == 5) #a.lowbound and b.lowbound are negative
    minchoice1 = b.lowbound * a.highbound
    minchoice2 = b.highbound * a.lowbound
    maxchoice1 = b.lowbound * a.lowbound
    maxchoice2 = b.highbound * a.highbound

    (typeof(minchoice1) <: Ubound) && (minchoice1 = minchoice1.lowbound)
    (typeof(minchoice2) <: Ubound) && (minchoice2 = minchoice2.lowbound)
    (typeof(maxchoice1) <: Ubound) && (maxchoice1 = maxchoice1.highbound)
    (typeof(maxchoice2) <: Ubound) && (maxchoice2 = maxchoice2.highbound)

    ubound_unsafe(min(minchoice1, minchoice2), max(maxchoice1, maxchoice2))
  #signcode 6 is not possible
  elseif (signcode == 7) #only b.highbound is positive
    ubound_unsafe(b.highbound * a.lowbound, b.lowbound * a.lowbound)
  #signcode 8, 9, 10, 11 are not possible
  elseif (signcode == 12) #b is negative, a is positive
    ubound_resolve(ubound_unsafe(b.lowbound * a.highbound, b.highbound * a.lowbound))
  elseif (signcode == 13) #b is negative, a straddles
    ubound_unsafe(b.lowbound * a.highbound, b.lowbound * a.lowbound)
  #signcode 14 is not possible
  elseif (signcode == 15) #everything is negative
    ubound_resolve(ubound_unsafe(a.highbound * b.highbound, a.lowbound * b.lowbound))
  else
    println("----")
    println(describe(a))
    println(describe(b))
    throw(ArgumentError("some ubound had incorrect orientation, $signcode."))
  end
end
=#
