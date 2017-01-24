#unum-test-addition.jl

#testing addition

################################################################################
## TESTING HELPER functions

#__carried_add
#double cell, double zero
test_array = Unums.ArrayNum{7}([z64, z64])
@test z64 == Unums.i64add!(z64, test_array, test_array)
@test test_array.a == [z64, z64]

@test o64 == Unums.i64add!(o64, test_array, test_array) #with a passthru carry
@test test_array.a == [z64, z64]

#double cell, less significant number adds in to carry
add_array = Unums.ArrayNum{7}([z64, f64])
test_array.a = [z64, o64]
@test z64 == Unums.i64add!(z64, test_array, add_array)
@test test_array.a == [o64, z64]

#double cell, double less significant number ff..ff
add_array.a = [z64, f64]
test_array.a = [z64, f64]
@test z64 == Unums.i64add!(z64, test_array, add_array)
@test test_array.a == [o64, ~o64]

#double cell, double upper ff..ff
add_array.a = [f64, z64]
test_array.a = [f64, z64]
@test o64 == Unums.i64add!(z64, test_array, add_array)
@test test_array.a == [~o64, z64]

#with a passthru carry
test_array.a = [f64, z64]
@test 2 == Unums.i64add!(o64, test_array, add_array)
@test test_array.a == [~o64, z64]

#create f's from whole cloth and pass it through
add_array.a = [0x9999_9999_9999_9999, f64]
test_array.a = [0x6666_6666_6666_6666, o64]
#@test 1 == Unums.__carried_add!(z64, add_array, test_array)
Unums.i64add!(z64, test_array, add_array)
@test test_array.a == [z64, z64]

#just let's make sure this works with even bigger arrays
test_array = Unums.ArrayNum{8}([f64, f64, f64, f64])
add_array = Unums.ArrayNum{8}([f64, f64, f64, f64])
@test 1 == Unums.i64add!(z64, test_array, add_array)
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
#__shift_after_add(carry, value) - resolves the result of a carry operation, and reports shift amt, and falloff.
@test Unums.__shift_after_add(UInt64(2), t64, z16) == (0x4000_0000_0000_0000, 1, z16)
@test Unums.__shift_after_add(UInt64(3), t64, z16) == (0xC000_0000_0000_0000, 1, z16)
@test Unums.__shift_after_add(UInt64(2), o64, z16) == (0x0000_0000_0000_0000, 1, Unums.UNUM_UBIT_MASK)
@test Unums.__shift_after_add(UInt64(3), o64, z16) == (0x8000_0000_0000_0000, 1, Unums.UNUM_UBIT_MASK)
@test Unums.__shift_after_add(UInt64(2), [z64,t64], z16) == ([z64, 0x4000_0000_0000_0000], 1, z16)
@test Unums.__shift_after_add(UInt64(3), [z64,t64], z16) == ([z64, 0xC000_0000_0000_0000], 1, z16)
@test Unums.__shift_after_add(UInt64(2), [o64,z64], z16) == ([z64, z64], 1, Unums.UNUM_UBIT_MASK)
@test Unums.__shift_after_add(UInt64(3), [o64,z64], z16) == ([z64, t64], 1, Unums.UNUM_UBIT_MASK)
=#

#test __sum_exact, which adds two exact sums, with magnitude(a) > magnitude(b)
wtwo  = Unum{4,6}(o64      ,z64,z16,z16      ,z16)
wfour = Unum{4,6}(UInt64(3),z64,z16,UInt16(1),z16)
wsix  = Unum{4,6}(UInt64(3),t64,z16,UInt16(1),z16)
@test Unums.sum_exact(wtwo, wtwo, 1, 1) == wfour   #one plus one is two
@test Unums.sum_exact(wfour, wtwo, 2, 1) == wsix    #one plus two is three

wbig =  Unum{4,6}(UInt64(0xd0), z64, z16,                   0x0007, z16)
wbigu = Unum{4,6}(UInt64(0xd0), z64, Unums.UNUM_UBIT_MASK,  0x0007, 0x003f)
wmed =  Unum{4,6}(UInt64(0xc0), z64, z16,                   0x0007, z16)
wmd2 =  Unum{4,6}(UInt64(0xbf), z64, z16,                   0x0007, z16)
whlf =  Unum{4,6}(UInt64(0x02), z64, z16,                   0x0002, 0x0001)
@test Unums.sum_exact(wbig, wtwo, 81, 1)  == wbigu
@test Unums.sum_exact(wmed, wtwo, 65, 1)  == Unum{4,6}(UInt64(0xc0), o64,                   z16,                  0x0007, 0x003f)
@test Unums.sum_exact(wmd2, wtwo, 64, 1)  == Unum{4,6}(UInt64(0xbf), UInt64(2),             z16,                  0x0007, 0x003e)
@test Unums.sum_exact(wmed, wmd2, 65, 64) == Unum{4,6}(UInt64(0xc0), 0x8000_0000_0000_0000, z16,                  0x0007, z16   )
@test Unums.sum_exact(wmed, whlf, 65, 0)  == Unum{4,6}(UInt64(0xc0), z64,                   Unums.UNUM_UBIT_MASK, 0x0007, 0x003f)

#subnormal mathematics
wsml = Unum{4,6}(z64, 0x8000_0000_0000_0000, z16, o16, z16   )
wtny = Unum{4,6}(z64, 0x0001_0000_0000_0000, z16, z16, 0x000F)
#println(Unums.__sum_exact(wsml, wtny, -1, -1))
@test Unums.sum_exact(wsml, wtny, 0, 0) == Unum{4,6}(z64, 0x8001_0000_0000_0000, z16, z16, 0x000F)
#note that wsml is also the same as whlf
@test wone == whlf + whlf
@test wone == wsml + wsml
@test wone == wsml + whlf


#don't forget to write a test case where we add a dominant 'strange subnormal'
#to a 'normal' float of lower magnitude.
wsml = Unum{4,6}(z64, 0x8000_0000_0000_0000, z16, o16, z16   )
wqrt = Unum{4,6}(o64, z64, z16, UInt16(2), z16)
@test wsml + wqrt == Unum{4,6}(z64, 0xc000_0000_0000_0000, z16, o16, o16)

#two-cell arithmetic, with one hell of a carry.
tbig = Unum{4,7}(UInt64(0b10), [f64, f64], z16, o16, UInt16(127))
tsma = Unum{4,7}(UInt64(0b10), [z64, o64], z16, o16, UInt16(127))
ttot = Unum{4,7}(UInt64(0b11), [t64, z64], z16, o16, z16        )
@test tbig + tsma == ttot

#sometimes adding an ulp and a non-ulp doesn't work.  Discovered by basic
#demonstration of the addition problem.

x = Unum{2,2}(32)
x += one(Unum{2,2})
x += one(Unum{2,2})
y = Unums.make_ulp!(Unum{2,2}(32))
y.fsize = 0x0002
@test x == y

x = Unum{2,2}(0x000000000000000C, 0x2000000000000000, 0x0001, 0x0003, 0x0003)
x += one(Unum{2,2})
b = Unum{2,2}(0x000000000000000C, 0x2000000000000000, 0x0001, 0x0003, 0x0002)
@test x == b

#adding two ulps sometimes doesn't work.  Discovered by basic demonstration of
#0.2 + 0.1 != 0.3
x = Unum{4,6}(2) / Unum{4,6}(10)
y = Unum{4,6}(1) / Unum{4,6}(10)
z = x + y

@test Unums.lub(z) > Unum{4,6}(0x0000000000000001, 0x3333333333333333, 0x0000, 0x0002, 0x003F)

x = Unum{4,6}(1) / Unum{4,6}(3)
z = x + x + x
@test Unums.lub(z) > one(Unum{4,6})

##############################################
## tests discovered by continuous testing.

#9 september 2015:  Having problems with some ubound addition. (throws error)
ctub1 = Unum{4,6}(0x0000000000000376,0xb282a906ed2d8f0c,0x0003,0x0009,0x003f)
ctub2 = Unum{4,6}(0x0000000000000376,0x3282a906ed2d8f01,0x0003,0x0009,0x003f)
ctu1 = Ubound(ctub1, ctub2)
ctu2 = Unum{4,6}(0x00000000000001cc,0x6beb9d225f1e6000,0x0001,0x0008,0x0032)
@test ctu1 + ctu2 == Ubound{4,6}(Unum{4,6}(0x0000000000000376,0xb282a906ed2d8f0c,0x0003,0x0009,0x003f),Unum{4,6}(0x0000000000000376,0x3282a906ed2d8f00,0x0003,0x0009,0x003f))

#resolved when an coding error was discovered:  UNUM_UBIT_MASK instead of UNUM_SIGN_MASK
#10 september 2015: (throws error)
ctub3 = Unum{4,6}(0x000000000000001d,0xde044b871cc5f67f,0x0003,0x0004,0x003f)
ctub4 = Unum{4,6}(0x000000000000001d,0xde044b871cc5f67d,0x0003,0x0004,0x003f)
ctu3 = Ubound{4,6}(ctub3,ctub4)
ctu4 = Unum{4,6}(0x00000000000001b8,0x1a757044fa76a000,0x0000,0x0008,0x0032)
@test ctu3 + ctu4 == Unum{4,6}(0x00000000000001b8,0x1a757044fa769fff,0x0001,0x0008,0x003f)
#resolved by adding a test to see if the two added values were very far apart.
#at the ubound level in addition to at the unum level. caused a revision in the
#previous test as well.

#11 september 2015: (throws error)
ctub5 = Unum{4,6}(0x00000000000000f1,0x3db8d7e07e3733ee,0x0001,0x0007,0x003f)
ctub6 = Unum{4,6}(0x00000000000000f1,0xbdb8d7e07e3733f3,0x0001,0x0007,0x003f)
ctu5 = Ubound(ctub5, ctub6)
ctu6 = Unum{4,6}(0x00000000000000f2,0x4410e89562546000,0x0002,0x0007,0x0032)
@test ctu5 + ctu6 == Ubound{4,6}(Unum{4,6}(0x00000000000000f1,0x4a68f94a46718c11,0x0003,0x0007,0x003f), Unum{4,6}(0x00000000000000f0,0x94d1f2948ce31818,0x0003,0x0007,0x003f))
#problem occurs due to an incorrect handling of trailing bits after shift in
#__diff_exact.
