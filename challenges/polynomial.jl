#polynomial.jl
#solves an arbitrary 6-degree polynomial, using the arbitrary function solver

include("../unum.jl")
using Unums

const plength = 2
#const parray = [exp(100 * randn()) * (randbool() ? -1 : 1) for idx=1:plength]
const parray = [-4.75, 1]

function pwr(x::Utype, n::Integer)
  if n == 1
    x
  else
    x * pwr(x, n - 1)
  end
end

function polynomial(v::Utype)
  T = isa(v, Ubound) ? typeof(v.lowbound) : typeof(v)
  sum = convert(T, parray[1])
  for (idx = 2:plength)
    sum += convert(T, parray[idx]) * pwr(v , idx - 1)
  end
  sum
end

a = solve(polynomial, 0.1, 0, 0, verbose = true)
map((x) -> println("result:", bits(x, " ")), a)
