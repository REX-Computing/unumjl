#john-addition-test.jl

include("unum.jl")
using Unums

#do addition of random numbers in a set of environments

const iters = 100000

#set up arrays of values so that generating arrays is not part of the speed calc

function add_test(T::Type)

  a = [convert(T, rand()) for i=1:iters]
  b = [convert(T, rand()) for i=1:iters]

  println("testing $T")
  tic()
    #i don't think that llvm aggressively optimizes this out since we don't use the result.
    a + b
  toc()
end

#map the add_test function onto an array of types we want to run it on!
map(add_test, [Float64, BigFloat, Unum{4,6}])
