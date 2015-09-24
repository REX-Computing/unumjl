#rump's formula

include("../unum.jl")
include("../unum_optimizer.jl")
using Unums

vtypes = [Float16, Float32, Float64, BigFloat]

function rump(x, y)
  333.75 * y^6 + (x^2) * (11 * x^2 * y^2 - y^6 - 121 * y^4 - 2) + 5.5 * y^8 + x / (2 * y)
end

for T in vtypes
  x = convert(T, 77617)
  y = convert(T, 33096)

  z = float64(rump(x, y))

  println("rump's formula result in $(T) : $(z)")
end

function type_rump(T, x, y)
  convert(T, 333.75) * y^6 + (x^2) * (convert(T, 11) * x^2 * y^2 - y^6 - convert(T,121) * y^4 - convert(T,2)) + convert(T, 5.5) * y^8 + x / (convert(T,2) * y)
end

function u_rump(T)
  x = convert(T, 77617)
  y = convert(T, 33096)

  type_rump(T, x, y)
end

r = optimize(u_rump, 0.1, 1, 1, verbose = true)
