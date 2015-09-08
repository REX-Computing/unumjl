#ubound-addition.jl
#addition and subtraction on the ubound class.

################################################################################
## addition
function +{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  lb = a.lowbound + b
  hb = a.highbound + b

  (typeof(lb) <: Ubound) && (lb = lb.lowbound)
  (typeof(hb) <: Ubound) && (hb = hb.highbound)

  #do try to collapse it to a unum.
  ubound_resolve(Ubound(lb, hb))
end
#alias the reverse function.
function +{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  b + a
end
#and for closure, the situation where both operands are Ubounds.
function +{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  lb = a.lowbound + b.lowbound
  hb = a.highbound + b.highbound

  (typeof(lb) <: Ubound) && (lb = lb.lowbound)
  (typeof(hb) <: Ubound) && (hb = hb.highbound)
  ubound_resolve(Ubound(lb, hb))
end
###############################################################################
#subtraction

function -{ESS,FSS}(a::Ubound{ESS,FSS})
  Ubound(-highbound, -lowbound)
end

function -{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  lb = a.lowbound - b
  hb = a.highbound - b

  (typeof(lb) <: Ubound) && (lb = lb.lowbound)
  (typeof(hb) <: Ubound) && (hb = hb.highbound)
  ubound_resolve(Ubound(lb, hb))
end

function -{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  lb = a.lowbound - b
  hb = a.highbound - b

  (typeof(lb) <: Ubound) && (lb = lb.lowbound)
  (typeof(hb) <: Ubound) && (hb = hb.highbound)
  ubound_resolve(Ubound(lb, hb))
end

function -{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  #I'm too lazy to do this explicitly.
  a + (-b)
end

################################################################################
## multiplication
function *{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  b * a
end

function *{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  #two cases.  One:  the ubound doesn't straddle zero
  t::Ubound = isnegative(b) ? Ubound(a.highbound * b, a.lowbound * b) : Ubound(a.lowbound * b, a.highbound * b)

  #attempt to resolve it if we did not straddle zero
  (a.lowbound.flags & UNUM_SIGN_MASK == a.highbound.flags & UNUM_SIGN_MASK) ? ubound_resolve(t) : t
end

function *{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  signcode::Uint16 = 0
  isnegative(a.lowbound)  && (signcode += 1)
  isnegative(a.highbound) && (signcode += 2)
  isnegative(b.lowbound)  && (signcode += 4)
  isnegative(b.highbound) && (signcode += 8)

  if (signcode == 0) #everything is positive
    ubound_resolve(Ubound(a.lowbound * b.lowbound, a.highbound * b.highbound))
  elseif (signcode == 1) #only a.lowbound is negative
    Ubound(a.lowbound * b.highbound, a.highbound * b.highbound)
  #signcode 2 is not possible
  elseif (signcode == 3) #a is negative and b is positive
    ubound_resolve(Ubound(a.lowbound * b.highbound, a.highbound * b.lowbound))
  elseif (signcode == 4) #only b.lowbound is negative
    Ubound(b.lowbound * a.highbound, b.highbound * a.highbound)
  elseif (signcode == 5) #a.lowbound and b.lowbound are negative
    Ubound(min(b.lowbound * a.highbound, b.highbound * a.lowbound), max(b.lowbound * a.lowbound, b.highbound * a.highbound))
  #signcode 6 is not possible
  elseif (signcode == 7) #only b.highbound is positive
    Ubound(b.highbound * a.lowbound, b.lowbound * a.lowbound)
  #signcode 8, 9, 10, 11 are not possible
  elseif (signcode == 12) #b is negative, a is positive
    ubound_resolve(Ubound(b.lowbound * a.highbound, b.highbound * a.lowbound))
  elseif (signcode == 13) #b is negative, a straddles
    Ubound(b.lowbound * a.highbound, b.lowbound * a.lowbound)
  #signcode 14 is not possible
  elseif (signcode == 15) #everything is negative
    ubound_resolve(Ubound(a.lowbound * b.lowbound, a.highbound * b.highbound))
  else
    throw(ArgumentError("some ubound had incorrect orientation."))
  end
end

################################################################################
## division
