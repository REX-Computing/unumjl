#unum.jl - a julia implementation of the unum
# this file is the module definition file and also contains
# includes for all of the components which make it work

#for now, only compatible with 64-bit architectures.
@assert(sizeof(Int) == 8, "currently only compatible with 64-bit architectures")

module Unums

#create the abstract Utype type
abstract Utype <: Real
export Utype

#set up the options engine for the unums system
include("unums-options.jl")

#=

#bring in some important uint64 bitwise methods
include("unum-int64op.jl")
#helpers used in the unum type constructors andn pseudoconstructors
include("unum-helpers.jl")

#the base unum type and its pseudoconstructors
include("unum-unum.jl")
#and the derived ubound type
include("ubound-ubound.jl")

#functions that operate on the unum type itself, and friends.
include("unum-typeproperties.jl")

include("unum-constants.jl")
include("unum-properties.jl")
include("unum-comparison.jl")
include("unum-convert.jl")
include("unum-operations.jl")
#some math stuff
include("unum-addition.jl")
include("unum-subtraction.jl")
include("unum-multiplication.jl")
include("unum-division.jl")

#unary operators
include("unum-sqrs.jl")

#h-layer stuff (human)
include("unum-hlayer.jl")

#other utilities
include("unum-bitwalk.jl")
include("unum-promote.jl")
include("unum-expwalk.jl")
include("unum_solver.jl")
=#
end #module
