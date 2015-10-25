#i64o-utilities.jl

#__minimum_data_width
#calculates the minimum data width to represent the passed superint.
__minimum_data_width(n::Array{Uint64,1}) = uint16(max(0, length(n) << 6 - ctz(n) - 1))
  #explanation of formula:
  #length(a) << 6:            total bits in the array representation
  #-ctz(f):                   how many zeros are at the end, we can trim those
  #-1:                        the bit representation (1000...0000) = "1" has
  #                           width 0 as per our definition.
  #max(0, ...):               bit representation of (0000...0000) = "0" also
  #                           has width 0, not width "-1".

#this is a better formula for a single-width unsigned integer representation.
__minimum_data_width(n::Uint64) = uint16(max(0, 63 - ctz(n)))
