using Unums
using Base.Test

@unumbers
#=
include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")
=#

x = Unum{3,4}(2)
x.fsize = 2
Unums.make_ulp!(x)
Unums.describe(x)

println("----")

y = Unum{3,4}(2)
y.fsize = 3
Unums.make_ulp!(y)
Unums.describe(y)

println("---")

z = x * y

println("expected top:")
q = Unum{3,4}(4.78125)
println(bits(q.fraction))
Unums.describe(q)


println("====")
Unums.describe(z)
