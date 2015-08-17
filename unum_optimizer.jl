#unum_optimizer.jl

#takes a function and repeatedly runs it until it gives appropriate precision.

function optimize(f, lim, sess = 0, sfss = 0)
  for (idx = 1:20)
    T = Unum{sess, sfss}
    res = f(T)
    println("environment {$sess, $sfss} result: $(describe(res))")
    if isalmostinf(res)
      sess += 1
      sfss += 1
    else
      break
    end
  end
end
