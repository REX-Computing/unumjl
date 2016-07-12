using Unums
using Base.Test

@unumbers

include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")



#=
UT = Unum{3,5}

x = Ubound(UT(1), UT(2))
y = Ubound(Unums.outer_ulp!(UT(1)), mmr(UT))
z = (x / y)

println(x)
describe(x)
println(y)
describe(y)
println(z)
describe(z)
=#
#=
@test x / y == Ubound(sss(UT), Unums.inner_ulp!(UT(2)))   #[1,2] / (1, inf) == (0, 2)
=#
