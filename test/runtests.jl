using Unums
using Base.Test

import Unums: z16, o16, z64, o64, t64, f64

#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#


W = Unum{0,0}

x = sss(W)
y = sss(W)

println(x * y)
