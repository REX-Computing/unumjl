using Unums
using Base.Test

# write your own tests here
#include("./test-infrastructure.jl")
#include("./test-operations.jl")
#include("./test-warlpiri.jl")

g = zero(Unums.Gnum{3,4})
uno = one(Unum{3,4})
two = convert(Unum{3,4}, 2)
add!(uno, two, g)
