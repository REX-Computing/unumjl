#unum_optimizer.jl

#takes a function and repeatedly runs it until it gives appropriate precision.

function scalc{ESS,FSS}(x::Unum{ESS,FSS})
  #string(calculate(x))
  string(convert(Float64, x))
end

function scalc{ESS,FSS}(x::Ubound{ESS,FSS})
  #string(calculate(x.lowbound), "->", calculate(x.highbound))
  string(convert(Float64, x.lowbound), "->", convert(Float64, x.highbound))
end

function optimize(f, lim, sess = 0, sfss = 0; verbose = false)
  res = 0
  for (idx = 1:20)
    T = Unum{sess, sfss}
    res = f(T)
    verbose && println("environment {$sess, $sfss} result: $(scalc(res))")
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
    unum_w = if (typeof(res) <: Ubound)
               calculate(res.highbound) - calculate(res.lowbound)
             elseif is_ulp(res)
               abs(calculate(Unums.__outward_exact(res)) - calculate(Unums.__inward_exact(res)))
             else
               0
             end
    unum_r = (typeof(res) <: Ubound) ? abs(calculate(res.lowbound)) : abs(calculate(res))
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
