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


#fill x least significant bits with ones.  Negative numbers fill most sig. bits
#assume there is one cell, if no value has been passed.
function fillbits(n::Integer, cells::Integer = 1)
  #kick it to the mask function if there's only one cell.
  if cells == 1
    return mask(n)
  end

  if n == ((cells << 6)) || (-n == (cells << 6))
    [f64 for i=1:cells]
  elseif n > 0
    lowlimit = n >> 6
    [[f64 for i=1:lowlimit], mask(n % 64), [z64 for i=lowlimit+2:cells]]
  elseif n < 0
    lowlimit = (-n) >> 6
    [[z64 for i=lowlimit + 2:cells], mask(n%64), [f64 for i=1:lowlimit]]
  else
    zeros(Uint64, cells)
  end
end

#bitof: extracts the bit at (0-indexed) location, using bit masking
function bitof(x::Integer, bit)
  return x & (one(x) << bit)
end

#lsbmsb: returns the lsb and msb of an integer, process is O(N) in
#the worst case, but O(~0.70N) (Uint16), or O(~0.80N) (Uint64) for randoms
function lsbmsb(x::Integer)
  #finds the lsb and msb of an unsigned int
  bitsize = sizeof(x) * 8
  l = lsb(x, bitsize)
  #if we find that l is maximal, then we know immediately that the number is blank.
  (l == bitsize) ? (l, 0) : (l, msb(x, bitsize))
end

#just the lsb.
function lsb(x::Integer)
  lsb(x, sizeof(x) * 8)
end
function lsb(x::Integer, n::Integer)
  for(i = 0:n - 1)
    if (bitof(x, i) != 0)
      return uint16(i)
    end
  end
  return n
end

#just the msb.
function msb(x::Integer)
  msb(x, sizeof(x) * 8)
end
function msb(x::Integer, n::Integer)
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
    (bits == 64) ? uint64(-1) : uint64(2^bits - 1)
  else
    uint64(~mask(64 + bits))
  end
end
#does the same, except with a unit range.
function mask(range::UnitRange)
  uint64(2^(range.stop + 1) - 2^(range.start))
end
