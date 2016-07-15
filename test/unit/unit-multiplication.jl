#unit-multiplication.jl

#testing chunk multiplication
a = 0xFFFFFFFFFFFFFFFF
b = 0xFFFFFFFFFFFFFFFF

#unit test mult_exact.

################################################################################
# found errors
x = Unum{4,5}(0x0000000000000003, 0x5555555600000000, 0x0000, 0x0001, 0x001F)
y = Unum{4,5}(3)
#should be approximately 16, but usually gets 8.
@test x * y > Unum{4,5}(16)

x = Unum{4,7}(o64, Unums.ArrayNum{7}([0x3fff_ffff_ffff_fffe, 0xc000_0000_0000_0000]), z16, z16, 0x004F)
y = Unums.ArrayNum{7}([o64, z64])
Unums.frac_mul!(x, y, Val{2}, Val{true})
@test x.fraction == Unums.ArrayNum{7}([0x3fff_ffff_ffff_ffff, 0xffff_ffff_ffff_fffe])

#bizzare ubit setting.
p = Unum{4,7}(0x0000000000000001, UInt64[0x8000000000000000,0x0000000000000000], 0x0000, 0x0001, 0x0001)
q = Unum{4,7}(0x0000000000000007, UInt64[0x4000000000000000,0x0000000000000000], 0x0000, 0x0002, 0x0002)
@test Unums.is_exact(p * q)

#wierd multiplication results.

x = Ubound(neg_one(Unum{3,4}), pos_one(Unum{3,4}))
@test x * x == x
@test is_zero((x ^ 2).lower)
@test x ^ 3 == x
@test is_zero((x ^ 4).lower)

#making sure our heuristic multiplication works.

#double ulp.
x = Unum{3,4}(2)
x.fsize = 2
Unums.make_ulp!(x)

y = Unum{3,4}(2)
y.fsize = 3
Unums.make_ulp!(y)

#some strange exact multiplications
#identified during bounds testing
x = Unums.inner_exact!(mmr(Unum{3,5}))
y = Unum{3,5}(0x0000000000000001, 0xFFFFFFFF00000000, 0x0001, 0x0001, 0x001F)
@test Unums.mul_exact(x, y, z16) == mmr(Unum{3,5})

#=
uft1 = unum_easy(Unum{4,6}, zero(UInt16), frac1, 1)
uft2 = unum_easy(Unum{4,6}, zero(UInt16), frac2, 1)
xft1 = convert(Float64, uft1)
xft2 = convert(Float64, uft2)
ifm3 = (reinterpret(UInt64, xft1 * xft2) << 12) & f64_frac_mask
ufm3 = (Unums.__mult_exact(uft1, uft2)).fraction & f64_frac_mask
@test ifm3 == ufm3
=#
#result:  A coding error caused this carry function in the multiplication
#operation to fail to trigger in the last 32-bit segment.  This has been fixed.
