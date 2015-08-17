#unum-test-multiplication.jl

#testing chunk multiplication
a = 0xFFFFFFFFFFFFFFFF
b = 0xFFFFFFFFFFFFFFFF

#generate random int64s and see if they work.
for idx = 1:100
  a = rand(Uint64)
  b = rand(Uint64)
  r1 = a * b
  r2 = uint64(big(a) * big(b) >> 64)
  r = Unums.__chunk_mult(a,b)
  @test (r1 == r[1]) && (r2 == r[2])
end

#testing multiplication with unums in general

#generate random floats and see if they work.
for idx = 1:100
  df = rand(Float64)
  ef = rand(Float64)
  d = convert(Unum{4,6}, df)
  e = convert(Unum{4,6}, ef)
  gf = df * ef
  g = d * e
  diff = gf - convert(Float64,g)
  @test (diff < 0.00001)
end
