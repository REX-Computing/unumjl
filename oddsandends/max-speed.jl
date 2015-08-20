#maximum-speed.jl

#let's test and see what is the best way of finding the maximum of two numbers?

const count = 1000000

#enclose in a function body because in julia there are no constant type globals.
function testy(T::Type)
println("running for $T")

#generate a series of arrays
test1 = [rand(T) for i=1:count]
test2 = [rand(T) for i=1:count]
test3 = [zero(T) for i=1:count]

res = 0

println("using max()")
tic()
for (i=1:count)
  res = max(test1[i], test2[i])
end
toc()
println(res)

println("using max() against zero, uint")
tic()
for (i=1:count)
  res = max(test1[i], test3[i])
end
toc()
println(res)

println("using min() against zero, uint")
tic()
for (i=1:count)
  res = min(test1[i], test3[i])
end
toc()
println(res)

println("using ternary op")
tic()
for (i=1:count)
  res = (test1[i] > test2[i]) ? test1[i] : test2[i]
end
toc()
println(res)

println("using if...then")
tic()
for (i=1:count)
  if (test1[i] > test2[i])
    res = test1[i]
  else
    res = test2[i]
  end
end
toc()
println(res)

println("using comparison against zero")
tic()
for (i=1:count)
  res = (test2[i] == 0) ? test1[i] : test2[i]
end
toc()
println(res)

println("using comparison not zero")
tic()
for (i=1:count)
  res = (test1[i] != 0) ? test1[i] : test2[i]
end
toc()
println(res)

println("----")
end

testy(Uint64)
testy(Int64)
testy(Uint64)
testy(Int64)
testy(Uint64)
testy(Int64)

#20 Aug 2015
#results, last section only, println(s) edited out.

#running for Uint64
#using max()
#elapsed time: 0.015386148 seconds
#using max() against zero, uint
#elapsed time: 0.036181472 seconds
#using min() against zero, uint
#elapsed time: 0.004971114 seconds
#using ternary op
#elapsed time: 0.021031701 seconds
#using if...then
#elapsed time: 0.021056531 seconds
#using comparison against zero
#elapsed time: 0.040860501 seconds
#using comparison not zero
#elapsed time: 0.014127978 seconds

#running for Int64
#elapsed time: 0.00130995 seconds
#using max() against zero, uint
#elapsed time: 0.001307646 seconds
#using min() against zero, uint
#elapsed time: 0.001316235 seconds
#using ternary op
#elapsed time: 0.00957752 seconds
#using if...then
#elapsed time: 0.008764473 seconds
#using comparison against zero
#elapsed time: 0.001603041 seconds
#using comparison not zero
#elapsed time: 0.001535636 seconds

#results.  Int64 max() and min() functions are MUCH faster.  if/then vs. ternary
#has no speed advantage.  Almost certainly the JNZ() directive is making a
#difference, but it seems alwasy better to just use max() or min().  Strangely
#terary op is worse for unsigned ints than it is for signed ints.
