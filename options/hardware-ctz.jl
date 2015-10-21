#options/hardware-ctz.jl

#enables a hardware ctz on certain systems, resulting in a substantial
#acceleration. will eventually feature an "autodetect" system which
#automatically detects platform and automatically sets the system

function __hctz_autodetect()
  #currently, hardware clz must be set manually.
  global __ctz_arch = ""
  return false
end

function __hctz_set(o::__Unum_Option)
  #select the correct.
  if __clz_arch == "x86"
    if OS_NAME == :Linux
      global __fast_ctz = __x86_linux_asm_ctz
      o.status = true
    end
  elseif __clz_arch == "arm"
    if OS_NAME == :Linux
      global __fast_ctz = __arm_linux_asm_ctz
      o.status = true
    end
  else
    global __fast_ctz = __soft_ctz
    o.status = false
  end
end

function __hclz_unset(o::__Unum_Option)
  global __fast_ctz = __soft_ctz
  o.status = false
end

################################################################################
# compiled C library calls out to different assembler languages/architectures

function __x86_linux_asm_ctz(x::Uint64)
  ccall((:clz, "./clz/bin/liblinuxx86ctz"), Int64, (Int64,), x)
end

function __arm_linux_asm_ctz(x::Uint64)
  ccall((:clz, "./clz/bin/liblinuxarmctz"), Int64, (Int64,), x)
end

__ctz_array=[0x0004, 0x0000, 0x0001, 0x0000,
             0x0002, 0x0000, 0x0001, 0x0000,
             0x0003, 0x0000, 0x0001, 0x0000,
             0x0002, 0x0000, 0x0001, 0x0000]

function __soft_ctz(x::Uint64)
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

################################################################################
#register this option.

__hctz_initial_state = __hctz_autodetect()
__uopt_hctz = __Unum_Option(__hctz_set, __hctz_unset, __hctz_initial_state)
__hctz_initial_state ? __hctz_set(__uopt_hctz) : __hctz_unset(__uopt_hctz)
__UNUM_OPTIONS["hardware-ctz"] = __uopt_hctz
