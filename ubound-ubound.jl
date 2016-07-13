#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
#unum-ubound.jl

function __check_block_ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  (a > b) && throw(ArgumentError("ubound built backwards: $(bits(a, " ")) > $(bits(b, " "))"))
end

#basic ubound type, which contains two unums, as well as some properties of ubounds

immutable Ubound{ESS,FSS} <: Utype
  lowbound::Unum{ESS,FSS}
  highbound::Unum{ESS,FSS}
end

#unsafe constructor
function ubound_unsafe{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  if __unum_isdev()
    #check to make sure that a < b
    __check_block_ubound(a, b)
  end
  Ubound(a, b)
end
function ubound_unsafe{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  if __unum_isdev()
    __check_block_ubound(a.highbound, b)
  end
  Ubound(a.lowbound, b)
end
function ubound_unsafe{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  if __unum_isdev()
    __check_block_ubound(a, b.lowbound)
  end
  Ubound(a, b.highbound)
end
function ubound_unsafe{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  if __unum_isdev()
    __check_block_ubound(a.highbound, b.highbound)
    __check_block_ubound(a.lowbound, b.lowbound)
  end
  Ubound(a.lowbound, b.highbound)
end

#safe constructors
function ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  __check_block_ubound(a, b)
  Ubound(a, b)
end

export Ubound, ubound, ubound_unsafe

export describe
function describe{ESS,FSS}(b::Ubound{ESS,FSS}, s=" ")
  highval = is_ulp(b.highbound) ? next_exact(b.highbound) : b.highbound
  hightext = is_pos_mmr(b.highbound) ? "mmr{$ESS, $FSS}" : string(calculate(highval))
  hightext = is_pos_sss(b.highbound) ? "sss{$ESS, $FSS}" : hightext
  hightext = is_neg_sss(b.highbound) ? "-sss{$ESS, $FSS}" : hightext
  lowval = is_ulp(b.lowbound) ? prev_exact(b.lowbound) : b.lowbound
  lowtext = is_neg_mmr(b.lowbound) ? "-mmr{$ESS, $FSS}" : string(calculate(lowval))
  lowtext = is_pos_sss(b.lowbound) ? "sss{$ESS, $FSS}" : lowtext
  lowtext = is_neg_sss(b.lowbound) ? "-sss{$ESS, $FSS}" : lowtext
  string("$(bits(b.lowbound, s)) -> $(bits(b.highbound, s)) (aka ", lowtext, " -> ", hightext ," )")
end
import Base.bits
bits(b::Ubound) = describe(b, "")
export bits

function __ubound_helper{ESS,FSS}(a::Unum{ESS,FSS}, lowbound::Bool)
  is_ulp(a) && return unum_unsafe(a)
  is_zero(a) && return sss(Unum{ESS,FSS}, lowbound ? z16 : UNUM_SIGN_MASK)
  (is_negative(a) != lowbound) ? outward_ulp(a) : inward_ulp(a)
end

#creates a open ubound from two unums, a < b
function open_ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #match the sign masks for the case of a or b being zero.
  ulp_a = __ubound_helper(a, true)
  ulp_b = __ubound_helper(b, false)
  ubound_unsafe(ulp_a, ulp_b)
end

#converts a Ubound into a unum, if applicable.  Otherwise, drop the ubound.
function ubound_resolve{ESS,FSS}(b::Ubound{ESS,FSS})
  #if both are identical, then we can resolve this ubound immediately
  (b.lowbound == b.highbound) && return b.lowbound
  #cache the length of these unums
  l::UInt16 = length(b.lowbound.fraction)

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
      trim::UInt16 = 0
    elseif smaller.fsize > bigger.fsize #mask out the lower bits
      eligible = (smaller.fraction & fillbits(bigger.fsize, l)) == zeros(UInt64, l)
      trim = bigger.fsize
    else
      eligible = ((bigger.fraction & fillbits(smaller.fsize, l)) == zeros(UInt64, l))
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

include("ubound-operators.jl")
include("ubound-comparison.jl")
