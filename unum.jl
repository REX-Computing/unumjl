#unum.jl - a julia implementation of the unum
# this file is the module definition file and also contains
# includes for all of the components which make it work

#for now, only compatible with 64-bit architectures.
@assert(sizeof(Int) == 8, "currently only compatible with 64-bit architectures")

module Unums
#this module exports the Unum Type
export Unum

#bring in some important uint64 bitwise methods
include("unum-int64op.jl")
#helpers used in the unum type constructors andn pseudoconstructors
include("unum-helpers.jl")

#the base unum type and its pseudoconstructors
include("unum-unum.jl")
#and the derived ubound type
include("unum-ubound.jl")

#functions that operate on the unum type itself, and friends.
include("unum-typefunctions.jl")

#include("unum-onezero.jl")
#include("unum-convert.jl")
#include("unum-properties.jl")
#include("unum-oddsandends.jl")
#some math stuff
#include("unum-addition.jl")
#include("unum-multiplication.jl")
#include("unum-division.jl")
#include("unum-comparison.jl")

#h-layer stuff (human)
include("unum-hlayer.jl")

end #module
