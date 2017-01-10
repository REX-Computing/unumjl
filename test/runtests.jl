using Unums
using Base.Test

@unumbers

x = Ubound(Unum{3,5}(0x0000000000000030, 0xDD99D88C00000000, 0x0003, 0x0005, 0x001E), Unum{3,5}(0x0000000000000030, 0xDD99D87800000000, 0x0003, 0x0005, 0x001D))
y = Ubound(Unum{3,5}(0x0000000000000018, 0x1BADF0DB00000000, 0x0001, 0x0004, 0x001F), Unum{3,5}(0x0000000000000018, 0x1BADF0DC00000000, 0x0001, 0x0004, 0x001D))

@test x / y == zero(Unum{3,5})


include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-slice.jl")
include("./test-warlpiri.jl")
