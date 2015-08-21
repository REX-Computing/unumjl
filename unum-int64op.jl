#unum-int64op.jl
#various int64 operations that could be helpful across the unum implementation.
#SuperInt is an array

#various helpful numbers
const z64 = zero(Uint64)
const o64 = one(Uint64)
const t64 = 0x8000_0000_0000_0000
const f64 = 0xFFFF_FFFF_FFFF_FFFF
const z16 = zero(Uint16)
const o16 = one(Uint16)
const f16 = uint16(0xFFFF)

#note in version 0.4, this will need to change to Union{}
SuperInt = Union(Uint64, Array{Uint64,1})
GeneralInt = Union(SuperInt, Integer)

#fill x least significant bits with ones.  Negative numbers fill most sig. bits
#assume there is one cell, if no value has been passed.
function fillbits(n::Integer, cells::Integer = 1)
  #kick it to the mask function if there's only one cell.
  if cells == 1
    return mask(n)
  end
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

#lsbmsb: returns the lsb and msb of an integer, process is O(N) in
#the worst case, but O(~0.70N) (Uint16), or O(~0.80N) (Uint64) for randoms
function lsbmsb(x::GeneralInt)
  #finds the lsb and msb of an unsigned int
  bitsize = sizeof(x) << 3
  l = lsb(x, bitsize)
  #if we find that l is maximal, then we know immediately that the number is blank.
  (l == bitsize) ? (l, 0) : (l, msb(x, bitsize))
end

#just the lsb.
function lsb(x::GeneralInt)
  lsb(x, sizeof(x) << 3)
end
function lsb(x::GeneralInt, n::Integer)
  for(i = 0:n - 1)
    if (bitof(x, i) != 0)
      return uint16(i)
    end
  end
  return n
end

#just the msb.
function msb(x::GeneralInt)
  msb(x, sizeof(x) << 3)
end
function msb(x::GeneralInt, n::Integer)
  for (i = n-1:-1:0)
    if (bitof(x, i) != 0)
      return uint16(i)
    end
  end
  return 0
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
