#integerchallenge.jl

include("../methods/unum_optimizer.jl")

using Unums

const limit = 100_000_000

function addtolimit(T::Type)
  sum = one(T)
  for idx = 1:limit
    sum += one(T)
  end
  #println(Unums.calculate(sum))
  sum
end

r = optimize(addtolimit, 0.1, verbose = true)
describe(r)
