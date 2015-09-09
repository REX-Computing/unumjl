#unum_optimizer.jl

#takes a function and repeatedly runs it until it gives appropriate precision.

function optimize(f, lim, sess = 0, sfss = 0; verbose = false)
  res = 0
  for (idx = 1:20)
    T = Unum{sess, sfss}
    res = f(T)
    verbose && println("environment {$sess, $sfss} result: $(describe(res))")
    #for now, use floating point here.
    if (typeof(res) <: Ubound)
      if (is_sss(res.lowbound) || is_sss(res.highbound) || is_mmr(res.lowbound) || is_mmr(res.highbound))
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
    u_w = width(res)
    unum_w = (typeof(u_w) <: Ubound) ? u_w.highbound : u_w
    unum_r = (typeof(res) <: Ubound) ? res.lowbound : res
    rel_w = float64(unum_w) / float64(unum_r)
    if rel_w < lim
      break
    else
      verbose && println("inexact; width $rel_w > $lim")
      sfss += 1
    end
  end
  res
end
