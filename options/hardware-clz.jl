#options/hardware-clz.jl

#enables a hardware-clz on certain systems, resulting in a substantial
#acceleration. will eventually feature an "autodetect" system which
#automatically detects platform and automatically sets the system

function __hclz_autodetect()
  #currently, hardware clz must be set manually.
  global __clz_arch = ""
  return false
end

function __hclz_set(o::__Unum_Option)
  #select the correct.
  if __clz_arch == "x86"
    if OS_NAME == :Linux
      global __fast_clz = __x86_linux_asm_clz
      o.status = true
    end
  elseif __clz_arch == "arm"
    if OS_NAME == :Linux
      global __fast_clz = __arm_linux_asm_clz
      o.status = true
    end
  else
    global __fast_clz = __soft_clz
    o.status = false
  end
end

function __hclz_unset(o::__Unum_Option)
  global __fast_clz = __soft_clz
  o.status = false
end

################################################################################
# compiled C library calls out to different assembler languages/architectures

function __x86_linux_asm_clz(x::Uint64)
  ccall((:clz, "./clz/bin/liblinuxx86clz"), Int64, (Int64,), x)
end

function __arm_linux_asm_clz(x::Uint64)
  ccall((:clz, "./clz/bin/liblinuxarmclz"), Int64, (Int64,), x)
end

__clz_array=[0x0004,0x0003,0x0002,0x0002,
             0x0001,0x0001,0x0001,0x0001,
             0x0000,0x0000,0x0000,0x0000,
             0x0000,0x0000,0x0000,0x0000]

function __soft_clz(x::Uint64)
  (n == 0) && return 64
  res::Uint16 = 0
  #use the binary search method
  (n & 0xFFFF_FFFF_0000_0000 == 0) && (n <<= 32; res += 0x0020)
  (n & 0xFFFF_0000_0000_0000 == 0) && (n <<= 16; res += 0x0010)
  (n & 0xFF00_0000_0000_0000 == 0) && (n <<= 8;  res += 0x0008)
  (n & 0xF000_0000_0000_0000 == 0) && (n <<= 4;  res += 0x0004)
  @inbounds res + __clz_array[(n >> 60) + 1]
end

################################################################################
#register this option.

__hclz_initial_state = __hclz_autodetect()
__uopt_hclz = __Unum_Option(__hclz_set, __hclz_unset, __hclz_initial_state)
__hclz_initial_state ? __hclz_set(__uopt_hclz) : __hclz_unset(__uopt_hclz)
__UNUM_OPTIONS["hardware-clz"] = __uopt_hclz
