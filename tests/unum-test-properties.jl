#unum-test-properties.jl

#tests the properties functions

#nextunum
x = Unum{4, 4}(uint16(7), uint16(3), UBIT_MASK, 0x0000_0000_0000_0000, uint64(3))
println(bits(x, " "))
y = nextunum(x)
println(bits(y, " "))

#isnan
#isfinite
#issubnormal
#isffraczero
#iszero

@test iszero(zero(Unum{4,6}))
@test !iszero(one(Unum{4,6}))

#isulp
