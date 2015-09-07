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
wtwo = Unum{4,6}(z16,uint16(1),z16,z64,uint64(3))
wthr = Unum{4,6}(z16,uint16(1),z16,t64,uint64(3))

@test Unums.__diff_exact(wone, -wone, 0, 0) == zero(Unum{4,6})   #one plus one is two
@test Unums.__diff_exact(wtwo, -wone, 1, 0) == wone              #two minus one is one
@test Unums.__diff_exact(wthr, -wone, decode_exp(wthr), decode_exp(wone)) == wtwo
