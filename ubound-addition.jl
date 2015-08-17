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
