#unum-test-addition.jl

#testing addition

################################################################################
## TESTING HELPER functions

#__carried_add
#double cell, double zero
test_array = Unums.ArrayNum{7}([z64, z64])
@test z64 == Unums.__carried_add!(z64, test_array, test_array)
@test test_array.a == [z64, z64]

@test o64 == Unums.__carried_add!(o64, test_array, test_array) #with a passthru carry
@test test_array.a == [z64, z64]

#double cell, less significant number adds in to carry
add_array = Unums.ArrayNum{7}([z64, f64])
test_array.a = [z64, o64]
@test z64 == Unums.__carried_add!(z64, add_array, test_array)
@test test_array.a == [o64, z64]

#double cell, double less significant number ff..ff
add_array.a = [z64, f64]
test_array.a = [z64, f64]
@test z64 == Unums.__carried_add!(z64, add_array, test_array)
@test test_array.a == [o64, ~o64]

#double cell, double upper ff..ff
add_array.a = [f64, z64]
test_array.a = [f64, z64]
@test o64 == Unums.__carried_add!(z64, add_array, test_array)
@test test_array.a == [~o64, z64]

#with a passthru carry
test_array.a = [f64, z64]
@test 2 == Unums.__carried_add!(o64, add_array, test_array)
@test test_array.a == [~o64, z64]

#create f's from whole cloth and pass it through
add_array.a = [0x9999_9999_9999_9999, f64]
test_array.a = [0x6666_6666_6666_6666, o64]
#@test 1 == Unums.__carried_add!(z64, add_array, test_array)
Unums.__carried_add!(z64, add_array, test_array)
@test test_array.a == [z64, z64]

#just let's make sure this works with even bigger arrays
test_array = Unums.ArrayNum{8}([f64, f64, f64, f64])
add_array = Unums.ArrayNum{8}([f64, f64, f64, f64])
@test 1 == Unums.__carried_add!(z64, add_array, test_array)
@test test_array.a == [f64, f64, f64, ~o64]

#test __sum_exact, which adds two exact sums, with magnitude(a) > magnitude(b)
wone = convert(Unum{4,6}, 1)
wtwo = convert(Unum{4,6}, 2)
wthr = convert(Unum{4,6}, 3)

@test wone + wone == wtwo
@test wtwo + wone == wthr

################################################################################
#unit tests discovered through debugging.

ten = convert(Unum{3,6}, 10)
fifteen = convert(Unum{3,6}, 15)
@test calculate(ten + fifteen) == 25

#=
=======
#double cell, double zero
@test (0, [0,0]) == Unums.__carried_add(z64, [z64, z64], [z64, z64])
@test (1, [0,0]) == Unums.__carried_add(o64, [z64, z64], [z64, z64]) #with a passthru carry
#double cell, lower add to carry
@test (0, [z64,1]) == Unums.__carried_add(z64, [f64, z64], [o64, z64])
@test (1, [z64,1]) == Unums.__carried_add(o64, [f64, z64], [o64, z64]) #with a passthru carry
#double cell, double lower ff..ff
@test (0, [~o64,1]) == Unums.__carried_add(z64, [f64, z64], [f64, z64])
@test (1, [~o64,1]) == Unums.__carried_add(o64, [f64, z64], [f64, z64]) #with a passthru carry
#double cell, double upper ff..ff
@test (1, [0,~o64]) == Unums.__carried_add(z64, [z64, f64], [z64, f64])
@test (2, [0,~o64]) == Unums.__carried_add(o64, [z64, f64], [z64, f64]) #with a passthru carry
#double cell, double full ff..ff
@test (1, [~o64,f64]) == Unums.__carried_add(z64, [f64, f64], [f64, f64])
@test (2, [~o64,f64]) == Unums.__carried_add(o64, [f64, f64], [f64, f64]) #with a passthru carry
#quad cell, double full ff.ff
@test (1, [~o64,f64,f64,f64]) == Unums.__carried_add(z64, [f64, f64, f64, f64], [f64, f64, f64, f64])
@test (2, [~o64,f64,f64,f64]) == Unums.__carried_add(o64, [f64, f64, f64, f64], [f64, f64, f64, f64]) #with a passthru carry

#__shift_after_add(carry, value) - resolves the result of a carry operation, and reports shift amt, and falloff.
@test Unums.__shift_after_add(UInt64(2), t64, z16) == (0x4000_0000_0000_0000, 1, z16)
@test Unums.__shift_after_add(UInt64(3), t64, z16) == (0xC000_0000_0000_0000, 1, z16)
@test Unums.__shift_after_add(UInt64(2), o64, z16) == (0x0000_0000_0000_0000, 1, Unums.UNUM_UBIT_MASK)
@test Unums.__shift_after_add(UInt64(3), o64, z16) == (0x8000_0000_0000_0000, 1, Unums.UNUM_UBIT_MASK)
@test Unums.__shift_after_add(UInt64(2), [z64,t64], z16) == ([z64, 0x4000_0000_0000_0000], 1, z16)
@test Unums.__shift_after_add(UInt64(3), [z64,t64], z16) == ([z64, 0xC000_0000_0000_0000], 1, z16)
@test Unums.__shift_after_add(UInt64(2), [o64,z64], z16) == ([z64, z64], 1, Unums.UNUM_UBIT_MASK)
@test Unums.__shift_after_add(UInt64(3), [o64,z64], z16) == ([z64, t64], 1, Unums.UNUM_UBIT_MASK)

#test __sum_exact, which adds two exact sums, with magnitude(a) > magnitude(b)
wone = Unum{4,6}(z16,z16,z16,z64,o64)
wtwo = Unum{4,6}(z16,UInt16(1),z16,z64,UInt64(3))
wthr = Unum{4,6}(z16,UInt16(1),z16,t64,UInt64(3))
@test Unums.__sum_exact(wone, wone, 0, 0) == wtwo   #one plus one is two
@test Unums.__sum_exact(wtwo, wone, 1, 0) == wthr   #one plus two is three

wbig =  Unum{4,6}(z16,    0x0007, z16,                  z64, UInt64(0xd0))
wbigu = Unum{4,6}(0x003f, 0x0007, Unums.UNUM_UBIT_MASK, z64, UInt64(0xd0))
wmed =  Unum{4,6}(z16,    0x0007, z16,                  z64, UInt64(0xc0))
wmd2 =  Unum{4,6}(z16,    0x0007, z16,                  z64, UInt64(0xbf))
whlf =  Unum{4,6}(z16,    0x0001, z16,                  z64, o64)
@test Unums.__sum_exact(wbig, wone, 80, 0) == wbigu
@test Unums.__sum_exact(wmed, wone, 64, 0)  == Unum{4,6}(0x003f, 0x0007, z16, o64,                   UInt64(0xc0))
@test Unums.__sum_exact(wmd2, wone, 63, 0)  == Unum{4,6}(0x003e, 0x0007, z16, UInt64(2),             UInt64(0xbf))
@test Unums.__sum_exact(wmed, wmd2, 64, 63) == Unum{4,6}(z16,    0x0007, z16, 0x8000_0000_0000_0000, UInt64(0xc0))
@test Unums.__sum_exact(wmed, whlf, 64, -1) == Unum{4,6}(0x003f, 0x0007, Unums.UNUM_UBIT_MASK, z64,   UInt64(0xc0))
#subnormal mathematics
wsml = Unum{4,6}(z16,    z16, z16, 0x8000_0000_0000_0000, z64)
wtny = Unum{4,6}(0x000F, z16, z16, 0x0001_0000_0000_0000, z64)
#println(Unums.__sum_exact(wsml, wtny, -1, -1))
@test Unums.__sum_exact(wsml, wtny, -1, -1) == Unum{4,6}(0x000F, z16, z16, 0x8001_0000_0000_0000, z64)
#note that wsml is also the same as whlf
@test wone == whlf + whlf
@test wone == wsml + wsml
@test wone == wsml + whlf
#don't forget to write a test case where we add a dominant 'strange subnormal'
#to a 'normal' float of lower magnitude.
wqrt = Unum{4,6}(z16, UInt16(2), z16, z64, UInt64(2))
@test Unums.__sum_exact(wsml, wqrt, decode_exp(wsml), decode_exp(wqrt)) == Unum{4,6}(o16, z16, z16, 0xC000_0000_0000_0000, z64)
res = Unums.__sum_exact(wsml, wqrt, decode_exp(wsml), decode_exp(wqrt))
#two-cell arithmetic, with one hell of a carry.
tbig = Unum{4,7}(UInt16(127), o16, z16, [f64, f64], UInt64(0b10))
tsma = Unum{4,7}(UInt16(127), o16, z16, [o64, z64], UInt64(0b10))
ttot = Unum{4,7}(z16        , o16, z16, [z64, z64], UInt64(0b11))
@test Unums.__sum_exact(tbig, tsma, decode_exp(tbig), decode_exp(tsma)) == ttot

##############################################
## tests discovered by continuous testing.

#25 august 2015:  Both of these unums seem to add up to "almostinf" despite
#being nowhere near the maximum size limit.
ctt1 = Unum{4,6}(UInt16(0b110011), UInt16(0b0110), z16, UInt64(0b01101001000011110001110011101100100101000000111000101100110_00000000000), UInt64(0b1100101))
ctt2 = Unum{4,6}(UInt16(0b110010), UInt16(0b0100), z16, UInt64(0b1011101011010111000000101000101011010000100111100010_000000000000), UInt64(0b11111))
@test !is_mmr(Unums.__sum_exact(ctt1, ctt1, decode_exp(ctt1), decode_exp(ctt1)))
@test !is_mmr(Unums.__sum_exact(ctt2, ctt2, decode_exp(ctt2), decode_exp(ctt2)))
#result:  This was due to poorly constructed test for the maximum exponent value

#9 september 2015:  Having problems with some ubound addition. (throws error)
ctub1 = Unum{4,6}(0x003f,0x0009,0x0003,0xb282a906ed2d8f0c,0x0000000000000376)
ctub2 = Unum{4,6}(0x003f,0x0009,0x0003,0x3282a906ed2d8f01,0x0000000000000376)
ctu1 = ubound(ctub1, ctub2)
ctu2 = Unum{4,6}(0x0032,0x0008,0x0001,0x6beb9d225f1e6000,0x00000000000001cc)
@test ctu1 + ctu2 == Ubound{4,6}(Unum{4,6}(0x003f,0x0009,0x0003,0xb282a906ed2d8f0c,0x0000000000000376),Unum{4,6}(0x003f,0x0009,0x0003,0x3282a906ed2d8f00,0x0000000000000376))
#resolved when an coding error was discovered:  UNUM_UBIT_MASK instead of UNUM_SIGN_MASK
#10 september 2015: (throws error)
ctub3 = Unum{4,6}(0x003f,0x0004,0x0003,0xde044b871cc5f67f,0x000000000000001d)
ctub4 = Unum{4,6}(0x003f,0x0004,0x0003,0xde044b871cc5f67d,0x000000000000001d)
ctu3 = Ubound{4,6}(ctub3,ctub4)
ctu4 = Unum{4,6}(0x0032,0x0008,0x0000,0x1a757044fa76a000,0x00000000000001b8)
@test ctu3 + ctu4 == Unum{4,6}(0x003f,0x0008,0x0001,0x1a757044fa769fff,0x00000000000001b8)
#resolved by adding a test to see if the two added values were very far apart.
#at the ubound level in addition to at the unum level. caused a revision in the
#previous test as well.
#11 september 2015: (throws error)
ctub5 = Unum{4,6}(0x003f,0x0007,0x0001,0x3db8d7e07e3733ee,0x00000000000000f1)
ctub6 = Unum{4,6}(0x003f,0x0007,0x0001,0xbdb8d7e07e3733f3,0x00000000000000f1)
ctu5 = Ubound(ctub5, ctub6)
ctu6 = Unum{4,6}(0x0032,0x0007,0x0002,0x4410e89562546000,0x00000000000000f2)
@test ctu5 + ctu6 == Ubound{4,6}(Unum{4,6}(0x003f,0x0007,0x0003,0x4a68f94a46718c11,0x00000000000000f1),Unum{4,6}(0x003f,0x0007,0x0003,0x94d1f2948ce31818,0x00000000000000f0))
#problem occurs due to an incorrect handling of trailing bits after shift in
#__diff_exact.
=#

#corner cases on unusual values.
#zero should return an identical value
#adding to +inf should return inf.
#add to max-ulp should return max-ulp
#inf + -inf should be NaN
#subtracting from supermax should yield a different ulp
