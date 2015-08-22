#unit-convert.jl
#unit tests methods to convert unums

#TEST helper functions
#bitof - retrieves single bits from an int64, zero indexed.

#integer to unum

@test [calculate(convert(Unum{3,6},i)) for i=-50:50] == [BigFloat(i) for i = -50:50]

#subnormal unums
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
#test that the general conversion works for normal floating points in the {4,6} environment

seed = randn(100)
f16a = [BigFloat(float16(seed[i])) for i = 1:100]
f32a = [BigFloat(float32(seed[i])) for i = 1:100]
f64a = [BigFloat(float64(seed[i])) for i = 1:100]
c16a = [calculate(convert(Unum{4,6}, float16(seed[i]))) for i = 1:100]
c32a = [calculate(convert(Unum{4,6}, float32(seed[i]))) for i = 1:100]
c64a = [calculate(convert(Unum{4,6}, float64(seed[i]))) for i = 1:100]
@test f16a == c16a
@test f32a == c32a
@test f64a == c64a

#test that NaNs convert.
@test isnan(convert(Unum{4,6}, NaN16))
@test isnan(convert(Unum{4,6}, NaN32))
@test isnan(convert(Unum{4,6}, NaN))
#and positive and negative Infs
@test ispinf(convert(Unum{4,6}, Inf16))
@test ispinf(convert(Unum{4,6}, Inf32))
@test ispinf(convert(Unum{4,6}, Inf))
@test isninf(convert(Unum{4,6}, -Inf16))
@test isninf(convert(Unum{4,6}, -Inf32))
@test isninf(convert(Unum{4,6}, -Inf))
