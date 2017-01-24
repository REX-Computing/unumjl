using Unums
using Base.Test

@unumbers

x = Unum{3,6}(0x000000000000000E, 0xE800000000000000, 0x0002, 0x0003, 0x0004)
y = Unum{3,6}(0x0000000000000003, 0x3FFFFFC000000000, 0x0003, 0x0001, 0x0019)

z = x * y

describe(x)
describe(y)
describe(z)

println(y)
println(z)

@test 0 == 1

include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-slice.jl")
include("./test-warlpiri.jl")
