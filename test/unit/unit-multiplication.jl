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
