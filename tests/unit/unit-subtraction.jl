#unit-subtraction.jl

#testing subtraction

import Unums.z64
import Unums.o64
import Unums.t64
import Unums.f64
import Unums.z16
import Unums.o16

################################################################################
## TESTING HELPER FUNCTIONS

#__carried_diff - a subtraction that takes into account carries
@test Unums.__carried_diff(o64, 0xFFFF_0000_0000_0000, 0x000F_0000_0000_0000) == (1, 0xFFF0_0000_0000_0000)
@test Unums.__carried_diff(o64, 0x0000_0000_0000_0000, 0x0010_0000_0000_0000) == (0, 0xFFF0_0000_0000_0000)

#__diff_exact - an exact subtraction with the first entity having a higher exponent

wone = Unum{4,6}(z16,z16,z16,z64,o64)
wtwo = Unum{4,6}(z16,UInt16(1),z16,z64,UInt64(3))
wthr = Unum{4,6}(z16,UInt16(1),z16,t64,UInt64(3))

@test Unums.__diff_exact(wone, -wone, 0, 0) == zero(Unum{4,6})   #one plus one is two
@test Unums.__diff_exact(wtwo, -wone, 1, 0) == wone              #two minus one is one
@test Unums.__diff_exact(wthr, -wone, decode_exp(wthr), decode_exp(wone)) == wtwo

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
