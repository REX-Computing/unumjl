#i64o-utilities.jl

#implement the deep copy constructor and the overwriting copy! function for ArrayNums.
Base.copy{FSS}(a::ArrayNum{FSS}) = ArrayNum{FSS}(copy(a.a))
function Base.copy!{FSS}(dest::ArrayNum{FSS}, src::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds dest.a[idx] = src.a[idx]
  end
end

#bits function for hlayer output.
Base.bits{FSS}(a::ArrayNum{FSS}) = mapreduce(bits, (s1, s2) -> string(s1, s2), "", a.a)

#forwarding getindex and setindex!
Base.getindex{FSS}(a::ArrayNum{FSS}, key...) = getindex(a.a, key...)
Base.setindex!{FSS}(a::ArrayNum{FSS}, X, keys...) = setindex!(a.a, X, keys...)

doc"""
`Unums.set_bit!` sets a bit in the ArrayNum referred to by the value b, this bit
is one-indexed with the bit 1 being the most significant.  A value of zero has
undefined effects.  Useful for setting bits after shifting a non-subnormal value.
"""
function set_bit!{FSS}(a::ArrayNum{FSS}, bit::UInt16)
  a_index = ((bit - o16) >> 6) + o16
  b_index = ((bit - o16) % 64)
  @inbounds a.a[a_index] = a.a[a_index] | (0x8000_0000_0000_0000 >> b_index)
  a
end

doc"""
`Unums.set_bit` sets a bit in a UInt64, this bit is one-indexed with the top bit
being the the most significant.  A value of zero has undefined effects.  Useful
for setting bits after shifting a non-subnormal value.
"""
function set_bit(a::UInt64, bit::UInt16)
  a | (0x8000_0000_0000_0000 >> (bit - o16))
end
doc"""
`Unums.frac_set_bit!(x, bit)` sets (one-indexed) bit, which is useful for
"""
@fracproc set_bit bit


#__minimum_data_width
#calculates the minimum data width to represent the passed superint.
function __minimum_data_width{FSS}(n::ArrayNum{FSS})
  res = max(z16, max_fsize(FSS) - ctz(n))
  res == 0xFFFF ? z16 : res
end
  #explanation of formula:
  #length(a) << 6:            total bits in the array representation
  #-trailing_zeros(f):        how many zeros are at the end, we can trim those
  #-1:                        the bit representation (1000...0000) = "1" has
  #                           width 0 as per our definition.
  #max(0, ...):               bit representation of (0000...0000) = "0" also
  #                           has width 0, not width "-1".

#this is a better formula for a single-width unsigned integer representation.
__minimum_data_width(n::UInt64) = (res = max(z16, 0x003F - ctz(n)); res == 0xFFFF ? z16 : res)

doc"""`@zero` looks for the local FSS value and outputs either z64 or zero(ArrayNum{FSS}) as needed.
"""
macro zero()
  esc(:(FSS < 7 ? z64 : ArrayNum{FSS}))
end


#=

doc"""
`__allones_for_fsize` checks to see if the object is all ones for a given
fsize value.  keep in mind that zero passed length value is equivalent to one
digit.  This is useful for checking if fractions have an effective value close
to 1 or 2 (depending on subnormality).  Note: for array ints, the expected
situation is to pass the array.
"""
function __allones_for_fsize(n::UInt64, fsize::UInt16)
  _masktop = mask_top(fsize)
  (n & _masktop) == _masktop
end

@gen_code function __allones_for_fsize{cells}(n::Array{UInt64,1}, fsize::UInt16, ::Val{cells})
  @code quote
    dividingcell::Int = div(fsize, 64) + 1
    sidebits::UInt64 = fsize % 64   #how many bits will be left over in the critical cell.
  end

  for idx = 1:cells
    @code quote
      (dividingcell == 1) && return __allones_for_fsize(n[$idx])
      #dividing line.
      if $idx < dividingcell
        #if it's before, it should be entirely ones (f64)
        (n[$idx] != f64) && return false
      elseif $idx == dividingcell
        #if it's on the dividing line, measure what the count will be, we can
        #ping back to the UInt64 version, keeping in mind that zero is strange.
        (sidebits == 0) && return true
        return __allones_for_fsize(n[$idx], sidebits)
      end
    end
  end
end
=#
