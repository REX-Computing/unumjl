using Unums
using Base.Test

import Unums: z16, o16, z64, o64, t64, f64

#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#


x = Unum{4,8}(1.0) / Unum{4,8}(3.0)
Unums.make_exact!(x)
@test (x / x) == one(Unum{4,7})

#=
x = Unum{4,8}(0x0000000000000001, UInt64[0x5555555555555555,0x5555555555555555,0x5555555555555555,0x5555555555555555], 0x0000, 0x0002, 0x00ff)

println(x / x)

x = one(Unum{4,5}) / Unum{4,5}(3)

println("----")

x = one(Unum{4,7}) / Unum{4,7}(3)
=#
