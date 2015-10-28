#unum-ubound.jl

#basic ubound type, which contains two unums, as well as some properties of ubounds

immutable Ubound{ESS,FSS} <: Utype
  lowbound::Unum{ESS,FSS}
  highbound::Unum{ESS,FSS}

  function Ubound(a, b)
    __check_block_ubound_dev(a, b)
    new(a, b)
  end
end
#springboard off of the inner constructor type to get this to work.  Yes, inner
#constructors in julia are a little bit confusing.
Ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = Ubound{ESS,FSS}(a,b)

#unsafe constructors
function ubound_unsafe{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  Ubound(a, b)
end

function ubound_unsafe{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  __check_block_ubound_dev(a.highbound, b)
  Ubound(a.lowbound, b)
end

function ubound_unsafe{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  __check_block_ubound_dev(a, b.lowbound)
  Ubound(a, b.highbound)
end

function ubound_unsafe{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  __check_block_ubound_dev(a.highbound, b.highbound)
  __check_block_ubound_dev(a.lowbound, b.lowbound)
  Ubound(a.lowbound, b.highbound)
end

function ubound_unsafe{ESS,FSS}(a::Ubound{ESS,FSS})
  __check_block_ubound_dev(a.lowbound, a.highbound)
  Ubound(a.lowbound, b.lowbound)
end

#guaranteed safe constructors
function ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  __check_block_ubound(a, b)
  Ubound(a, b)
end
#=
function ubound{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  __check_block_ubound(a.highbound, b)
  ubound(a.lowbound, b)
end

function ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS})
  __check_block_ubound(a, b.lowbound)
  ubound(a, b.highbound)
end

function ubound{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  __check_block_ubound(a.highbound, b.highbound)
  __check_block_ubound(a.lowbound, b.lowbound)
  ubound(a.lowbound, b.highbound)
end
=#

export Ubound, ubound, ubound_unsafe

function __open_ubound_helper{ESS,FSS}(a::Unum{ESS,FSS}, lowbound::Bool)
  is_ulp(a) && return unum_unsafe(a)
  is_zero(a) && return sss(Unum{ESS,FSS}, lowbound ? z16 : UNUM_SIGN_MASK)
  (is_negative(a) != lowbound) ? outward_ulp(a) : inward_ulp(a)
end

#creates a open ubound from two unums, a < b, ensures it's open regardless of
#whether or not the values passed are exact.
function open_ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #match the sign masks for the case of a or b being zero.
  ulp_a = __open_ubound_helper(a, true)
  ulp_b = __open_ubound_helper(b, false)
  ubound_unsafe(ulp_a, ulp_b)
end
export open_ubound

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
