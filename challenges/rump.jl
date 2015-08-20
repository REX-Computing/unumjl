#rump's formula

include("unum.jl")
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
