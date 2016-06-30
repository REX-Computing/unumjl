#unum-sqrs.jl

#square and square root

#computes the square of a unum x.  For ubounds we must do a check.
function sqr{ESS,FSS}(x::Ubound{ESS,FSS})
  signcode::UInt16 = 0
  is_neg_def(x.lowbound) && (signcode += 1)
  is_neg_def(x.highbound) && (signcode += 2)

  #parse through the signcodes
  if signcode == 0
    ubound_resolve(ubound_unsafe(x.lowbound * x.lowbound, x.highbound * x.highbound))
  elseif signcode == 1
    l = is_subnormal(x.lowbound) ? __resolve_subnormal!(x.lowbound) : x.lowbound
    h = is_subnormal(x.highbound) ? __resolve_subnormal!(x.highbound) : x.highbound
    (v, _) = magsort(l, h)
    ubound_unsafe(zero(Unum{ESS,FSS}), v * v)
  #signcode 2 is impossible
  elseif signcode == 3
    ubound_resolve(ubound_unsafe(x.highbound * x.highbound, x.lowbound * x.lowbound))
  end
end

export sqr
