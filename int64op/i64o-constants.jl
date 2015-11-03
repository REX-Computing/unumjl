#i64o-constants.jl

#various superint constants and ways of generating them

#generates a superint zero for a given superint length
superzero(l::Integer) = ((l == 1) ? z64 : zeros(UInt64, l))
superone(l::Integer) = ((l == 1) ? o64 : [zeros(UInt64, l - 1), o64])
supertop(l::Integer) = ((l == 1) ? t64 : [t64, zeros(UInt64, l - 1)])

#Generates a single UInt64 array that is all zeros except for a single bit
#flipped, which is the n'th bit from the msb, 0-indexed.
function __bit_from_top(n::Integer, l::Integer)
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
