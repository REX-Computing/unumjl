require("../unum.jl")

using Unums
################################################################################
## UNIT TESTING JUST ARITHMETIC operations
using Base.Test

@test (1==0; "currently arithmetic isn't implemented")

#=
include("unit-addition.jl")
include("unit-subtraction.jl")
include("unit-multiplication.jl")
include("unit-division.jl")
=#
