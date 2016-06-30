using Unums
using Base.Test

@unumbers

include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
#=
# 0101 / 0011

x = Unums.make_ulp!(Unum{0,0}(2))
y = Unums.make_ulp!(one(Unum{0,0}))

println(x)
println(y)
println(bits(x))
println(bits(y))

println(x / y)
=#
#=
x = Unum{4,8}(1.0) / Unum{4,8}(3.0)
Unums.make_exact!(x)
println("----")
println(x)
println("----")
@test (x / x) == one(Unum{4,7})
=#
