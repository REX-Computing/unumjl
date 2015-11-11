#i64o-constants.jl

#various superint constants and ways of generating them
Base.zero{FSS}(::Type{ArrayNum{FSS}}) = ArrayNum{FSS}(zeros(UInt64, __cell_length(FSS)))
Base.zero{FSS}(a::Type{ArrayNum{FSS}}) = ArrayNum{FSS}(zeros(UInt64, __cell_length(FSS)))

doc"""
sets an `ArrayNum` to zero.
"""
@generated function zero!{FSS}(a::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  code = :()
  #unroll the loop that fills the contents of the a with zero.
  for idx = 1:l
    @inbounds code = :($code; a.a[$idx] = 0)
  end
  code
end

@generated function Base.one{FSS}(::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  quote
    arr = zeros(UInt64, $l)
    arr[$l] = 1
    ArrayNum{FSS}(arr)
  end
end

@generated function Base.one{FSS}(a::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  quote
    arr = zeros(UInt64, $l)
    arr[$l] = 1
    ArrayNum{FSS}(arr)
  end
end

@generated function top{FSS}(::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  quote
    arr = zeros(UInt64, $l)
    arr[1] = t64
    ArrayNum{FSS}(arr)
  end
end

@generated function top{FSS}(a::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  quote
    arr = zeros(UInt64, $l)
    arr[1] = t64
    ArrayNum{FSS}(arr)
  end
end
export top

#=
#Generates a single UInt64 array that is all zeros except for a single bit
#flipped, which is the n'th bit from the msb, 0-indexed.
function __bit_from_top(n::Int, l::Int)
  (l == 1) && return (t64 >> n)

  res = zeros(UInt64, l)
  #calculate the cell number
  cellidx = (n >> 6) + 1
  #figure out what we should replace the cell with.
  cell = UInt64(t64 >> (n % 64))
  #do the replacement
  res[cellidx] = cell
  #return the result
  res
end
=#
