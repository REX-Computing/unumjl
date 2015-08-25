#unum-test-addition.jl

#testing addition

import Unums.z64
import Unums.o64
import Unums.t64
import Unums.f64
import Unums.z16

################################################################################
## TESTING HELPER functions

#__carried_add
#single cell, double zero.
@test (0, z64) == Unums.__carried_add(z64, z64, z64)
@test (1, z64) == Unums.__carried_add(o64, z64, z64) #with a passthru carry
#single cell, add to carry.
@test (1, z64) == Unums.__carried_add(z64, f64, o64)
@test (2, z64) == Unums.__carried_add(o64, f64, o64) #with a passthru carry
#single cell, double ff..ff
@test (1, ~o64) == Unums.__carried_add(z64, f64, f64)
@test (2, ~o64) == Unums.__carried_add(o64, f64, f64) #with a passthru carry
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
@test Unums.__shift_after_add(uint64(0), t64) == (0x8000_0000_0000_0000, 0, false)
@test Unums.__shift_after_add(uint64(1), t64) == (0x8000_0000_0000_0000, 0, false)
@test Unums.__shift_after_add(uint64(2), t64) == (0x4000_0000_0000_0000, 1, false)
@test Unums.__shift_after_add(uint64(3), t64) == (0xC000_0000_0000_0000, 1, false)
@test Unums.__shift_after_add(uint64(0), o64) == (0x0000_0000_0000_0001, 0, false)
@test Unums.__shift_after_add(uint64(1), o64) == (0x0000_0000_0000_0001, 0, false)
@test Unums.__shift_after_add(uint64(2), o64) == (0x0000_0000_0000_0000, 1, true)
@test Unums.__shift_after_add(uint64(3), o64) == (0x8000_0000_0000_0000, 1, true)
@test Unums.__shift_after_add(uint64(0), [z64,t64]) == ([z64, 0x8000_0000_0000_0000], 0, false)
@test Unums.__shift_after_add(uint64(1), [z64,t64]) == ([z64, 0x8000_0000_0000_0000], 0, false)
@test Unums.__shift_after_add(uint64(2), [z64,t64]) == ([z64, 0x4000_0000_0000_0000], 1, false)
@test Unums.__shift_after_add(uint64(3), [z64,t64]) == ([z64, 0xC000_0000_0000_0000], 1, false)
@test Unums.__shift_after_add(uint64(0), [o64,z64]) == ([o64, z64], 0, false)
@test Unums.__shift_after_add(uint64(1), [o64,z64]) == ([o64, z64], 0, false)
@test Unums.__shift_after_add(uint64(2), [o64,z64]) == ([z64, z64], 1, true)
@test Unums.__shift_after_add(uint64(3), [o64,z64]) == ([z64, t64], 1, true)

#test __sum_exact, which adds two exact sums, with magnitude(a) > magnitude(b)
wone = Unum{4,6}(z16,z16,z16,z64,o64)
wtwo = Unum{4,6}(z16,uint16(1),z16,z64,uint64(3))
wthr = Unum{4,6}(z16,uint16(1),z16,t64,uint64(3))
@test Unums.__sum_exact(wone, wone, 0, 0) == wtwo   #one plus one is two
@test Unums.__sum_exact(wtwo, wone, 1, 0) == wthr   #one plus two is three

wbig =  Unum{4,6}(z16,    0x0007, z16,                  z64, uint64(0xd0))
wbigu = Unum{4,6}(0x003f, 0x0007, Unums.UNUM_UBIT_MASK, z64, uint64(0xd0))
wmed =  Unum{4,6}(z16,    0x0007, z16,                  z64, uint64(0xc0))
wmd2 =  Unum{4,6}(z16,    0x0007, z16,                  z64, uint64(0xbf))
whlf =  Unum{4,6}(z16,    0x0001, z16,                  z64, o64)
@test Unums.__sum_exact(wbig, wone, 80, 0) == wbigu
@test Unums.__sum_exact(wmed, wone, 64, 0)  == Unum{4,6}(0x003f, 0x0007, z16, o64,                   uint64(0xc0))
@test Unums.__sum_exact(wmd2, wone, 63, 0)  == Unum{4,6}(0x003e, 0x0007, z16, uint64(2),             uint64(0xbf))
@test Unums.__sum_exact(wmed, wmd2, 64, 63) == Unum{4,6}(z16,    0x0007, z16, 0x8000_0000_0000_0000, uint64(0xc0))
@test Unums.__sum_exact(wmed, whlf, 64, -1) == Unum{4,6}(0x003f, 0x0007, Unums.UNUM_UBIT_MASK, z64,   uint64(0xc0))
#subnormal mathematics
wsml = Unum{4,6}(z16,    z16, z16, 0x8000_0000_0000_0000, z64)
wtny = Unum{4,6}(0x000F, z16, z16, 0x0001_0000_0000_0000, z64)
@test Unums.__sum_exact(wsml, wtny, -1, -1) == Unum{4,6}(0x000F, z16, z16, 0x8001_0000_0000_0000, z64)
println(calculate(wsml))
wsm2 = Unum{4,6}(z16,    0x000F, z16, 0x8000_0000_0000_0000, z64)
println(calculate(wsm2))
#corner cases on unusual values.
#zero should return an identical value
#adding to +inf should return inf.
#add to max-ulp should return max-ulp
#inf + -inf should be NaN
#subtracting from supermax should yield a different ulp
