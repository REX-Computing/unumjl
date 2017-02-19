using Unums
using Base.Test

@unumbers
#=
W = Unum{0,0}

@test Unums.sum_exact(W(2), W(1), 1, 0) == mmr(W)

x = Unums.lower_ulp(W(2))
y = sss(W)

describe(x)
describe(y)

describe(x + y)

@test 0 == 1
=#

include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-slice.jl")
include("./test-warlpiri.jl")
