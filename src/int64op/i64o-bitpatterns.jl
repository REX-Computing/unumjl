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
`is_all_ones(n)` outputs whether or not all of the bits in an UInt64 or an `ArrayNum`
are one.
`is_all_ones(n, fsize)` does the same, but constrained to a certain fsize.
"""
function is_all_ones{FSS}(n::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds (n.a[idx] != f64) && return false
  end
  return true
end
function is_all_ones(n::UInt64, fsize::UInt16)
  n == mask_top(fsize)
end
function is_all_ones{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  cell_index = (fsize ÷ 0x0040) + o16
  bit_index = fsize % 0x0040
  for idx = 1:cell_index - 1
    @inbounds (n.a[idx] != f64) && return false
  end
  @inbounds return is_all_ones(n.a[cell_index], bit_index)
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
`is_mmr_frac(::ArrayNum)` checks if the fraction looks like mmr.
`is_mmr_frac(::UInt64, ::Type{Val{FSS}})` also checks if the fraction looks like mmr.
"""
function is_mmr_frac{FSS}(n::UInt64, ::Type{Val{FSS}})
  if FSS == 0
    n == z64
  else
    n == mask_top(max_fsize(FSS) - 0x0001)
  end
end
function is_mmr_frac{FSS}(n::ArrayNum{FSS})
  l = __cell_length(FSS)
  for idx = 1:(l - 1)
    @inbounds (n.a[idx] != f64) && return false
  end
  @inbounds return (n.a[l] == 0xFFFF_FFFF_FFFF_FFFE)
end

bool_bottom_bit{FSS}(fraction::UInt64, ::Type{Val{FSS}}) = (bottom_bit(FSS) & fraction) != 0
bool_bottom_bit{FSS}(n::ArrayNum{FSS}) = (n.a[__cell_length(FSS)] & o64) != 0
bool_bottom_bit{ESS,FSS}(x::UnumSmall{ESS,FSS}) = bool_bottom_bit(x.fraction, Val{FSS})
bool_bottom_bit{ESS,FSS}(x::UnumLarge{ESS,FSS}) = bool_bottom_bit(x.fraction)

doc"""
  `Unums.bool_indexed_bit(fraction, index)`
"""
bool_indexed_bit(fraction::UInt64, index::UInt16) = ((t64 >> index) & fraction) != 0
function bool_indexed_bit{FSS}(fraction::ArrayNum{FSS}, index::UInt16)
  cell_index = (index ÷ 0x0040) + o16
  index = index % 0x0040
  bool_indexed_bit(fraction.a[cell_index], index)
end
