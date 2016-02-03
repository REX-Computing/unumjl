using Unums
using Base.Test

onenum = false

if (onenum)
x = one(Unum{0,0})
y = neg_sss(Unum{0,0})
println(bits(x), "*", bits(y))
r = x * y
println("result: ", bits(r))
println("should have been  1001")
else
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
end
