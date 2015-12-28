#ubound-comparison.jl

#runs comparisons on the ubound type

import Base: ==, <, >

#==============================================================================#
#equality comparison
function =={ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  #first, check to make sure that the left and right sides of the unum have the
  #same exact vs. inexact character.
  low_exact = is_exact(a.lower)
  high_exact = is_exact(a.upper)
  (low_exact != is_exact(b.lower)) && return false
  (high_exact != is_exact(b.upper)) && return false

  #in the case they're exact then checking the end bounds is straightforward equality.
  if low_exact
    (a.lower != b.lower) && return false
  else
    println("testing lower bound")
    cmp_lower_bound(a.lower, a.upper) && return false
    println("lower bound ok")
  end

  if high_exact
    (a.upper != b.upper) && return false
  else
    println("testing upper bound")
    cmp_upper_bound(a.lower, a.upper) && return false
    println("upper bound ok")
  end

  return true
end

function =={ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  #resolve the ubound then check against the unum value.
  return false
  #=
  resd = ubound_resolve(a)
  isa(resd, Unum) || return false
  return resd == b
  =#
end

#just flip the previous function to make things easier.
=={ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = (b == a)

#repeat the process, except for isequal.
function Base.isequal{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  return false
end

Base.isequal{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = isequal(b, a)

#==============================================================================#

<{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS}) = a.highbound < b.lowbound
<{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = a < b.lowbound
<{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS}) = a.highbound < b

>{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS}) = a.lowbound > b.highbound
>{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = a > b.highbound
>{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS}) = a.lowbound > b
