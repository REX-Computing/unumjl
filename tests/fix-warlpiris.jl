#fix-warlpiri.jl
#shim used to fix warlpiris

include("../unum.jl")
using Unums

import Unums.UNUM_SIGN_MASK
import Unums.UNUM_UBIT_MASK

z16 = uint16(0)
z64 = uint64(0)
o64 = uint64(1)
t64 = uint64(0x8000_0000_0000_0000)

#1101

a = Unum{0,0}(z16, z16, UNUM_SIGN_MASK, o64, o64)
b = Unum{0,0}(z16, z16, UNUM_SIGN_MASK | UNUM_UBIT_MASK, z64, o64)
println(bits(b))
println("$(bits(b)) + $(bits(b)) = $(bits(b + b))")
