include("unum.jl")
using Unums

sum = one(Unum{1,1})
println(Unums.calculate(sum))
println(describe(sum))
sum = sum + one(Unum{1,1})

println(bits(sum, " "))
println(bits(almostpinf(Unum{1,1}), " "))
println(isalmostinf(sum))
println(Unums.calculate(sum))
