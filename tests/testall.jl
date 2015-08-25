require("../unum.jl")

using Unums
################################################################################
## UNIT TESTING
using Base.Test

#integer operations and helpers for the type constructor
include("unit-int64op.jl")
include("unit-helpers.jl")

#type constructors
include("unit-unum.jl")

#testing helper functions
include("unit-convert.jl")
#include("unum-test-properties.jl")

#comparison testing
include("unit-comparison.jl")

#mathematics testing
#include("unum-test-addition.jl")
#include("unum-test-multiplication.jl")
#include("unum-test-division.jl")
