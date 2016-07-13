#unum-continuous.jl
#functions that make continuous testing possible

include("../../unum.jl")
using unum

function continuous_test_on_float(f)
  #runs a continuous test on the function f, which takes a random floating point
  #and outputs a true/false depending on the value.
  while (true)
    #random, normal generation of a floating point.
    value = randn()
    try
      res = f(value)
      if (res == false)
        println("function $f fails for float $res ($(bits(value)))")
        bits(value)
      end
    catch
      println("$value failed on function $f due to thrown error:")
      bt = catch_backtrace()
      s = sprint(io->Base.show_backtrace(io, bt))
      println("$s")
      fails += 1
    end
  end
end
