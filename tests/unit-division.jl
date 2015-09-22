#unum-test-division.jl

#generate random floats and see if they work.
#for idx = 1:100
#  df = 2 * rand(Float64) - 1
#  ef = 2 * rand(Float64) - 1
#  d = convert(Unum{4,6}, df)
#  e = convert(Unum{4,6}, ef)
#  gf = df / ef
#  g = d / e
#  diff = gf - convert(Float64,g)
#  @test (diff < 0.00001)
#end

#some simple tests in Unum{4,5}
x = convert(Unum{4,5}, 30.0)
y = convert(Unum{4,5}, 1.5)
z = Unums.__div_exact(x, y)
println(bits(z, " "))
