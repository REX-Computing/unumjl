#cont-addition.jl
#continuous testing of julia addition directives
include("../../unum.jl")
using Unums

function cont_exactadd_positive()
  #test random, exact addition in the forward direction.
  while true
    x1 = exp(100 * randn());  x2 = x1 + exp(100 * randn());

    u1 = convert(Unum{4,6}, x1); u2 = convert(Unum{4,6}, x2)
    u3 = Unums.__sum_exact(u2, u1, Unums.decode_exp(u2), Unums.decode_exp(u1))
    x3 = convert(Float64, u3)

    if (x3 != (x1 + x2))
      println("$x3 != $(x1 + x2) = $x1 + $x2, diff: $(x3 - x1 - x2)")
      println("x1:  $(bits(u1, " "))")
      println("x2:  $(bits(u2, " "))")
      println("x2:  $(bits(u3, " "))")
    end
  end
end
