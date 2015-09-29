#unum-sqrs.jl

#square and square root

#computes the square of a unum x.  For unums there is no difference from multiplication.
function sqr{ESS,FSS}(x::Unum{ESS,FSS})
  return x * x
end

export sqr
