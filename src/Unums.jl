#unum.jl - a julia implementation of the unum
# this file is the module definition file and also contains
# includes for all of the components which make it work

#for now, only compatible with 64-bit architectures.
@assert(sizeof(Int) == 8, "currently only compatible with 64-bit architectures")

module Unums

#engage the unpms options engine.
include("./options/options.jl")
#various tools to help coding.
include("./tools.jl")

################################################################################
#TYPE DEFINITION FILES
#type definitions for int64 array.
include("./int64op/i64o-typedefs.jl")
#type definition of unum.
include("./unum/unum-typedefs.jl")
#type definition of ubound
include("./ubound/ubound-typedefs.jl")
#type definition of gnum.
include("./gnum/gnum-typedefs.jl")

#create the abstract Utype which encompasses all possibilities of Unum/Ubound/Gnum
typealias Utype{ESS,FSS} Union{Unum{ESS,FSS}, Ubound{ESS,FSS}, Gnum{ESS,FSS}}
export Utype

################################################################################
#IMPLEMENTATION FILES
#implementation of int64 and int64 array utility code.
include("./int64op/int64ops.jl")
#implementation of unums.
include("./unum/unum.jl")
#ubound-related code
include("./ubound/ubound.jl")
#gnums-related code
#include("./gnum/gnum.jl")

#utility files
include("./ubox/ubox.jl")
#include("unum-bitwalk.jl")
#include("unum-promote.jl")
#include("unum-expwalk.jl")
#include("unum_solver.jl")

end #module
