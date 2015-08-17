#unum-test-addition.jl

#testing addition

#generate random floats and see if they work.
for idx = 1:100
  df = rand(Float64)
  ef = rand(Float64)
  d = convert(Unum{4,6}, df)
  e = convert(Unum{4,6}, ef)
  gf = df + ef
  g = d + e
  diff = gf - convert(Float64,g)
  @test (diff < 0.00001)
end

for idx = 1:100
  df = rand(Float64)
  ef = rand(Float64)
  d = convert(Unum{4,6}, df)
  e = convert(Unum{4,6}, ef)
  gf = df - ef
  g = d - e
  diff = gf - convert(Float64,g)
  @test (diff < 0.00001)
end

for idx = 1:100
  df = 1.0
  ef = 5*rand(Float64)
  d = one(Unum{4,6})
  e = convert(Unum{4,6}, ef)
  gf = df - ef
  g = d - e
  diff = gf - convert(Float64,g)
  @test (diff < 0.00001)
end

#subnormal mathematics

#corner cases on unusual values.
#zero should return an identical value
#adding to +inf should return inf.
#add to max-ulp should return max-ulp
#inf + -inf should be NaN
#subtracting from supermax should yield a different ulp



#performance testing.
uarray = [ convert(Unum{4,6},rand(Float64)) for idx=1:10000 ]
function myriadds(a, v)
  tic()
  for idx = 1:10000
    a[idx] + v
  end
  toq()
end

#Add zero should be faster than add a different integer.
z = zero(Unum{4,6})
o = one(Unum{4,6})

if (rand() < 0.5)
  tone = myriadds(uarray, o)
  tzero = myriadds(uarray, z)
else
  tzero = myriadds(uarray, z)
  tone = myriadds(uarray, o)
end
@test tzero < tone
