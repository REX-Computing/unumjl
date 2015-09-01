#unum-ubound.jl

#basic ubound type, which contains two unums, as well as some properties of ubounds

export Ubound
immutable Ubound{ESS,FSS}
  lowbound::Unum{ESS,FSS}
  highbound::Unum{ESS,FSS}
end

export describe
function describe(b::Ubound, s=" ")
  "$(bits(b.lowbound, s)) -> $(bits(b.highbound, s))"
end
import Base.bits
bits(b::Ubound) = describe(b, "")
export bits

function __ubound_helper{ESS,FSS}(a::Unum{ESS,FSS}, lowbound::Bool)
  is_ulp(a) && return unum_unsafe(a)
  iszero(a) && return ssn(Unum{ESS,FSS}, lowbound ? z16 : UNUM_SIGN_MASK)
  (is_negative(a) != lowbound) ? outward_ulp(a) : inward_ulp(a)
end

#creates a open ubound from two unums, a < b
function open_ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #match the sign masks for the case of a or b being zero.
  ulp_a = __ubound_helper(a, true)
  ulp_b = __ubound_helper(b, false)
  Ubound(ulp_a, ulp_b)
end

#converts a Ubound into a unum, if applicable.  Otherwise, drop the ubound.
function ubound_resolve{ESS,FSS}(b::Ubound{ESS,FSS})
  #if both are identical, then we can resolve this ubound immediately
  (b.lowbound == b.highbound) && return b.lowbound
  #cache the length of these unums
  l::Uint16 = length(b.lowbound.fraction)

  #if the sign masks are not equal then we're toast.
  (is_negative(b.lowbound) != is_negative(b.highbound)) && return b
  #lastly, these must both be uncertain unums
  if (is_ulp(b.lowbound)) && (is_ulp(b.highbound))
    #if negative then swap them around.
    (smaller, bigger) = (is_negative(b.lowbound)) ? (b.highbound, b.lowbound) : (b.lowbound, b.highbound)
    #now, find the next exact ulp for the bigger one
    bigger = __outward_exact(bigger)

    #check to see if bigger is at the boundary of two enums.
    if (bigger.fraction == 0) && (bigger.exponent == smaller.exponent + 1)
      #check to see if the smaller fraction is all ones.
      eligible = smaller.fraction == fillbits(-(smaller.fsize + 1), l)
      trim::Uint16 = 0
    elseif smaller.fsize > bigger.fsize #mask out the lower bits
      eligible = (smaller.fraction & fillbits(bigger.fsize, l)) == zeros(Uint64, l)
      trim = bigger.fsize
    else
      eligible = ((bigger.fraction & fillbits(smaller.fsize, l)) == zeros(Uint64, l))
      trim = smaller.fsize
    end
    (eligible) ? Unum{ESS,FSS}(trim, smaller.esize, smaller.flags, smaller.fraction, smaller.exponent) : b
  end

  return b
end

function ==(a::Ubound, b::Ubound)
  (a.lowbound == b.lowbound) && (a.highbound == b.highbound)
end

function isalmostinf(b::Ubound)
  isalmostinf(b.lowbound) || isalmostinf(b.highbound)
end

include("ubound-addition.jl")
