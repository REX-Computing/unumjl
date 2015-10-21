#i64o-bitpatterns.jl

#bitpattern detection of SuperInts - boolean functions which report on

# a helper function for is_exp_zero, and is_frac_zero.  Optimized to be fast.
is_all_zero(a::Uint64) = (a == 0)
function is_all_zero(a::Array{Uint64})
  for idx = 1:length(a)
    a[idx] != 0 && return false
  end
  true
end

#note that is_not_zero has a different optimization in the array case.
#this function should be used instead of !is_all_zero.
is_not_zero(a::Uint64) = (a != 0)
function is_not_zero(a::Array{Uint64})
  for idx = 1:length(a)
    a[idx] != 0 && return true
  end
  false
end

#is_top checks to see if the top bit of the integer represented by a superint
#is set to one, while all others must be zero.
is_top(a::Uint64) = (a == t64)
function is_top(a::Array{Uint64})
  (last(a) != t64) && return false
  for idx = 1:(length(a) - 1)
    a[idx] != 0 && return false
  end
  true
end

is_not_top(a::Uint64) = (a != t64)
function is_not_top(a::Array{Uint64})
  (last(a) != t64) && return true
  for idx = 1:(length(a) - 1)
    a[idx] != 0 && return true
  end
  true
end
