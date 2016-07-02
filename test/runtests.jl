using Unums
using Base.Test

@unumbers
#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#

@test Unum{4,6}(6) < Unum{4,6}(7)
