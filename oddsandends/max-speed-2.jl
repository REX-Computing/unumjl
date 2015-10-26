#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#max-speed-2.jl

#testing the use of max versus ternary operator for uint16s for __fsize_of_exact

const count = 1000000

function testy()

  test1 = [(rand() < 0.5) ? uint16(0) : rand(Uint16) for i=1:count]

  res::Uint16 = 0
  println("using max()")
  tic()
  for (i=1:count)
    res += max(0, test1[i] - 1)
  end
  toc()
  println(res)

  println("using max() with potential conversion")
  tic()
  for (i=1:count)
    res += uint16(max(0, test1[i] - 1))
  end
  toc()
  println(res)

  res = 0
  println("using ternary op")
  tic()
  for (i=1:count)
    res += (test1[i] == 0) ? 0 : test1[i] - 1
  end
  toc()
  println(res)

  res = 0
  println("using ternary op with assignment")
  tic()
  for (i=1:count)
    temp = test1[i]
    res += (temp == 0) ? 0 : temp - 1
  end
  toc()
  println(res)
end

testy()
testy()
testy()

#and let's double check that the max result is the same.
function testy2()  #variable type annotations only valid within function blocks
  test2 = [0, 1, 2] #result should be [0, 0, 1]
  r::Uint16 = 0
  for (i=1:3)
    r = max(0, test2[i] - 1)
    println(r)
    println(typeof(r))
  end
end
testy2()

#30 Aug 2015
#results, third run only, 'res printlns' edited out.
#using max()
#elapsed time: 0.001808343 seconds
#using max() with potential conversion
#elapsed time: 0.001754662 seconds
#using ternary op
#elapsed time: 0.007478182 seconds
#using ternary op with assignment
#elapsed time: 0.007068262 seconds
#0
#0
#1
#result:  Using max() is still faster, and produces the desired results.
