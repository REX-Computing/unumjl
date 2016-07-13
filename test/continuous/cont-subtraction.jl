#!/usr/bin/julia

#cont-subtraction.jl
#continuous testing of julia subtraction directives
include("../../unum.jl")
using Unums

error = 0
total = 0

while true
  x1 = exp(100 * randn());  x2 = x1 + exp(100 * randn());

  u1 = convert(Unum{4,6}, x1); u2 = convert(Unum{4,6}, x2)
  u3 = Unums.__diff_exact(u2, -u1, Unums.decode_exp(u2), Unums.decode_exp(u1))
  x3 = convert(Float64, u3)

  if (abs(x3 - (x2 - x1)) > (abs(x3) * 0.000000001))
    println("$x3 != $(x2 - x1) = $x2 - $x1, diff: $(x3 - (x2 - x1))")
    println("u1:", u1)
    println("u2:", u2)
    println("u3:", u3)
    println("u1:  $(bits(u1, " "))")
    println("u2:  $(bits(u2, " "))")
    println("u3:  $(bits(u3, " "))")
    error += 1
  end
  total += 1
  #println("error rate: $(error/total)")
end
