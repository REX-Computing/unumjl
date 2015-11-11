#i64o-bitpatterns.jl

#bitpattern detection of SuperInts - boolean functions which report on

# a helper function for is_exp_zero, and is_frac_zero.  Optimized to be fast.
is_all_zero(a::UInt64) = (a == 0)
@generated function is_all_zero{FSS}(a::ArrayNum{FSS})
  code = :(accum = zero(UInt64))              #set an accumulator to zero.
  for idx = 1:__cell_length(FSS)
    code = :(code; @inbounds accum |= a[idx])   #accumulate bits.
  end
  :(code; accum == 0)                         #check to see if the accumulated quantity is zero.
end

is_not_zero(a::UInt64) = (a != 0)
function is_not_zero{FSS}(a::ArrayNum{FSS})
  code = :(accum = zero(UInt64))
  for idx = 1:__cell_length(FSS)
    code = :(code; @inbounds accum |= a[idx])
  end
  :(code; accum != 0)
end

#is_top checks to see if the top bit of the integer represented by a superint
#is set to one, while all others must be zero.
is_top(a::UInt64) = (a == t64)
function is_top(a::Array{UInt64})
  (first(a) != t64) && return false
  for idx = 2:length(a)
    @inbounds a[idx] != 0 && return false
  end
  true
end

is_not_top(a::UInt64) = (a != t64)
function is_not_top(a::Array{UInt64})
  (first(a) != t64) && return true
  for idx = 2:length(a)
    @inbounds a[idx] != 0 && return true
  end
  false
end
