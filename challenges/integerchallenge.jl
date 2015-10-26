#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#integerchallenge.jl

include("../unum.jl")
include("../unum_optimizer.jl")

using Unums

const limit = 10000000

function addtolimit(T::Type)
  sum = one(T)
  for idx = 1:limit
    sum += one(T)
  end
  #println(Unums.calculate(sum))
  sum
end

r = optimize(addtolimit, 0.1, verbose = true)
println("result:  $(float64(r))")
