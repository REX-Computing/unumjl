using Unums
using Base.Test

import Unums: z16, o16, z64, o64, t64, f64

#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#

x = Unums.make_exact!(Unum{4,6}(1) / Unum{4,6}(3))
println(x / x)


#=
x = Unum{4,5}(0x0000000000000003, 0x5555555600000000, 0x0000, 0x0001, 0x001F)
y = Unum{4,5}(3)

println(calculate(x * y))
=#
