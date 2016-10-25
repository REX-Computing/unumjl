using Unums
using Base.Test

@unumbers
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")

#=
x = Unum{4,7}(0x0000000000000001, UInt64[0x0000000000000000,0x0000000000000000], 0x0003, 0x0000, 0x007F)

z = Unums.outer_exact(x)

println(z)

x * x
=#
