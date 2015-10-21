#clzctz.jl
#clz and ctz operations, stored as global function variables.

################################################################################
#CLZ

__clz_array=[0x0004,0x0003,0x0002,0x0002,
             0x0001,0x0001,0x0001,0x0001,
             0x0000,0x0000,0x0000,0x0000,
             0x0000,0x0000,0x0000,0x0000]

function __soft_clz(n::Uint64)
  (n == 0) && return 64
  res::Uint16 = 0
  #use the binary search method
  (n & 0xFFFF_FFFF_0000_0000 == 0) && (n <<= 32; res += 0x0020)
  (n & 0xFFFF_0000_0000_0000 == 0) && (n <<= 16; res += 0x0010)
  (n & 0xFF00_0000_0000_0000 == 0) && (n <<= 8;  res += 0x0008)
  (n & 0xF000_0000_0000_0000 == 0) && (n <<= 4;  res += 0x0004)
  @inbounds res + __clz_array[(n >> 60) + 1]
end

function clz(n::Array{Uint64, 1})
  #iterate down the array starting from the most significant cell
  res::Uint16 = 0
  for idx = length(n):-1:1
    #kick it to the previous clz function
    (n[idx] != 0) && return res + clz(n[idx])
    res += 0x0040
  end
  res
end

################################################################################
#CTZ

__ctz_array=[0x0004, 0x0000, 0x0001, 0x0000,
             0x0002, 0x0000, 0x0001, 0x0000,
             0x0003, 0x0000, 0x0001, 0x0000,
             0x0002, 0x0000, 0x0001, 0x0000]

function __soft_ctz(n::Uint64)
  (n == 0) && return 64
  res::Uint16 = 0
  #use the binary search method
  (n & 0x0000_0000_FFFF_FFFF == 0) && (n >>= 32; res += 0x0020)
  (n & 0x0000_0000_0000_FFFF == 0) && (n >>= 16; res += 0x0010)
  (n & 0x0000_0000_0000_00FF == 0) && (n >>= 8;  res += 0x0008)
  (n & 0x0000_0000_0000_000F == 0) && (n >>= 4;  res += 0x0004)
  #unlike clz, ctz doesn't consume bits as it gets pushed around.  Let's mask
  #out all digits we didn't shift over.
  n &= 0x0000_0000_0000_000F
  @inbounds res + __ctz_array[n + 1]
end

#for when it's a superint (that's not a straight Uint64)
function ctz(n::Array{Uint64, 1})
  #iterate down the array starting from the most significant cell
  res::Uint16 = 0
  for idx = 1:length(n)
    #kick it to the previous clz function
    (n[idx] != 0) && return res + ctz(n[idx])
    res += 0x0040
  end
  res
end

################################################################################
# set default clz and ctz variables to the software versions by default.
clz(n::Uint64) = __soft_clz(n)
ctz(n::Uint64) = __soft_ctz(n)

export clz, ctz
