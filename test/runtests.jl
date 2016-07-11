using Unums
using Base.Test

@unumbers
#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#
#=
x = Unum{2,2}(32)
x += one(Unum{2,2})
x += one(Unum{2,2})
y = Unums.make_ulp!(Unum{2,2}(32))
y.fsize = 0x0002
@test x == y
=#

x = Unum{4,6}(2) / Unum{4,6}(10)
y = Unum{4,6}(1) / Unum{4,6}(10)

println("----")
z = x + y
println("====")

@test Unums.lub(z) > Unum{4,6}(0x0000000000000001, 0x3333333333333333, 0x0000, 0x0002, 0x003F)

x = Unum{4,6}(1) / Unum{4,6}(3)
z = x + x + x

@test Unums.lub(z) > one(Unum{4,6})
