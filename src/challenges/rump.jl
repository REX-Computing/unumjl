#rump's formula

using Unums
include("../methods/unum_optimizer.jl")

vtypes = [Float16, Float32, Float64, BigFloat]

function type_rump(T, x, y)
  A = T(333.75)
  B = T(11)
  C = T(121)
  D = T(2)
  E = T(5.5)

  A * y^6 + (x^2) * (B * x^2 * y^2 - y^6 - C * y^4 - D) + E * y^8 + x / (D * y)
end

for T in vtypes
  x = convert(T, 77617)
  y = convert(T, 33096)

  z = Float64(type_rump(T, x, y))

  println("rump's formula result in $(T) : $(z)")
end

function u_rump(T)
  x = T(77617)
  y = T(33096)

  type_rump(T, x, y)
end

r = optimize(u_rump, 0.1, 1, 1, verbose = true)
