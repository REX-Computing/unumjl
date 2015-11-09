#i64o-constants.jl

#various superint constants and ways of generating them
zero{FSS}(::Type{I64Array{FSS}}) = I64Array{FSS}(zeros(UInt64, __cell_length(FSS)))
#zeroing this out is generated code.
@generated function zero{FSS}(a::Type{I64Array{FSS}})
  l = __cell_length(FSS)
  code = :()
  for idx = 1:l
    @inbounds code = :($code; a.a[$idx] = 0)
  end
  return code
end

@generated function one{FSS}(::Type{I64Array{FSS}})
  l = __cell_length(FSS)
  quote
    arr = zeros(UInt64, $l))
    arr[$l] = 1
    arr
  end
end
@generated function one{FSS}(a::Type{I64Array{FSS}})
  l = __cell_length(FSS)
  code = :()
  for idx = 1:(l-1)
    @inbounds code = :($code; a.a[$idx] = 0)
  end
  :($code, @inbounds a[$l] = 1)
end

@generated function top{FSS}(::Type{I64Array{FSS}})
  l = __cell_length(FSS)
  quote
    arr = zeros(UInt64, $l))
    arr[1] = t64
    arr
  end
end
@generated function top{FSS}(a::Type{I64Array{FSS}})
  l = __cell_length(FSS)
  code = :()
  for idx = 2:l
    @inbounds code = :($code; a.a[$idx] = 0)
  end
  :($code, @inbounds a[1] = t64)
end


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
