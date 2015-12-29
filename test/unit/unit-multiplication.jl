#unit-multiplication.jl

#testing chunk multiplication
a = 0xFFFFFFFFFFFFFFFF
b = 0xFFFFFFFFFFFFFFFF

#unit test mult_exact.

#testing problems with carry operations in chunk_mult
#random value testing identified problematic fraction values.
f64_frac_mask = 0xFFFF_FFFF_FFFE_0000
frac1 = 0x7c26c92fea77e000
frac2 = 0x997d76a4e016d000

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
