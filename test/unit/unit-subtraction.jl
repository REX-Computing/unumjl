#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#unit-subtraction.jl

#testing subtraction

#__diff_exact - an exact subtraction with the first entity having a higher exponent

wone = convert(Unum{4,6}, 1)
wtwo = convert(Unum{4,6}, 2)
wthr = convert(Unum{4,6}, 3)

eone = Unums.decode_exp(wone)
etwo = Unums.decode_exp(wtwo)
ethr = Unums.decode_exp(wthr)

@test Unums.diff_exact(wone, -wone, eone, eone) == zero(Unum{4,6})   #one plus one is two
@test Unums.diff_exact(wtwo, -wone, etwo, eone) == wone              #two minus one is one
@test Unums.diff_exact(wthr, -wone, ethr, eone) == wtwo

#test that the sign things seem to work.
x = Unum{3,3}(7.191347884985208e19)
y = Unum{3,3}(1.3733397310822187e27)
@test is_negative(x - y)

x = Unum{4,5}(-1.314174462714471e27)
y = Unum{4,5}(1.4517351819998816e20)
@test Unums.is_inward(y, x)
@test is_negative(x - y)

#long subtraction, discovered as an error in rump's formula.

x = Unum{4,7}(0x00000000000000F9, UInt64[0x7d31ee79ca44b643,0x91bb985960000000], 0x0000, 0x0007, 0x0063)
y = Unum{4,7}(0x00000000000000F9, UInt64[0x7d31ee79ca44b643,0x91bb985960000080], 0x0000, 0x0007, 0x0079)
@test y - x == Unum{4,7}(2)

#=
#11 September 2015 - identified through continuous testing.  The problem here is
#that the two normal floats share their exponent factor, and clears a huge swath
#of zeros in the fraction.
x1 = Unum{4,6}(0x0033, 0x0007, z16, 0x04dcb922d2c6d000, 0x000000015)
x2 = Unum{4,6}(0x0033, 0x0007, Unums.UNUM_SIGN_MASK, 0x04dcb8d6e79b5000, 0x000000015)
de = decode_exp(0x0007, 0x000000015)
@test Unums.__diff_exact(x1, x2, de, de) == Unum{4,6}(0x0016, 0x0008, z16, 0x2facae0000000000, UInt64(0x7b))
#fixed by implementing a subroutine that is triggered only when carry is zero for
#a no-offset subtraction.

#11 septemeber 2015 - identified through continuous testing.  The problem here is
#that two normal floats with an offset one off can also trigger a huge swath of
#zeros in the fraction.
#diagram:  (1)0 000000XXXXX
#            (1)111111XXXXX
#             0 000001XXXXX
x3 = Unum{4,6}(0x0032,0x0006,Unums.UNUM_SIGN_MASK,0x95b579166f2be000,0x0000000000000065)
x4 = Unum{4,6}(0x0033,0x0006,0x0000,0x120df3b26a793000,0x0000000000000066)
dx3 = decode_exp(x3)
dx4 = decode_exp(x4)
@test Unums.__diff_exact(x4, x3, dx4, dx3) == Unum{4,6}(0x002f,0x0006,0x0000,0x1cccdc9ccb8d0000,0x0000000000000064)
#fixed by implementing a subroutine that also identifies this situation.  to keep
#code DRY, created the __shift_many_zeros subroutine.

#11 september 2015 - identified through continuous testing, in parallel to the
#ubound problem as in the unit test for addition.
x5 = Unum{4,6}(0x0032,0x0007,Unums.UNUM_SIGN_MASK,0x4410e89562546000,UInt64(0xf2))
x6 = Unum{4,6}(0x003f,0x0007,z16,0x3db8d7e07e3733ef,UInt64(0xf1))
dx5 = decode_exp(x5)
dx6 = decode_exp(x6)
@test Unums.__diff_exact(x5,x6,dx5,dx6) == Unum{4,6}(0x003f, 0x0007, Unums.UNUM_UBIT_MASK | Unums.UNUM_SIGN_MASK, 0x4a68f94a46718c11, UInt64(0xf1))
#resolved due to an incorrect offset in a fillbit call.
=#
