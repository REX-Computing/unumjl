using Unums
using Base.Test

onenum = true

if (onenum)
x = mmr(Unum{0,0})
y = sss(Unum{0,0})
println(bits(x), "*", bits(y))
r = x * y
println("result: ", bits(r))
println("should have been 0001 -> 0101")
else
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
end
