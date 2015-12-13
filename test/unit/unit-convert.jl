#unit-convert.jl
#unit tests methods to convert unums

#TEST helper functions
#bitof - retrieves single bits from an int64, zero indexed.

#integer to unum

@test [calculate(convert(Unum{3,6},i)) for i=-50:50] == [BigFloat(i) for i = -50:50]
@test is_mmr(convert(Unum{0,0}, 3))

#test to make sure that accidentally hacking the infinity value instead produces mmr.
@test is_mmr(convert(Unum{1,1}, 7))
@test is_mmr(convert(Unum{1,1}, 8))

#unum to integer

#unum to unum
#from a small unum - to a bigger small unum.
@test convert(Unum{4,6}, Unum{0,0}(z16, z16, z16, z64, z64)) == Unum{4,6}(z16, z16, z16, z64, z64)
#from a bigger small unum - to a smaller unum, with no trimming.
@test convert(Unum{1,1}, one(Unum{4,6})) == one(Unum{1,1})
#from a big small unum to a smaller unum which requires subnormality.
@test convert(Unum{0,0}, one(Unum{4,6})) == one(Unum{0,0})
#from a really big unum to a small unum requiring subnormality.
@test convert(Unum{0,0}, one(Unum{4,7})) == one(Unum{0,0})

@test convert(Unum{0,0}, zero(Unum{4,6})) == zero(Unum{0,0})
@test convert(Unum{4,6}, zero(Unum{0,0})) == zero(Unum{0,0})

@test convert(Unum{0,0}, sss(Unum{4,7})) == sss(Unum{0,0})
@test convert(Unum{4,6}, sss(Unum{0,0})) == Unum{4,7}(z16, z16, Unums.UNUM_UBIT_MASK, z64, z64)


#float to unum
#test that the general conversion works for normal floating points in the {4,6} environment

seed = randn(100)
f16a = [BigFloat(Float16(seed[i])) for i = 1:100]
f32a = [BigFloat(Float32(seed[i])) for i = 1:100]
f64a = [BigFloat(Float64(seed[i])) for i = 1:100]
c16a = [calculate(convert(Unum{4,6}, Float16(seed[i]))) for i = 1:100]
c32a = [calculate(convert(Unum{4,6}, Float32(seed[i]))) for i = 1:100]
c64a = [calculate(convert(Unum{4,6}, Float64(seed[i]))) for i = 1:100]
@test f16a == c16a
@test f32a == c32a
@test f64a == c64a

#test that NaNs convert.
@test isnan(convert(Unum{4,6}, NaN16))
@test isnan(convert(Unum{4,6}, NaN32))
@test isnan(convert(Unum{4,6}, NaN))
#and positive and negative Infs
@test is_pos_inf(convert(Unum{4,6}, Inf16))
@test is_pos_inf(convert(Unum{4,6}, Inf32))
@test is_pos_inf(convert(Unum{4,6}, Inf))
@test is_neg_inf(convert(Unum{4,6}, -Inf16))
@test is_neg_inf(convert(Unum{4,6}, -Inf32))
@test is_neg_inf(convert(Unum{4,6}, -Inf))
#test that zero converts correctly
@test is_zero(convert(Unum{4,6}, zero(Float16)))
@test is_zero(convert(Unum{4,6}, zero(Float32)))
@test is_zero(convert(Unum{4,6}, zero(Float64)))

#test some subnormal numbers.
f16sn = reinterpret(Float16, one(UInt16))
@test calculate(convert(Unum{4,6}, f16sn)) == BigFloat(f16sn)
f32sn = reinterpret(Float32, one(UInt32))
@test calculate(convert(Unum{4,6}, f32sn)) == BigFloat(f32sn)
f64sn = reinterpret(Float64, one(UInt64))
@test calculate(convert(Unum{4,6}, f64sn)) == BigFloat(f64sn)

#test pushing exact into a unum's subnormal range.
justsubnormal(ess) = reinterpret(Float64,(Unums.min_exponent(ess) + 1022) << 52)
smallsubnormal(ess, fss) = reinterpret(Float64,(Unums.min_exponent(ess) - Unums.max_fsize(fss) + 1022) << 52)
pastsubnormal(ess, fss) = reinterpret(Float64,(Unums.min_exponent(ess) - Unums.max_fsize(fss) + 1021) << 52)
@test calculate(convert(Unum{0,0}, justsubnormal(0))) == BigFloat(justsubnormal(0))
@test calculate(convert(Unum{1,1}, justsubnormal(1))) == BigFloat(justsubnormal(1))
@test calculate(convert(Unum{2,2}, justsubnormal(2))) == BigFloat(justsubnormal(2))
@test calculate(convert(Unum{3,3}, justsubnormal(3))) == BigFloat(justsubnormal(3))
@test calculate(convert(Unum{0,0}, smallsubnormal(0,0))) == BigFloat(smallsubnormal(0,0))
@test calculate(convert(Unum{1,1}, smallsubnormal(1,1))) == BigFloat(smallsubnormal(1,1))
@test calculate(convert(Unum{2,2}, smallsubnormal(2,2))) == BigFloat(smallsubnormal(2,2))
@test calculate(convert(Unum{3,3}, smallsubnormal(3,3))) == BigFloat(smallsubnormal(3,3))
@test is_sss(convert(Unum{0,0}, pastsubnormal(0,0)))
@test is_sss(convert(Unum{1,1}, pastsubnormal(1,1)))
@test is_sss(convert(Unum{2,2}, pastsubnormal(2,2)))
@test is_sss(convert(Unum{3,3}, pastsubnormal(3,3)))
tinyfloat = reinterpret(Float64, o64)
@test is_sss(convert(Unum{0,0}, tinyfloat))
@test is_sss(convert(Unum{1,1}, tinyfloat))
@test is_sss(convert(Unum{2,2}, tinyfloat))
@test is_sss(convert(Unum{3,3}, tinyfloat))

#and into the isalmostinf range.
@test is_mmr(convert(Unum{0,0}, 2.2))
@test is_mmr(convert(Unum{1,1}, 8.2))

#test converting into really big unums.
@test convert(Unum{4,7}, 1.0) == one(Unum{4,7})
@test convert(Unum{4,8}, 1.0) == one(Unum{4,8})

#unum to float

#test random numbers by bootstropping off of the float to unum conversion.
seed = randn(100)
f16a = [Float16(seed[i]) for i = 1:100]
f32a = [Float32(seed[i]) for i = 1:100]
f64a = [Float64(seed[i]) for i = 1:100]
@test f16a == map((x) -> convert(Float16, convert(Unum{4,6}, x)), f16a)
@test f32a == map((x) -> convert(Float32, convert(Unum{4,6}, x)), f32a)
@test f64a == map((x) -> convert(Float64, convert(Unum{4,6}, x)), f64a)

#test that NaNs convert in more than one Unum environment
@test NaN16 === convert(Float16, nan(Unum{0,0}))
@test NaN32 === convert(Float32, nan(Unum{0,0}))
@test NaN   === convert(Float64, nan(Unum{0,0}))
@test NaN16 === convert(Float16, nan(Unum{4,6}))
@test NaN32 === convert(Float32, nan(Unum{4,6}))
@test NaN   === convert(Float64, nan(Unum{4,6}))
#test that positive infs convert in more than one Unum environment
@test Inf16 == convert(Float16, pos_inf(Unum{0,0}))
@test Inf32 == convert(Float32, pos_inf(Unum{0,0}))
@test Inf   == convert(Float64, pos_inf(Unum{0,0}))
@test Inf16 == convert(Float16, pos_inf(Unum{4,6}))
@test Inf32 == convert(Float32, pos_inf(Unum{4,6}))
@test Inf   == convert(Float64, pos_inf(Unum{4,6}))
@test -Inf16 == convert(Float16, neg_inf(Unum{0,0}))
@test -Inf32 == convert(Float32, neg_inf(Unum{0,0}))
@test -Inf   == convert(Float64, neg_inf(Unum{0,0}))
@test -Inf16 == convert(Float16, neg_inf(Unum{4,6}))
@test -Inf32 == convert(Float32, neg_inf(Unum{4,6}))
@test -Inf   == convert(Float64, neg_inf(Unum{4,6}))
#test that zero converts correctly in two environments
@test zero(Float16) == convert(Float16, zero(Unum{0,0}))
@test zero(Float32) == convert(Float32, zero(Unum{0,0}))
@test zero(Float64) == convert(Float64, zero(Unum{0,0}))
@test zero(Float16) == convert(Float16, zero(Unum{4,6}))
@test zero(Float32) == convert(Float32, zero(Unum{4,6}))
@test zero(Float64) == convert(Float64, zero(Unum{4,6}))
#test that subnormals convert correctly
@test 1.0 == convert(Float64, Unum{0,0}(z16, z16, z16, t64, z64))
#test converting *to* a subnormal float.
