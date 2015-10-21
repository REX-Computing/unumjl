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
      global clz = __x86_linux_asm_clz
      o.status = true
    end
  elseif __clz_arch == "arm"
    if OS_NAME == :Linux
      global clz = __arm_linux_asm_clz
      o.status = true
    end
  else
    global clz = __soft_clz
    o.status = false
  end
end

function __hclz_unset(o::__Unum_Option)
  global clz = __soft_clz
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

################################################################################
#register this option.

__hclz_initial_state = __hclz_autodetect()
__uopt_hclz = __Unum_Option(__hclz_set, __hclz_unset, __hclz_initial_state)
__hclz_initial_state ? __hclz_set(__uopt_hclz) : __hclz_unset(__uopt_hclz)
__UNUM_OPTIONS["hardware-clz"] = __uopt_hclz
