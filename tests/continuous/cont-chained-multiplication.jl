#!/usr/bin/julia

#cont-addition.jl
#continuous testing of julia addition directives
include("../../unum.jl")
using Unums

function erand()
  u = convert(Unum{4,7}, exp(100 * randn()) * (rand() < 0.5 ? -1 : 1))
  #flip the ubit randomly
  unum_unsafe(u, u.flags | (rand() < 0.5 ? Unums.UNUM_UBIT_MASK : zero(Uint16)))
end

function to_big(u)
  typeof(u) <: Ubound && return calculate(u.lowbound)
  calculate(u)
end

sumsums = 0
sumcrash = 0
sumerror = 0

while true

  u1 = erand()
  f3 = to_big(u1)

  for idx = 1:100

    f1 = f3
    u2 = erand()
    f2 = to_big(u2)
    u3 = u1

    try
      u3 = u1 * u2

      f3 = to_big(u3)

      if (isfinite(f3) && isfinite(f1 * f2) && (f3 != big(0)) && (f1 * f2 != big(0)))
        if (abs(f3 - (f1 * f2)) > (abs(f3) * 0.000000001))
          println("$f3 != $(f1 * f2) = $f1 * $f2, diff: $(f3 - f1 * f2)")
          println("x1:  $(u1)")
          println("x2:  $(u2)")
          println("x2:  $(u3)")
          println("----")
          sumerror += 1
          println("$(100 - 100*(sumerror + sumcrash)/sumsums)% correct, $(100 * sumerror/sumsums)% error, $(100 * sumcrash/sumsums)% fatal")
        end
      end
    catch
      println("failure in multiplication")
      println(u1)
      println(u2)
      bt = catch_backtrace()
      s = sprint(io->Base.show_backtrace(io, bt))
      println("$s")
      println("----")
      sumcrash += 1
      println("$(100 - 100*(sumerror + sumcrash)/sumsums)% correct, $(100 * sumerror/sumsums)% error, $(100 * sumcrash/sumsums)% fatal")
    end

    sumsums += 1

    u1 = u3
  end
  #println("$(100 - 100*(sumerror + sumcrash)/sumsums)% correct, $(100 * sumerror/sumsums)% error, $(100 * sumcrash/sumsums)% fatal")
end
