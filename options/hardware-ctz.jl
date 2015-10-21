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
      global ctz(n::Uint64) = __x86_linux_asm_ctz(n)
      o.status = true
    end
  elseif __clz_arch == "arm"
    if OS_NAME == :Linux
      global ctz(n::Uint64) = __arm_linux_asm_ctz(n)
      o.status = true
    end
  else
    global ctz(n::Uint64) = __soft_ctz(n)
    o.status = false
  end
end

function __hclz_unset(o::__Unum_Option)
  global ctz(n::Uint64) = __soft_ctz(n)
  o.status = false
end

################################################################################
# compiled C library calls out to different assembler languages/architectures

function __x86_linux_asm_ctz(n::Uint64)
  ccall((:clz, "./clz/bin/liblinuxx86ctz"), Int64, (Int64,), n)
end

function __arm_linux_asm_ctz(n::Uint64)
  ccall((:clz, "./clz/bin/liblinuxarmctz"), Int64, (Int64,), n)
end

################################################################################
#register this option.

__hctz_initial_state = __hctz_autodetect()
__uopt_hctz = __Unum_Option(__hctz_set, __hctz_unset, __hctz_initial_state)
__hctz_initial_state ? __hctz_set(__uopt_hctz) : __hctz_unset(__uopt_hctz)
__UNUM_OPTIONS["hardware-ctz"] = __uopt_hctz
