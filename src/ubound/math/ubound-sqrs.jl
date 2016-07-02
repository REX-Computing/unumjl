#unum-sqrs.jl

#square and square root

#computes the square of a unum x.  For ubounds we must do a check.
@universal function sqr(x::Ubound)
  signcode::UInt16 = 0
  is_neg_def(x.lowbound) && (signcode += 1)
  is_neg_def(x.highbound) && (signcode += 2)

  #parse through the signcode possibilities
  if signcode == 0
    lower_result = resolve_lower(x.lower * x.lower)
    upper_result = resolve_upper(x.upper * x.upper)
    resolve_as_utype(lower_result, upper_result)
  elseif signcode == 1
    B(zero(U), result)
  #signcode 2 is impossible
  elseif signcode == 3
    lower_result = resolve_lower(x.upper * x.upper)
    upper_result = resolve_upper(x.lower * x.lower)
  end
end

export sqr
