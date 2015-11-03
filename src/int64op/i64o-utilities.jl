#i64o-utilities.jl

#__minimum_data_width
#calculates the minimum data width to represent the passed superint.
__minimum_data_width(n::Array{UInt64,1}) = UInt16(max(0, length(n) << 6 - ctz(n) - 1))
  #explanation of formula:
  #length(a) << 6:            total bits in the array representation
  #-ctz(f):                   how many zeros are at the end, we can trim those
  #-1:                        the bit representation (1000...0000) = "1" has
  #                           width 0 as per our definition.
  #max(0, ...):               bit representation of (0000...0000) = "0" also
  #                           has width 0, not width "-1".

#this is a better formula for a single-width unsigned integer representation.
__minimum_data_width(n::UInt64) = UInt16(max(0, 63 - ctz(n)))

#__allones_for length
#checks to see if the object is all ones for the appropriate length.
#keep in mind that zero passed length value is equivalent to one digit.
#this is useful for checking if we're very close to one.

#nb:  -9223372036854775808 is the magic int64 version of 0x8000_0000_0000_0000 and
#we are using the arithmetic rightshift which drags leading ones aloong.
__allones_for_length(n::UInt64, m::UInt16) = (n == UInt64(-9223372036854775808 >> m))

function __allones_for_length(n::Array{UInt64,1}, m::UInt16)
  #first, calculate where our dividing line will fall.
  dividingcell::Integer = div(m, 64) + 1
  for idx = 1:length(n)
    #trichotomy relative to the dividing line.
    if idx < dividingcell
      #if it's before, it should be entirely ones (f64)
      (n[idx] != f64) && return false
    elseif idx == dividingcell
      #if it's on the dividing line, measure what the count will be, we can
      #ping back to the UInt64 version, keeping in mind that zero is strange.
      #remember to decrement by one first.
      (__allones_for_length(n[idx], UInt16(m % 64))) || return false
    else
      #everything coming after the dividing line should be zeros.
      (n[idx] != z64) && return false
    end
  end
  return true
end
