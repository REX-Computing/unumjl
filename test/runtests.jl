using Unums
using Base.Test

@unumbers

include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")


#=
x = Unums.sss(Unum{0,0})
y = Unums.neg_one(Unum{0,0})

z = x + y

println(z)
=#
