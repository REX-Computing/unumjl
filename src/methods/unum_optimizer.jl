#unum_optimizer.jl

#takes a function and repeatedly runs it until it gives appropriate precision.
function optimize(f, lim, sess = 0, sfss = 0; verbose = false)
  res = 0
  for (idx = 1:20)
    T = Unum{sess, sfss}
    res = f(T)
    verbose && println("environment {$sess, $sfss} result: ")
    describe(res)
    #for now, use floating point here.
    if (typeof(res) <: Ubound)
      if (is_sss(res.lower) || is_sss(res.lower) || is_mmr(res.upper) || is_mmr(res.upper))
        verbose && println("overflow")
        sess += 1
        sfss += 1
        continue
      end
    elseif (typeof(res) <: Unum)
      if (is_sss(res) || is_mmr(res))
        verbose && println("overflow")
        sess += 1
        sfss += 1
        continue
      end
    end
    unum_w = if (typeof(res) <: Ubound)
               calculate(res.upper) - calculate(res.lower)
             elseif is_ulp(res)
               abs(calculate(Unums.__outward_exact(res)) - calculate(Unums.__inward_exact(res)))
             else
               0
             end
    unum_r = (typeof(res) <: Ubound) ? abs(calculate(res.lower)) : abs(calculate(res))
    rel_w = unum_w / unum_r
    if rel_w < lim
      verbose && println("solved; rel. width $rel_w < $lim")
      break
    else
      verbose && println("too inexact; rel. width $rel_w > $lim")
      sfss += 1
    end
  end
  res
end
