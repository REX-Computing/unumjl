###############################################################################
#subtraction

function -{ESS,FSS}(a::Ubound{ESS,FSS})
  Ubound(-a.highbound, -a.lowbound)
end

function -{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  lb = a.lowbound - b
  hb = a.highbound - b

  (typeof(lb) <: Ubound) && (lb = lb.lowbound)
  (typeof(hb) <: Ubound) && (hb = hb.highbound)
  ubound_resolve(ubound_unsafe(lb, hb))
end

function -{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  lb = a - b.highbound
  hb = a - b.lowbound

  (typeof(lb) <: Ubound) && (lb = lb.lowbound)
  (typeof(hb) <: Ubound) && (hb = hb.highbound)
  ubound_resolve(ubound_unsafe(lb, hb))
end

function -{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  #I'm too lazy to do this explicitly.
  a + (-b)
end
