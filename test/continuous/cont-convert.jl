#!/usr/bin/julia

#cont-convert.jl
#continuous conversion tests on conversions

include("../../unum.jl")
using Unums

#performs a conversion wherin we try every possible bit permutation of the unum
#and then run the following steps:
# 1) random float
# 2) convert to unum
# 3) direct calculate float from unum
# 4) check to make sure 1 & 3 are the same
# 4) convert back to float from unum
# 5) check to make sure 4 & 1 are the same

#test random, exact addition in the forward direction.
while true
  x1 = exp(100 * randn()) * (rand() > 0.5 ? -1 : 1)
  x2 = 0.0
  try
    u1 = convert(Unum{4,6}, x1)
    x2 = convert(Float64, u1)
  catch
    println("error converting $(bits(x1))")
  end

  if (x1 != x2)
    println("$x1 => $x2 converts funny, diff: $(x1 - x2)")
  end
end
