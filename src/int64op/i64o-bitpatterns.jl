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
function is_all_zero{FSS}(n::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds (n.a[idx] != 0) && return false   #accumulate bits.
  end
  return true
end

doc"""
`is_not_zero` outputs whether or not any of the bits in an UInt64 or an `ArrayNum`
are one.  Used for checking not_zero at the Unum level.
"""
is_not_zero(n::UInt64) = (n != 0)
function is_not_zero{FSS}(n::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds (n.a[idx] != 0) && return true
  end
  return false
end

doc"""
`is_all_ones` outputs whether or not all of the bits in an UInt64 or an `ArrayNum`
are one.
"""
function is_all_ones{FSS}(n::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds (n.a[idx] != f64) && return false
  end
  return true
end

doc"""
`is_not_ones` outputs whether or not any of the bits in an UInt64 or an `ArrayNum`
is zero
"""
function is_not_ones{FSS}(n::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds (n.a[idx] != f64) && return true
  end
  return false
end

doc"""
`is_top` outputs whether or not the most significant bit of an UInt64 or an
`ArrayNum` is a one, while the rest are zero.  Used for checking the subnormal
one at the Unum level.
"""
is_top(a::UInt64) = (a == t64)
function is_top{FSS}(n::ArrayNum{FSS})
  (n.a[1] != t64) && return false
  for idx = 2:__cell_length(FSS)
    @inbounds (n.a[idx] != 0) && return false
  end
  return true
end

doc"""
`top_bit` outputs whether or not the top bit is one.
"""
top_bit(a::UInt64) = (a & t64) != z64
top_bit{FSS}(a::ArrayNum{FSS}) = @inbounds top_bit(a.a[1])
@universal frac_top_bit(a::Unum) = top_bit(a.fraction)

doc"""
`is_not_top` outputs if the most significant bit of an UInt64 or an
`ArrayNum` isn't one, or if any of the other bits are one.  Used for checking
the subnormal one at the Unum level.
"""
is_not_top(a::UInt64) = (a != t64)
function is_not_top{FSS}(n::ArrayNum{FSS})
  (n.a[1] != t64) && return true
  for idx = 2:__cell_length(FSS)
    @inbounds (n.a[idx] != 0) && return true
  end
  return false
end

doc"""
`is_mmr_frac` has the sole purpose of checking if the fraction looks like mmr.
"""
function is_mmr_frac{FSS}(n::ArrayNum{FSS})
  l = __cell_length(FSS)
  for idx = 1:(l - 1)
    @inbounds (n.a[idx] != f64) && return false
  end
  return (n.a[l] == 0xFFFF_FFFF_FFFF_FFFE)
end
