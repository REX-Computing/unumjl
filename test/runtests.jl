using Unums
using Base.Test

import Unums: z16, o16, z64, o64, t64, f64


include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")

#=
W = Unum{0,0}

x = Unums.make_ulp!(one(W))
y = Unums.make_ulp!(one(W))

println(bits(x))
println(bits(y))

println(Unums.mul_exact(x, y, z16))

x = mmr(W)
y = sss(W)

println(x * y)
println(bits(x * y))
=#
