#unum_solver.jl

#takes a function and finds the zeroes.

function scalc{ESS,FSS}(x::Unum{ESS,FSS})
  #string(calculate(x))
  string(convert(Float64, x))
end

function scalc{ESS,FSS}(x::Ubound{ESS,FSS})
  #string(calculate(x.lowbound), "->", calculate(x.highbound))
  string(convert(Float64, x.lowbound), "->", convert(Float64, x.highbound))
end

function spans_zero(x, y)
  if isa(x, Unum)
    #analyzes the input unum and the output and decides if it should report that it crosses zero.
    if is_exact(x)  #exact unums must result in exactly zero to qualify.
      isa(y, Ubound) && return false
      return is_zero(y)  #a unum must be exactly zero to qualify as spanning zero.
    end
  end
  #inexact unums and ubounds must span zero; and basically have to result in ubounds.
  isa(y, Unum) && return is_zero(y)  #a unum result must be exactly zero to span zero
  is_negative(y.lowbound) && is_positive(y.highbound)
end

function spy1(v)
  print("testing: ", describe(v))
  v
end

function spy2(v)
  println(v ? " crosses" : " does not cross")
  v
end

function spy3(v)
  print(" result: ", describe(v))
  v
end

#runs an analysis on the result and decides if more exponent is necessary.
function more_exponent_necessary(f, a)
  #first check to see if any of the values in the array warrant increasing the exponent.
  for (idx = 1:length(a))
    #is the value outright mmr or sss?
    (is_mmr(a[idx]) || is_sss(a[idx])) && return true
    #next check the function evaluated at this value.
    fv = f(a[idx])
    if isa(fv, Ubound)
      (is_sss(fv.lowbound) || is_sss(fv.highbound) || is_mmr(fv.lowbound) || is_mmr(fv.highbound)) && return true
    else
      (is_sss(fv) || is_mmr(fv)) && return true
    end
  end
  return false
end

function bignum_relative_width(x::Unum)
  abs(calculate(width(x)) / calculate(x))
end

function solve(f, lim, sess = 0, sfss = 0; verbose = false)
  #walk the number line in the starting environment.
  #compose the passed function with the spans_zero assesment to create the boolean-valued
  #analyzer function.
  bf(v) = spy2(spans_zero(v, spy3(f(spy1(v)))))
  bw(v) = bitwalk(bf, v, true, true)

  res = fullwalk(bf, sess, sfss)

  function report()
    if verbose
      println("passed solutions:")
      map((d) -> println(describe(d)), res)
    end
  end

  report()

  while (true)
    #first, check to see if we have any results.
    (length(res) == 0) && return res
    #check to see if we meet the termination condition.
    if more_exponent_necessary(f, res)
      verbose && println("overflow error in environment {$sess, $sfss}")
      report()

      res = mapreduce((d)->promote_ess(bf, d), vcat, [], res)
      sess += 1
      continue
    end

    #calculate the worst width within the set of solution ulps.
    worst_width = mapreduce(bignum_relative_width, max, 0.0, res)
    verbose && println("worst width across solution set: ", worst_width)
    (worst_width < lim) && break
    verbose && println("does not satisfy criterion < ", lim)

    #check to see if we are already at the maximum size, in which case, promote the fss.
    if res[1].fsize == max_fsize(sfss)
      verbose && println("promoting fss across the result set")
      res = map(promote_fss, res)
      sfss += 1
    end

    report()
    #apply bitwalker across the entire set.
    res = mapreduce(bw, vcat, [], res)
  end
  res
end

export solve
