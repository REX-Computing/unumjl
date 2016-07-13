#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
#unum_optimizer.jl

import Unums: is_zero_ulp, is_inf_ulp

#takes a function and repeatedly runs it until it gives appropriate precision.
function optimize(f, lim, sess = 0, sfss = 0; verbose = false)
  res = 0
  for (idx = 1:20)
    T = Unum{sess, sfss}
    res = f(T)
    verbose && println("environment {$sess, $sfss} result: ")
    verbose && describe(res)
    #for now, use floating point here.
    if (typeof(res) <: Ubound)
      if (is_zero_ulp(res.lower) || is_zero_ulp(res.upper) || is_inf_ulp(res.lower) || is_inf_ulp(res.upper))
        verbose && println("overflow")
        sess += 1
        sfss += 1
        continue
      end
    elseif (typeof(res) <: Unum)
      if (is_zero_ulp(res) || is_inf_ulp(res))
        verbose && println("overflow")
        sess += 1
        sfss += 1
        continue
      end
    end
    unum_w = if (typeof(res) <: Ubound)
               calculate(res.upper) - calculate(res.lower)
             elseif is_ulp(res)
               abs(calculate(Unums.outer_exact(res)) - calculate(Unums.inner_exact(res)))
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
