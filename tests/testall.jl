require("../unum.jl")

using Unums
################################################################################
## UNIT TESTING
using Base.Test

include("unit-int64op.jl")
include("unit-helpers.jl")

#testing helper functions
#include("unit-convert.jl")
#include("unum-test-properties.jl")

#mathematics testing
#include("unum-test-addition.jl")
#include("unum-test-multiplication.jl")
#include("unum-test-division.jl")
