using Unums
using Base.Test

import Unums: z16, o16, z64, o64, t64, f64

#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#

x = Unum{3,5}(2.7)

y = Unum{3,5}(0.6)

Unums.frac_div!(x, y)
