#unum-sqrs.jl

#square and square root

#computes the square of a unum x.  For unums there is no difference from multiplication.
function sqr{ESS,FSS}(x::Unum{ESS,FSS})
  return x * x
end

#overload the power_by_squaring function to allow for the defalt integer power
#thing to work correctly.

function _rawpow(x, p::Integer)
  if p == 1
    return copy(x)
  elseif p == 0
    return one(U)
  elseif p == 2
    return x * x
  elseif iseven(p)
    t = _rawpow(x, p ÷ 2)
    return t * t
  else
    return x * _rawpow(x, p - 1)
  end
end

function pow(x, p::Integer)
  if p == 1
    return copy(x)
  elseif p == 0
    return one(x)
  elseif p == 2
    return sqr(x)
  elseif p < 0
    throw(DomainError())
  end
  #set up the number of iterations we do the multiply.
  iseven(p) ? sqr(_rawpow(x, p ÷ 2)) : x * _rawpow(x, p - 1)
end

import Base.^
@universal ^(x::Unum, p::Integer) = pow(x, p)
@universal ^(x::Ubound, p::Integer) = pow(x, p)

export sqr
