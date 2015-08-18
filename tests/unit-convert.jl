#unit-convert.jl
#unit tests methods to convert unums

#TEST helper functions
#bitof - retrieves single bits from an int64, zero indexed.

#integer to unum
@test [convert(Float16, convert(Unum{3,6},i)) for i=-50:50] == [float16(i) for i = -50:50]
@test [convert(Float32, convert(Unum{3,6},i)) for i=-50:50] == [float32(i) for i = -50:50]
@test [convert(Float64, convert(Unum{3,6},i)) for i=-50:50] == [float64(i) for i = -50:50]
#repeat the same, with realllly large unums
@test [convert(Float16, convert(Unum{5,9},i)) for i=-50:50] == [float16(i) for i = -50:50]
@test [convert(Float32, convert(Unum{5,9},i)) for i=-50:50] == [float32(i) for i = -50:50]
@test [convert(Float64, convert(Unum{5,9},i)) for i=-50:50] == [float64(i) for i = -50:50]
#denormal unums
#at lower resolution than the float
#at equal resolution to the float
#at higher resolution to the float

#unum to integer

#unum to float
#generate random bits in the unum
#for ess = 1:5
#  for fss = 1:6
#    for idx = 1:100
#      esize = uint16(rand(Uint64) & Unums.mask(ess))
#      fsize = uint16(rand(Uint64) & Unums.mask(fss))
#      exponent = rand(Uint64) & Unums.mask(esize + 1)
#      fraction = rand(Uint64) & Unums.mask(-(fsize + 1))
#      uval = float64(Unum{ess,fss}(fsize, esize, zero(Uint16), fraction, exponent))
#      cval = 2.0^(exponent - 2.0^(esize - 1)) * (big(fraction) / 2.0^64)
#    end
#  end
#end

#float to unum

#stress test both-ways conversions with random floats.
#scales = [100, 1, 1/100]
#rtypes = [Float16, Float32, Float64] #note that Float16 will hit small subnormals in these scales.
#rtypes = [Float32, Float64]
#for s in scales
#  for T in rtypes
#    for idx = 1:100
      #pick a normally distributed, random number and convert to float.
#      test = convert(T, randn() * s)
      #convert the test subject to a wide unum.
#      utest = convert(Unum{4,6}, test)
      #convert back to floating point.
#      testres = convert(T, utest)
      #make sure we got it right.
#      @test (test == testres)
#    end
#  end
#end
