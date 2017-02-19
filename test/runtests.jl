using Unums
using Base.Test

@unumbers

a = Unum{3,5}(0x0000000000000040, 0xFFFFFFFE00000000, 0x0002, 0x0007, 0x001E)
b = zero(Unum{3,5})
Unums.sum_inexact(a, b, -63, -63)



a = Unum{3,5}(0x0000000000000000, 0x0000000000000000, 0x0003, 0x0006, 0x001E)
b = Unum{3,5}(0x0000000000000040, 0xFFFFFFFE00000000, 0x0001, 0x0007, 0x001E)
a + b

@test 1 == 0

include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-slice.jl")
include("./test-warlpiri.jl")
