#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
#unum-int64op.jl
#various Int64 operations that could be helpful across the unum implementation.
#SuperInt is an array

#various helpful numbers
const z64 = zero(UInt64)
const o64 = one(UInt64)
const t64 = 0x8000_0000_0000_0000
const f64 = 0xFFFF_FFFF_FFFF_FFFF
const z16 = zero(UInt16)
const o16 = one(UInt16)
const f16 = UInt16(0xFFFF)

SuperInt = Union{UInt64, Array{UInt64,1}}
#general 16-bit integers
GI16 = Union{UInt16, Int16}

#generates a superint zero for a given superint length
superzero(l::Integer) = ((l == 1) ? z64 : zeros(UInt64, l))
superone(l::Integer) = ((l == 1) ? o64 : [o64; zeros(UInt64, l - 1)])
supertop(l::Integer) = ((l == 1) ? t64 : [zeros(UInt64, l - 1); t64])

function __copy_superint(a::SuperInt)
  length(a) == 1 && return a
  copy(a)
end

function superbits(a::SuperInt)
  if length(a) == 1
    bits(a)
  else
    reduce((a, b) -> string(b,a), map(bits, a))
  end
end

# a helper function for is_exp_zero, and is_frac_zero.  Optimized to be fast.
function allzeros(a::SuperInt)
  (length(a) == 1) && return a == 0
  for idx = length(a):-1:1
    a[idx] != 0 && return false
  end
  true
end

function justtop(a::SuperInt)
  (length(a) == 1) && return a == t64
  (last(a) != t64) && return false
  for idx = (length(a)-1):-1:1
    a[idx] != 0 && return false
  end
  true
end


#generates a mask of a certain number of bits on the right, or left if negative
function mask(bits::Integer)
  if bits >= 0
    (bits == 64) ? - one(UInt64) : UInt64((1 << bits) - 1)
  else
    UInt64(~mask(64 + bits))
  end
end
#does the same, except with a unit range.
function mask(range::UnitRange)
  UInt64((1 << (range.stop + 1)) - (1 << (range.start)))
end

#fill x least significant bits with ones.  Negative numbers fill most sig. bits
#assume there is one cell, if no value has been passed.
function fillbits(n::Integer, cells::UInt16 = 1)
  #kick it to the mask function if there's only one cell.
  if cells == 1
    return mask(n)
  end
  lowlimit::UInt16 = 0
  #generate the cells.
  if n == ((cells << 6)) || (-n == (cells << 6))
    #check to see if we're asking to fill the entire set of cells
    [f64 for i=1:cells]
  elseif n > 0
    #cells filled from the right to the left
    lowlimit = n >> 6
    [[f64 for i=1:lowlimit]; mask(n % 64); [z64 for i=lowlimit+2:cells]]
  elseif n < 0
    #cells filled from the left to the right
    lowlimit = (-n) >> 6
    [[z64 for i=lowlimit + 2:cells]; mask(n%64); [f64 for i=1:lowlimit]]
  else
    #empty cells
    zeros(UInt64, cells)
  end
end

#bitof: extracts the bit at (0-indexed) location, using bit masking
function bitof(x::Integer, bit)
  return x & (one(x) << bit)
end
function bitof(x::Array{UInt64,1}, bit)
  cell = (bit >> 6) + 1
  offset = bit % 64
  bitof(x[cell], offset)
end
#the reverse experiment is __bit_from_top.  Generates a single UInt64 array that
#has a single bit flipped, which is the n'th bit from the msb, 1-indexed.
function __bit_from_top(n::Integer, l::Integer)
  (l == 1) && return (t64 >> (n - 1))
  res = zeros(UInt64, l)
  #calculate the cell number
  cellidx = l - ((n - 1) >> 6)
  #figure out what we should replace the cell with.
  cell = UInt64(t64 >> ((n - 1) % 64))
  #do the replacement
  res[cellidx] = cell
  #return the result
  res
end

#rebuild "least significant bit" and "most significant bit" as clz/ctz to make
#conversion to assembler more straightforward.  These are very accelerated
#binary search modules, but even these should be changed in future revs.

#a 16-element lookup array to speed up clz in the last few sections.
              #0000   0001   0010   0011 0100 0101 0110 0111 1000 ...
__clz_array=[0x0004,0x0003,0x0002,0x0002, o16, o16, o16, o16, z16,z16,z16,z16,z16,z16,z16,z16]
function clz(n::UInt64)
  (n == 0) && return 64
  res::UInt16 = 0
  #use the binary search method
  (n & 0xFFFF_FFFF_0000_0000 == 0) && (n <<= 32; res += 0x0020)
  (n & 0xFFFF_0000_0000_0000 == 0) && (n <<= 16; res += 0x0010)
  (n & 0xFF00_0000_0000_0000 == 0) && (n <<= 8;  res += 0x0008)
  (n & 0xF000_0000_0000_0000 == 0) && (n <<= 4;  res += 0x0004)
  res + __clz_array[(n >> 60) + 1]
end

function clz(n::GI16)
  res::UInt16 = 0
  (n & 0xFF00 == 0) && (n <<= 8;  res += 0x0008)
  (n & 0xF000 == 0) && (n <<= 4;  res += 0x0004)
  res += __clz_array[(n >> 12) + 1]
end
#for when it's a superint (that's not a straight UInt64)

function clz(n::Array{UInt64, 1})
  #iterate down the array starting from the most significant cell
  res::UInt16 = 0
  for idx = length(n):-1:1
    #kick it to the previous clz function
    (n[idx] != 0) && return res + clz(n[idx])
    res += 0x0040
  end
  res
end

#a 16-element lookup array to speed up ctz in the last few sections.
              #0000  0001 0010 0011   0100 0101 0110 0111    1000  1001 1010 1011   1100  1101 1110 1111
__ctz_array=[0x0004, z16, o16, z16, 0x0002, z16, o16, z16, 0x0003, z16, o16, z16, 0x0002, z16, o16, z16]
function ctz(n::UInt64)
  (n == 0) && return 64
  res::UInt16 = 0
  (n & 0x0000_0000_FFFF_FFFF == 0) && (n >>= 32; res += 0x0020)
  (n & 0x0000_0000_0000_FFFF == 0) && (n >>= 16; res += 0x0010)
  (n & 0x0000_0000_0000_00FF == 0) && (n >>= 8;  res += 0x0008)
  (n & 0x0000_0000_0000_000F == 0) && (n >>= 4;  res += 0x0004)
  #unlike clz, ctz doesn't consume bits as it gets pushed around.  Let's mask
  #out all digits we didn't shift over.
  n &= 0x0000_0000_0000_000F
  res + __ctz_array[n + 1]
end

function ctz(n::GI16)
  res::UInt16 = 0
  (n & 0x00FF == 0) && (n >>= 8;  res += 0x0008)
  (n & 0x000F == 0) && (n >>= 4;  res += 0x0004)
  n &= 0x000F
  res + __ctz_array[n + 1]
end

#for when it's a superint (that's not a straight UInt64)
function ctz(n::Array{UInt64, 1})
  #iterate down the array starting from the most significant cell
  res::UInt16 = 0
  for idx = 1:length(n)
    #kick it to the previous clz function
    (n[idx] != 0) && return res + ctz(n[idx])
    res += 0x0040
  end
  res
end
export clz, ctz

#calculates the fsize of f when it's an exact value.
function __fsize_of_exact(f::SuperInt)
  #multiply the length of f by 64 and then subtract ctz
  #if we're a zero, just return that, otherwise return the result minus 1.
  #use the max() method as suggested by profiling.
  UInt16(max(0, length(f) << 6 - ctz(f) - 1))
end

#iterative leftshift and rightshift operations on Array SuperInts
function lsh(a::SuperInt,b::Integer)
  (typeof(a) == UInt64) && return a << b
  #calculate how many cells apart our two ints shall be.
  celldiff = b >> 6
  #calculate how much we have to shift
  shift = b % 64
  #as a courtesy, generate a new array so we don't clobber the old one.
  l = length(a)
  res = zeros(UInt64, l)
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
  (typeof(a) == UInt64) && return a >> b
  #how many cells apart is our shift
  celldiff = (b >> 6)
  #and how many slots we need to shift
  shift = b % 64
  #as a courtesy, generate a new array so we don't clobber the old one.
  l = length(a)
  res = zeros(UInt64, l)
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

function <(a::Array{UInt64,1}, b::Array{UInt64,1})
  for i = length(a):-1:1
    (a[i] > b[i]) && return false
    (a[i] < b[i]) && return true
  end
  return false
end

function >(a::Array{UInt64,1}, b::Array{UInt64,1})
  for i=length(a):-1:1
    (a[i] < b[i]) && return false
    (a[i] > b[i]) && return true
  end
  return false
end
export lsh, rsh
