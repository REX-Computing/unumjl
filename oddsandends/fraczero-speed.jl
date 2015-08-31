#fraczero-speed.jl

#testing to see how fast we can test to see if the fraction is zero.

#method #1 - compare against the zero array.

const count = 1000000

function constfn(b, i)
  b && (i == zero(Uint64))
end

function forloopfn(b)
  for idx = 1:length(b)
    b[idx] != 0 && return false
  end
  return true
end

function forloopfn2(b)
  for idx = length(b):-1:1
    b[idx] != 0 && return false
  end
  return true
end

function testy()

#make a cell array which will hold four-unit int64 arrays
arrays = cell(count)
for idx = 1:count
  arrays[idx] = [(rand() < 0.25) ? zero(Uint64) : rand(Uint64) for jdx = 1:4]
end

println("by comparing against a zero array.")
sum = 0
tic()
for (i=1:count)
  sum += (arrays[i] == zeros(Uint64, 4)) ? 1 : 0
end
toc()
#println forces julia to use the result and not compile it away.
println(sum)

println("by comparing against a cached zero array.")
cache = zeros(Uint64, 4)
sum = 0
tic()
for (i=1:count)
  sum += (arrays[i] == cache) ? 1 : 0
end
toc()
#println forces julia to use the result and not compile it away.
println(sum)

println("by mapping an anonymous function")
sum = 0
tic()
for (i=1:count)
  sum += (reduce((b, i) -> b && (i == zero(Uint64)), true, arrays[i])) ? 1 : 0
end
toc()
#println forces julia to use the result and not compile it away.
println(sum)

println("by mapping a cached anonymous function.")
cachefn = (b, i) -> b && (i == zero(Uint64))
sum = 0
tic()
for (i=1:count)
  sum += (reduce(cachefn, true, arrays[i])) ? 1 : 0
end
toc()
#println forces julia to use the result and not compile it away.
println(sum)

println("by mapping a const function.")
sum = 0
tic()
for (i=1:count)
  sum += (reduce(constfn, true, arrays[i])) ? 1 : 0
end
toc()
#println forces julia to use the result and not compile it away.
println(sum)

println("with a breakaway for loop.")
sum = 0
tic()
for (i=1:count)
  sum += (forloopfn(arrays[i])) ? 1 : 0
end
toc()
#println forces julia to use the result and not compile it away.
println(sum)


println("breakaway for loop, downwards.")
sum = 0
tic()
for (i=1:count)
  sum += (forloopfn2(arrays[i])) ? 1 : 0
end
toc()
#println forces julia to use the result and not compile it away.
println(sum)
end

testy()
testy()
testy()

#results:  a breakaway for loop was definitely the fastest.  It's not even a contest.

#by comparing against a zero array.
#elapsed time: 0.234025668 seconds
#by comparing against a cached zero array.
#elapsed time: 0.17063435 seconds
#by mapping an anonymous function
#elapsed time: 0.297591116 seconds
#by mapping a cached anonymous function.
#elapsed time: 0.300173192 seconds
#by mapping a const function.
#elapsed time: 0.290023684 seconds
#with a breakaway for loop.
#elapsed time: 0.031858592 seconds
#breakaway for loop, downwards.
#elapsed time: 0.037607769 seconds
