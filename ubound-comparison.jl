#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
#ubound-comparison.jl

#runs comparisons on the ubound type

#==============================================================================#
#equality comparison
function =={ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS})
  #first, check to make sure that the left and right sides of the unum have the
  #same exact vs. inexact character.
  low_exact = is_exact(a.lowbound)
  high_exact = is_exact(a.highbound)
  (low_exact != is_exact(b.lowbound)) && return false
  (high_exact != is_exact(b.highbound)) && return false

  #in the case they're exact then checking the end bounds is straightforward equality.
  if low_exact
    (a.lowbound != b.lowbound) && return false
  else
    (prev_exact(a.lowbound) != prev_exact(b.lowbound)) && return false
  end

  if high_exact
    (a.highbound != b.highbound) && return false
  else
    (next_exact(a.highbound) != next_exact(a.highbound)) && return false
  end

  return true
end

function =={ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  #resolve the ubound then check against the unum value.
  resd = ubound_resolve(a)
  isa(resd, Unum) || return false
  return resd == b
end

#just flip the previous function to make things easier.
=={ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = (b == a)

import Base.isequal
#repeat the process, except for isequal.
function isequal{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  resd = ubound_resolve(a)
  isa(resd, Unum) || return false
  return isequal(resd, b)
end

isequal{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = isequal(b, a)
export isequal

#==============================================================================#

<{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS}) = a.highbound < b.lowbound
<{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = a < b.lowbound
<{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS}) = a.highbound < b

>{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS}) = a.lowbound > b.highbound
>{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = a > b.highbound
>{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS}) = a.lowbound > b
