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

function spans_zero(x)
  isa(x, Unum) && return is_zero(x)  #a unum must be exactly zero to span zero.
  is_negative(x.lowbound) && is_positive(x.highbound)
end

function spy1(v)
  print("testing: ", describe(v))
  v
end

function spy2(v)
  println(v ? " crosses" : " does not cross")
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
      println("result is:", describe(fv))
      (is_sss(fv.lowbound) || is_sss(fv.highbound) || is_mmr(fv.lowbound) || is_mmr(fv.highbound)) && return true
    else
      (is_sss(fv) || is_mmr(fv)) && return true
    end
  end
  return false
end

function solve(f, lim, sess = 0, sfss = 0; verbose = false)
  #walk the number line in the starting environment.
  #compose the passed function with the spans_zero assesment to create the boolean-valued
  #analyzer function.
  bf(v) = spy2(spans_zero(f(spy1(v))))

  res = fullwalk(bf, sess, sfss)

  while (true)
    #first, check to see if we have any results.
    (length(res) == 0) && return res
    #check to see if we meet the termination condition.
    if more_exponent_necessary(f, res)
      if (verbose)
        println("overflow error in environment {$sess, $sfss}")
        println("passed solutions:")
        map((d)->println(describe(d)), res)
      end
      res = mapreduce((d)->promote_ess(bf, d), vcat, [], res)
      println("r ", res)
      sess += 1
      continue
    end
    #break
#=
    #next, check to see if we have exhausted the fsize variable
    if (res[1].fsize < max_fsize(sfss))
      T = typeof(res[1])
      #collate results from bitwalk together.
      res = mapreduce((d)->bitwalk(bf, d, true), vcat, [] , res)
    else
      if resolution_unsatisfied(f, res, lim)
        res = map(promote_fss, res)
        sfss += 1
        continue
      end
    end=#
  end
  res
end

export solve
