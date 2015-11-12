#i64o-bitpatterns.jl

#bitpattern detection of unum integer numbers.  Certain patterns of numbers are
#well suited for detection for certain fraction tasks.  In particular, all-zeros
#is necessary for deciding if number is an exact power of two or zero.  And
#is_top helps detect the subnormal one.

doc"""
`is_all_zero` outputs whether or not all of the bits in an UInt64 or an `ArrayNum`
are zero.  Used for checking zero at the Unum level.
"""
is_all_zero(n::UInt64) = (n == 0)
@generated function is_all_zero{FSS}(n::ArrayNum{FSS})
  code = :(accum = zero(UInt64))              #set an accumulator to zero.
  for idx = 1:__cell_length(FSS)
    code = :($code; @inbounds accum |= n.a[$idx])   #accumulate bits.
  end
  :($code; accum == 0)                         #check to see if the accumulated quantity is zero.
end

doc"""
`is_not_zero` outputs whether or not any of the bits in an UInt64 or an `ArrayNum`
are one.  Used for checking not_zero at the Unum level.
"""
is_not_zero(n::UInt64) = (n != 0)
@generated function is_not_zero{FSS}(n::ArrayNum{FSS})
  code = :(accum = zero(UInt64))
  for idx = 1:__cell_length(FSS)
    code = :($code; @inbounds accum |= n.a[$idx])
  end
  :($code; accum != 0)
end

doc"""
`is_top` outputs whether or not the most significant bit of an UInt64 or an
`ArrayNum` is a one, while the rest are zero.  Used for checking the subnormal
one at the Unum level.
"""
is_top(a::UInt64) = (a == t64)
@generated function is_top{FSS}(n::ArrayNum{FSS})
  code = :((n.a[1] != t64) && return false; accum = zero(UInt64))
  for idx = 2:__cell_length{FSS}
    code = :($code; @inbounds accum |= n.a[idx])
  end
  :($code; accum == 0)
end

doc"""
`is_not_top` outputs if the most significant bit of an UInt64 or an
`ArrayNum` isn't one, or if any of the other bits are one.  Used for checking
the subnormal one at the Unum level.
"""
is_not_top(a::UInt64) = (a != t64)
@generated function is_not_top{FSS}(n::ArrayNum{FSS})
  code = :((n.a[1] != t64) && return true; accum = zero(UInt64))
  for idx = 2:__cell_length{FSS}
    code = :($code; @inbounds accum |= n.a[idx])
  end
  :($code; accum != 0)
end
