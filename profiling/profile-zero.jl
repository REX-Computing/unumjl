#profiling zero tests.

include ("../../unum.jl")

#run in unum{4,6} environment.  30% of the unums will have a ubit set.
#10% of the unums will be zero, 10% of them will be negative zero.
#10% of the unums will be a subnormal.

#calculates a random number between 0..i
function randint(i)
end

function randU(T)
  x = convert(T, randn())
  dieroll = rand()
  if (dieroll < 0.1)
    zero(T)
  elseif (dieroll < 0.2)
    -zero(T)
  elseif (dieroll < 0.3)
    T(z16, z16,
  else
    convert(T, rand())
  end
end

count = 100000

function profile(T)
  #generate the array.
  array = [randU() for i = 1:count]

  println("naive ordering")
  tic()
    map(iszero_naive, array)
  toc()

  println("optimized ordering")
  tic()
    map(iszero_naive, array)
  toc()
end
