#unums-options.jl

#the unum library comes with a set of options that can be set after calling
#import("unum.jl").  Here is where those options are declared and set to their
#defaults.

__UNUM_OPTIONS = Dict{String, __Unum_Option}

type __Unum_Option
  set::Function
  unset::Function
  status::Boolean
end

function set_unum_option(name::String)
  if haskey(__UNUM_OPTIONS, name)
    __UNUM_OPTIONS[name].set(__UNUM_OPTIONS[name])
  end
end

function unset_unum_option(name::String)
  if haskey(__UNUM_OPTIONS, name)
    __UNUM_OPTIONS[name].unset(__UNUM_OPTIONS[name])
  end
end

has_unum_option(name::String) = haskey(__UNUM_OPTIONS, name)
unum_option_state(name::String) = __UNUM_OPTIONS[name].status

################################################################################
#default options to include

include("./options/development-safety.jl")
include("./options/hardware-clz.jl")
