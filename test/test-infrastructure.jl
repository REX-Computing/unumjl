#test-infrastructure.jl
#tests unums infrastructure (everything except mathematical operations).

################################################################################
## UNIT TESTING

#integer operations and helpers for the type constructor
#include("./unit/unit-int64op.jl")

#functions which directly participate in construction and validation of unums
#include("./unit/unit-helpers.jl")

#type constructor testing
include("./unit/unit-unum.jl")
#include("./unit/unit-ubound.jl")

#testing things that get done to unums
include("./unit/unit-constants.jl")
include("./unit/unit-convert.jl")
include("./unit/unit-comparison.jl")
include("./unit/unit-operations.jl")
