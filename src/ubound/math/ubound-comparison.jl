#ubound-comparison.jl

#runs comparisons on the ubound type

import Base: ==, <, >

if options[:devmode]
  macro matchsign_devmode(a, b)
    esc(quote
      if options[:devmode]
        (@signof a) == (@signof b) || throw(ArgumentError("sign of arguments is mismatched"))
      end
    end)
  end
else
  macro matchsign_devmode(a, b); nothing; end
end

@universal function cmp_inner_bound(a::Unum, b::Unum)
  @matchsign_devmode a b
  resolve_degenerates!(a)
  resolve_degenerates!(b)
  decode_exp(a) == decode_exp(b) || return false
  return a.fraction == b.fraction
end

#TODO:  Make this comparison not depend on making new Unums.
@universal function cmp_outer_bound(a::Unum, b::Unum)
  @matchsign_devmode a b
  resolve_degenerates!(a)
  resolve_degenerates!(b)
  decode_exp(a) == decode_exp(b) || return false
  return outer_exact(a) == outer_exact(b)
end

@universal function cmp_lower_bound(a::Unum, b::Unum)
  @matchsign_devmode a b
  is_positive(a) ? cmp_inner_bound(a, b) : cmp_outer_bound(a, b)
end
@universal function cmp_upper_bound(a::Unum, b::Unum)
  @matchsign_devmode a b
  is_positive(a) ? cmp_outer_bound(a, b) : cmp_inner_bound(a, b)
end
#==============================================================================#
#equality comparison
@universal function ==(a::Ubound, b::Ubound)
  #first, check to make sure that the left and right sides of the unum have the
  #same exact vs. inexact character.  This is a quick first-pass check to make
  low_exact = is_exact(a.lower)
  high_exact = is_exact(a.upper)
  (low_exact != is_exact(b.lower)) && return false
  (high_exact != is_exact(b.upper)) && return false
  #also check signs.
  (@signof(a.lower) != @signof(b.lower)) && (!is_zero(a.lower)) && (!is_zero(b.lower)) && return false
  (@signof(a.upper) != @signof(b.upper)) && (!is_zero(a.upper)) && (!is_zero(b.upper)) && return false

  #in the case they're exact then checking the end bounds is straightforward equality.
  if low_exact
    (a.lower != b.lower) && return false
  else
    cmp_lower_bound(a.lower, b.lower) || return false
  end

  if high_exact
    (a.upper != b.upper) && return false
  else
    cmp_upper_bound(a.upper, b.upper) || return false
  end

  return true
end

function =={ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  #resolve the ubound then check against the unum value.  For now, this returns
  #false.  A correct implementation will do a more detailed check.
  is_exact(b) && return false
  is_exact(a.lower) && return false
  is_exact(a.upper) && return false

  @signof(a.lower) == @signof(b) || return false
  @signof(a.upper) == @signof(b) || return false

  cmp_lower_bound(a.lower, b) || return false
  cmp_upper_bound(a.upper, b) || return false
end

#just flip the previous function to make things easier.
=={ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = (b == a)

#repeat the process, except for isequal.
function Base.isequal{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS})
  return false
end

Base.isequal{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = isequal(b, a)

#==============================================================================#

<{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS}) = a.upper < b.lower
<{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = a < b.lower
<{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS}) = a.upper < b

>{ESS,FSS}(a::Ubound{ESS,FSS}, b::Ubound{ESS,FSS}) = a.lower > b.upper
>{ESS,FSS}(a::Unum{ESS,FSS}, b::Ubound{ESS,FSS}) = a > b.upper
>{ESS,FSS}(a::Ubound{ESS,FSS}, b::Unum{ESS,FSS}) = a.lower > b

@universal ≊(a::Ubound, b::Unum) = simless(a.lower, b) && simless(b, a.upper)
@universal ≊(a::Unum, b::Ubound) = b ≊ a
@universal function ≊(a::Ubound, b::Ubound)
  (simless(b.lower, a.lower) && simless(a.lower, b.upper)) && return true
  (simless(a.lower, b.lower) && simless(b.lower, a.upper)) && return true
  (simless(a.lower, b.lower) && simless(b.upper, a.upper)) && return true
  (simless(b.lower, a.lower) && simless(a.upper, b.upper)) && return true
  return false
end
