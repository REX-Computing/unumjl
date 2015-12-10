#i64o-utilities.jl

#bits function for hlayer output.
Base.bits{FSS}(a::ArrayNum{FSS}) = mapreduce(bits, (s1, s2) -> string(s1, s2), "", a.a)

#__minimum_data_width
#calculates the minimum data width to represent the passed superint.
@gen_code function __minimum_data_width{FSS}(n::ArrayNum{FSS})
  l = max_fsize(FSS)
  @code quote
    res = max(z16, $l - ctz(n))
    res == 0xFFFF ? z16 : res
  end
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
