#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#polynomial.jl
#solves an arbitrary 6-degree polynomial, using the arbitrary function solver

include("../unum.jl")
using Unums

const plength = 4
#const parray = [exp(100 * randn()) * (randbool() ? -1 : 1) for idx=1:plength]
const parray = [6, 5, -7, 1]
const tol = 0.0001

function pwr(x::Utype, n::Integer)
  if n == 1
    x
  elseif iseven(n)
    sqr(pwr(x, n ÷ 2))
  else
    x * pwr(x, n - 1)
  end
end

function polynomial(v::Utype)
  T = isa(v, Ubound) ? typeof(v.lowbound) : typeof(v)
  sum = convert(T, parray[1])
  for (idx = 2:plength)
    sum += convert(T, parray[idx]) * pwr(v, idx - 1)
  end
  sum
end

a = solve(polynomial, tol, 0, 0)#, verbose = true)
map((x) -> println("result:", describe(x)), a)

println()
println()

print("solved polynomial: ")
for idx=plength:-1:2
  print(parray[idx], "x^", (idx - 1), " + ")
end
println(parray[1], " to relative tolerance ", tol)

println("solutions: ")
map((d) -> println(describe(d)), a)
