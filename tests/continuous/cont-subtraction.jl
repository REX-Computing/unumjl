#!/usr/bin/julia

#cont-addition.jl
#continuous testing of julia addition directives
include("../../unum.jl")
using Unums

while true
  x1 = exp(100 * randn());  x2 = x1 + exp(100 * randn());

  u1 = convert(Unum{4,6}, x1); u2 = convert(Unum{4,6}, x2)
  u3 = Unums.__diff_exact(u2, -u1, Unums.decode_exp(u2), Unums.decode_exp(u1))
  x3 = convert(Float64, u3)

  if (abs(x3 - (x2 - x1)) > (abs(x3) * 0.000000001))
    println("$x3 != $(x1 + x2) = $x1 + $x2, diff: $(x3 - x1 - x2)")
    println("x1:  $(bits(u1, " "))")
    println("x2:  $(bits(u2, " "))")
    println("x3:  $(bits(u3, " "))")
  end
end
