#john-addition-test.jl

include("../unum.jl")
using Unums

#do addition of random numbers in a set of environments

const iters = 100000

#set up arrays of values so that generating arrays is not part of the speed calc

function exprand()
  exp(randn() * 100) * (rand() > 0.5 ? 1: - 1)
end

function add_test(T::Type)

  a = [convert(T, exprand()) for i=1:iters]
  b = [convert(T, exprand()) for i=1:iters]

  println("testing $T")
  tic()
    #i don't think that llvm aggressively optimizes this out since we don't use the result.
    for (idx = 1:iters)
      a[idx] + b[idx]
    end
  toc()
end

function random_with_ulp(T::Type)
  x = convert(T, rand())
  (rand() > 0.5) ? x : unum_unsafe(x, x.flags | Unums.UNUM_UBIT_MASK)
end

function add_test_ulp(T::Type)
  a = [random_with_ulp(T) for i=1:iters]
  b = [random_with_ulp(T) for i=1:iters]

  println("testing with ulps $T")
  tic()
    #i don't think that llvm aggressively optimizes this out since we don't use the result.
    for (idx = 1:iters)
      a[idx] + b[idx]
    end
  toc()
end

Unums.__unum_release_environment()
#map the add_test function onto an array of types we want to run it on!
map(add_test, [Float64, BigFloat, Unum{0,0}, Unum{1,1}, Unum{3,3}, Unum{4,6}, Unum{4,7}, Unum{4,8}])
map(add_test_ulp, [Unum{0,0}, Unum{1,1}, Unum{3,3}, Unum{4,6}, Unum{4,7}, Unum{4,8}])
