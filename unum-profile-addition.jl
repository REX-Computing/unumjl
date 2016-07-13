#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
include("unum.jl")
using Unums

#profile basic addition
x = Unum{4,6}

uarray = [convert(Unum{4,6}, rand()) for i = 1:100000]
farray = [rand() for i = 1:100000]
barray = [big(rand()) for i = 1:100000]

u = zero(Unum{4,6})
tic()
for i = 1:100000
  u += uarray[i]
end
toc()

f = zero(Float64)
tic()
for i = 1:100000
  f += farray[i]
end
toc()

b = zero(BigFloat)
tic()
for i = 1:100000
  b += barray[i]
end
toc()
