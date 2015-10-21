#i64o-superint.jl
#definition of the superint union type and basic things to do with these values.
#the superint is a union of arbitrary length Uint64 and single value Uint64.
#operators are to be defined which seamlessly deal with all these numbers.

#Superints are arranged so that the Uint64 in position 1 is the most significant

#various helpful numbers

#sixteen bit numbers
const z16 = zero(Uint16)
const o16 = one(Uint16)
const f16 = uint16(0xFFFF)

#64 bit numbers
const z64 = zero(Uint64)
const o64 = one(Uint64)
const t64 = 0x8000_0000_0000_0000               #top bit
const f64 = 0xFFFF_FFFF_FFFF_FFFF               #full bits

#note in version 0.4, this will need to change to Union{}
SuperInt = Union(Uint64, Array{Uint64,1})

#generates a superint zero for a given superint length
superzero(l::Integer) = ((l == 1) ? z64 : zeros(Uint64, l))
superone(l::Integer) = ((l == 1) ? o64 : [o64, zeros(Uint64, l - 1)])
supertop(l::Integer) = ((l == 1) ? t64 : [zeros(Uint64, l - 1), t64])

function __copy_superint(a::SuperInt)
  isa(a, Uint64) && return a
  copy(a)
end

function superbits(a::SuperInt)
  isa(a, Uint64) && return bits(a)
  reduce((a, b) -> string(b,a), map(bits, a))
end

#bitof: extracts the bit at (0-indexed) location, using bit masking
function bitof(x::Integer, bit)
  return x & (one(x) << bit)
end
function bitof(x::Array{Uint64,1}, bit)
  cell = (bit >> 6) + 1
  offset = bit % 64
  bitof(x[cell], offset)
end
#the reverse experiment is __bit_from_top.  Generates a single Uint64 array that
#has a single bit flipped, which is the n'th bit from the msb, 1-indexed.
function __bit_from_top(n::Integer, l::Integer)
  (l == 1) && return (t64 >> (n - 1))
  res = zeros(Uint64, l)
  #calculate the cell number
  cellidx = l - ((n - 1) >> 6)
  #figure out what we should replace the cell with.
  cell = uint64(t64 >> ((n - 1) % 64))
  #do the replacement
  res[cellidx] = cell
  #return the result
  res
end

#calculates the fsize of f when it's an exact value.
function __fsize_of_exact(f::SuperInt)
  #multiply the length of f by 64 and then subtract ctz
  #if we're a zero, just return that, otherwise return the result minus 1.
  #use the max() method as suggested by profiling.
  uint16(max(0, length(f) << 6 - ctz(f) - 1))
end

export lsh, rsh
