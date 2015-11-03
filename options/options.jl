#unums-options.jl

#the unum library comes with a set of options that can be set after calling
#import("unum.jl").  Here is where those options are declared and set to their
#defaults.

type __Unum_Option
  set::Function
  unset::Function
  status::Bool
end

__UNUM_OPTIONS = Dict{String, __Unum_Option}()

#basic ways to manipulate and check the unum options dictionary.
set_option(name::String)   = haskey(__UNUM_OPTIONS, name) && __UNUM_OPTIONS[name].set(__UNUM_OPTIONS[name])
unset_option(name::String) = haskey(__UNUM_OPTIONS, name) && __UNUM_OPTIONS[name].unset(__UNUM_OPTIONS[name])
has_option(name::String) = haskey(__UNUM_OPTIONS, name)
option_state(name::String) = __UNUM_OPTIONS[name].status
options() = collect(keys(__UNUM_OPTIONS))

################################################################################
#default options to include

include("./development-safety.jl")
