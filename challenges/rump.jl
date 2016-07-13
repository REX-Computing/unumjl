#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#rump's formula

include("../unum.jl")
using Unums
include("../unum_optimizer.jl")

vtypes = [Float16, Float32, Float64, BigFloat]

function type_rump(T, x, y)
  __A = convert(T, 333.75)
  __B = convert(T, 11)
  __C = convert(T, 121)
  __D = convert(T, 2)
  __E = convert(T, 5.5)
  __A * y^6 + (x^2) * (__B * x^2 * y^2 - y^6 - __C * y^4 - __D) + __E * y^8 + x / (__D * y)
end

for T in vtypes
  x = convert(T, 77617)
  y = convert(T, 33096)

  z = float64(type_rump(T, x, y))

  println("rump's formula result in $(T) : $(z)")
end

function u_rump(T)
  x = convert(T, 77617)
  y = convert(T, 33096)

  type_rump(T, x, y)
end

r = optimize(u_rump, 0.1, 1, 1, verbose = true)
