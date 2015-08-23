#unum-test-addition.jl

#testing addition

import Unums.z64
import Unums.o64
import Unums.t64
import Unums.f64

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
@test Unums.__shift_after_add(uint64(1), t64) == (0xC000_0000_0000_0000, 1, false)
@test Unums.__shift_after_add(uint64(2), t64) == (0xA000_0000_0000_0000, 2, false)
@test Unums.__shift_after_add(uint64(3), t64) == (0xE000_0000_0000_0000, 2, false)
@test Unums.__shift_after_add(uint64(0), o64) == (0x0000_0000_0000_0001, 0, false)
@test Unums.__shift_after_add(uint64(1), o64) == (0x8000_0000_0000_0000, 1, true)
@test Unums.__shift_after_add(uint64(2), o64) == (0x8000_0000_0000_0000, 2, true)
@test Unums.__shift_after_add(uint64(3), o64) == (0xC000_0000_0000_0000, 2, true)
@test Unums.__shift_after_add(uint64(0), [z64,t64]) == ([z64, 0x8000_0000_0000_0000], 0, false)
@test Unums.__shift_after_add(uint64(1), [z64,t64]) == ([z64, 0xC000_0000_0000_0000], 1, false)
@test Unums.__shift_after_add(uint64(2), [z64,t64]) == ([z64, 0xA000_0000_0000_0000], 2, false)
@test Unums.__shift_after_add(uint64(3), [z64,t64]) == ([z64, 0xE000_0000_0000_0000], 2, false)
@test Unums.__shift_after_add(uint64(0), [o64,z64]) == ([0x0000_0000_0000_0001, z64], 0, false)
@test Unums.__shift_after_add(uint64(1), [o64,z64]) == ([z64,                   t64], 1, true)
@test Unums.__shift_after_add(uint64(2), [o64,z64]) == ([z64,                   t64], 2, true)
@test Unums.__shift_after_add(uint64(3), [o64,z64]) == ([z64, 0xC000_0000_0000_0000], 2, true)


#subnormal mathematics

#corner cases on unusual values.
#zero should return an identical value
#adding to +inf should return inf.
#add to max-ulp should return max-ulp
#inf + -inf should be NaN
#subtracting from supermax should yield a different ulp
