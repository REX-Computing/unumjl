#unum-int64op.jl
#various int64 operations that could be helpful across the unum implementation.
#SuperInt is an array

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

#generates a mask of a certain number of bits on the right, or left if negative
function mask(bits::Integer)
  if bits >= 0
    (bits == 64) ? uint64(-1) : uint64((1 << bits) - 1)
  else
    uint64(~mask(64 + bits))
  end
end
#does the same, except with a unit range.
function mask(range::UnitRange)
  uint64((1 << (range.stop + 1)) - (1 << (range.start)))
end

#fill x least significant bits with ones.  Negative numbers fill most sig. bits
#assume there is one cell, if no value has been passed.
function fillbits(n::Integer, cells::Uint16 = 1)
  #kick it to the mask function if there's only one cell.
  if cells == 1
    return mask(n)
  end
  lowlimit::Uint16 = 0
  #generate the cells.
  if n == ((cells << 6)) || (-n == (cells << 6))
    #check to see if we're asking to fill the entire set of cells
    [f64 for i=1:cells]
  elseif n > 0
    #cells filled from the right to the left
    lowlimit = n >> 6
    [[f64 for i=1:lowlimit], mask(n % 64), [z64 for i=lowlimit+2:cells]]
  elseif n < 0
    #cells filled from the left to the right
    lowlimit = (-n) >> 6
    [[z64 for i=lowlimit + 2:cells], mask(n%64), [f64 for i=1:lowlimit]]
  else
    #empty cells
    zeros(Uint64, cells)
  end
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

#iterative leftshift and rightshift operations on Array SuperInts
function lsh(a::SuperInt,b::Integer)
  (typeof(a) == Uint64) && return a << b
  #calculate how many cells apart our two ints shall be.
  celldiff = b >> 6
  #calculate how much we have to shift
  shift = b % 64
  #as a courtesy, generate a new array so we don't clobber the old one.
  l = length(a)
  res = zeros(Uint64, l)
  for (idx = l:-1:2)
    (idx - celldiff < 2) && break
    #leftshift it.
    res[idx] = a[idx - celldiff] << shift
    res[idx] |= a[idx - celldiff - 1] >> (64 - shift)
  end
  #then leftshift the last one.
  res[1 + celldiff] = a[1] << shift
  res
end

function rsh(a::SuperInt, b::Integer)
  (typeof(a) == Uint64) && return a >> b
  #how many cells apart is our shift
  celldiff = (b >> 6)
  #and how many slots we need to shift
  shift = b % 64
  #as a courtesy, generate a new array so we don't clobber the old one.
  l = length(a)
  res = zeros(Uint64, l)
  for (idx = 1:l - 1)
    (idx + celldiff + 1> l) && break
    #rightshift it.
    res[idx] = a[idx + celldiff] >> shift
    res[idx] |= a[idx + celldiff + 1] << (64 - shift)
  end
  #complete the last one - it's possible that the last one is not there
  (l - celldiff != 0) && (res[l - celldiff] = a[l] >> shift)
  res
end

function <(a::Array{Uint64,1}, b::Array{Uint64,1})
  for i = length(a):-1:1
    (a[i] > b[i]) && return false
    (a[i] < b[i]) && return true
  end
  return false
end

function >(a::Array{Uint64,1}, b::Array{Uint64,1})
  for i=length(a):-1:1
    (a[i] < b[i]) && return false
    (a[i] > b[i]) && return true
  end
  return false
end
export lsh, rsh
