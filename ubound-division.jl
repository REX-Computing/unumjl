#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
#ubound-division.jl

#division on ubounds.

################################################################################
## division

function /{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  aln = is_negative(a.lowbound)
  ahn = is_negative(a.highbound)
  bn = is_negative(b)

  (aln != ahn) && return (bn ? ubound_unsafe(a.highbound / b, a.lowbound / b) : ubound_unsafe(a.lowbound / b, a.highbound / b))
  bn ? ubound_resolve(ubound_unsafe(a.highbound / b, a.lowbound / b)) : ubound_resolve(ubound_unsafe(a.lowbound / b, a.highbound / b))
end

function /{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  bln = is_negative(b.lowbound)

  (bln != is_negative(b.highbound)) && return nan(Unum{ESS,FSS})
  (is_negative(a) != bln) ? ubound_resolve(ubound_unsafe(a / b.lowbound, a / b.highbound)) : ubound_resolve(ubound_unsafe(a / b.highbound, a / b.lowbound))
end

function /{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  signcode::Uint16 = 0
  is_negative(a.lowbound)  && (signcode += 1)
  is_negative(a.highbound) && (signcode += 2)
  is_negative(b.lowbound)  && (signcode += 4)
  is_negative(b.highbound) && (signcode += 8)

  if (signcode == 0) #everything is positive
    ubound_resolve(ubound_unsafe(a.lowbound / b.highbound, a.highbound / b.lowbound))
  elseif (signcode == 1) #only a.lowbound is negative
    ubound_unsafe(a.lowbound / b.lowbound, a.highbound / b.lowbound)
  #signcode 2 is not possible
  elseif (signcode == 3) #a is negative and b is positive
    ubound_resolve(ubound_unsafe(a.highbound / b.lowbound, a.lowbound / b.highbound))
  elseif (signcode == 4) #only b.lowbound is negative
    #b straddles zero so we'll output NaN
    return nan(Unum{ESS,FSS})
  elseif (signcode == 5) #a.lowbound and b.lowbound are negative
    #b straddles zero so we'll output NaN
    return nan(Unum{ESS,FSS})
  #signcode 6 is not possible
  elseif (signcode == 7) #only b.highbound is positive
    #b straddles zero so we'll output NaN
    return nan(Unum{ESS,FSS})
  #signcode 8, 9, 10, 11 are not possible
  elseif (signcode == 12) #b is negative, a is positive
    ubound_resolve(ubound_unsafe(a.highbound / b.lowbound, a.lowbound / b.highbound))
  elseif (signcode == 13) #b is negative, a straddles
    ubound_unsafe(a.highbound / b.highbound, a.lowbound / b.highbound)
  #signcode 14 is not possible
  elseif (signcode == 15) #everything is negative
    ubound_resolve(ubound_unsafe(a.lowbound / b.highbound, a.highbound / b.lowbound))
  else
    println("----")
    println(describe(a))
    println(describe(b))
    throw(ArgumentError("some ubound had incorrect orientation, $signcode."))
  end
end
