#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


function sumtest_nobounds(a::Array{Float64, 1})
  sum = 0.0
  for idx=1:length(a)
    sum += a[idx]
  end
  sum
end

function sumtest_inbounds(a::Array{Float64, 1})
  sum = 0.0
  for idx=1:length(a)
    @inbounds sum += a[idx]
  end
  sum
end

function sumtest_prevar(a::Array{Float64, 1})
  l::Int64 = length(a)
  sum = 0.0
  for idx = 1:l
    @inbounds sum += a[idx]
  end
  sum
end

count = 10000

alist = [rand(1000) for idx = 1:count]

function testwith(f, aofa)
  for idx=1:count
    f(aofa[idx])
  end
end

function run()
@time testwith(sumtest_nobounds, alist)
@time testwith(sumtest_inbounds, alist)
@time testwith(sumtest_prevar, alist)
end

for idx = 1:10
  run()
end
