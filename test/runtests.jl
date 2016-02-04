using Unums
using Base.Test

onenum = true

if (onenum)
T = Unum{3,4}
x = convert(T, 3)
y = convert(T, 5)
println(x, "*", y)
z = convert(T, 15)
r = x * y
println("result: ", r)
println("should have been ", z)
else
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
end
