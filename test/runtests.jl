using Unums
using Base.Test

@unumbers
#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#

x = Unum{4,7}(0x00000000000000F9, UInt64[0x7d31ee79ca44b643,0x91bb985960000000], 0x0000, 0x0007, 0x0063)
y = Unum{4,7}(0x00000000000000F9, UInt64[0x7d31ee79ca44b643,0x91bb985960000080], 0x0000, 0x0007, 0x0079)

z = y - x

println(bits(y, " "))
println(bits(x, " "))
println(bits(z, " "))

@test z == Unum{4,7}(2)
