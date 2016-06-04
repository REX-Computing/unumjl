#unit-operations.jl
#other useful operations on unums.

#test __resolve_subnormal.
#takes a subnormal number and makes it normal, or the smallest subnormal class
#as makes most sense for that number.

#example:  0 1 0 0 is unum(0.5) in all contexts, and this is the same as:
#          01 0 1 0 in most unums.

#first demonstrate that the two representations (the subnormal and the normal) are
#equivalent.
x = Unum{4,6}(z64, t64, z16, z16, z16)
Unums.resolve_degenerates!(x)
@test calculate(x) == calculate(Unum{4,6}(z64, t64, z16, z16, z16))
@test x.fsize == z16
@test x.esize == o16
@test x.flags == z16
@test x.fraction == z64
@test x.exponent == o64
#note we can't use the equality operator testnig because the equality operator
#will engage the __resolve_subnormal function itself.

#repeat the exercise in a VarInt unum.
x = Unum{4,8}(z64, [t64, z64, z64, z64], z16, z16, z16)
Unums.resolve_degenerates!(x)
#@test calculate(x) == calculate(u)  #NB "calculate" doesn't currently work on superint unums.
@test x.fsize == z16
@test x.esize == o16
@test x.flags == z16
@test x.fraction.a == [z64, z64, z64, z64]
@test x.exponent == o64


#repeat the exercise in a very small unum.
x = Unum{2,2}(z64, t64, z16, z16, z16)
Unums.resolve_degenerates!(x)
@test calculate(x) == calculate(Unum{2,2}(z64, t64, z16, z16, z16))
@test x.fsize == z16
@test x.esize == o16
@test x.flags == z16
@test x.fraction == z64
@test x.exponent == o64

#=
#second example:  Take a unum at the edge of smallness and show that we can
#resolve this into the apropriate even smaller subnormal number.
x = Unum{2,4}(UInt16(15), z16, z16, 0x0001_0000_0000_0000, z64)
Unums.__resolve_subnormal!(x)
@test calculate(x) == calculate(UInt16(15), z16, z16, 0x0001_0000_0000_0000, z64)
@test x.exponent == 0
=#
