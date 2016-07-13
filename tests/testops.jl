#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


require("../unum.jl")

using Unums
################################################################################
## UNIT TESTING JUST ARITHMETIC operations
using Base.Test

include("unit-addition.jl")
include("unit-subtraction.jl")
include("unit-multiplication.jl")
include("unit-division.jl")
