#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135




__clz_array=[0x0004,0x0003,0x0002,0x0002,
             0x0001,0x0001,0x0001,0x0001,
             0x0000,0x0000,0x0000,0x0000,
             0x0000,0x0000,0x0000,0x0000]

function clz_nobound(n::UInt64)
  (n == 0) && return 64
  res::UInt16 = 0
  #use the binary search method
  (n & 0xFFFF_FFFF_0000_0000 == 0) && (n <<= 32; res += 0x0020)
  (n & 0xFFFF_0000_0000_0000 == 0) && (n <<= 16; res += 0x0010)
  (n & 0xFF00_0000_0000_0000 == 0) && (n <<= 8;  res += 0x0008)
  (n & 0xF000_0000_0000_0000 == 0) && (n <<= 4;  res += 0x0004)
  res + __clz_array[(n >> 60) + 1]
end

function clz_inbound(n::UInt64)
  (n == 0) && return 64
  res::UInt16 = 0
  #use the binary search method
  (n & 0xFFFF_FFFF_0000_0000 == 0) && (n <<= 32; res += 0x0020)
  (n & 0xFFFF_0000_0000_0000 == 0) && (n <<= 16; res += 0x0010)
  (n & 0xFF00_0000_0000_0000 == 0) && (n <<= 8;  res += 0x0008)
  (n & 0xF000_0000_0000_0000 == 0) && (n <<= 4;  res += 0x0004)
  @inbounds res += __clz_array[(n >> 60) + 1]
  res
end

count = 10000

alist = [rand(UInt64) for idx = 1:count]

function testwith(f, a)
  for idx=1:count
    f(a[idx])
  end
end

@time testwith(clz_nobound, alist)
@time testwith(clz_inbound, alist)
@time testwith(clz_nobound, alist)
@time testwith(clz_inbound, alist)
