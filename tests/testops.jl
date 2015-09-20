require("../unum.jl")

using Unums
################################################################################
## UNIT TESTING JUST ARITHMETIC operations
using Base.Test

include("unit-addition.jl")
include("unit-subtraction.jl")
include("unit-multiplication.jl")
include("unit-division.jl")
