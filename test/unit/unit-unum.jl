#unit-unum.jl

#test that the Unum pseudo-constructor bifurcates the actual construction to
#"UnumSmall" and "UnumLarge" types
@test isa(Unum{4,6}(z16, z16, z16, z64, z64), Unums.UnumSmall{4,6})
@test isa(Unum{4,7}(z16, z16, z16, [z64, z64], z64), Unums.UnumLarge{4,7})
#test that passing strange data types fails.
@test_throws MethodError Unum{4,6}(z16, z16, z16, [z64, z64], z16)
@test_throws MethodError Unum{4,7}(z16, z16, z16, z64, z16)
@test_throws MethodError Unum{4,8}(z16, z16, z16, [z64, z64], z16)

#cascading tests on the general unum checking procedure.
@test_throws ArgumentError Unums.__general_unum_check(7, 0, z16, z16, z16, z64, z64)          #ESS too big.
@test_throws ArgumentError Unums.__general_unum_check(6, 12, z16, z16, z16, z64, z64)         #FSS too big.
@test_throws ArgumentError Unums.__general_unum_check(0, 0, o16, z16, z16, z64, z64)          #fsize too big
@test_throws ArgumentError Unums.__general_unum_check(0, 11, UInt16(256), z16, z16, z64, z64) #fsize too big
@test_throws ArgumentError Unums.__general_unum_check(0, 0, z16, o16, z16, z64, z64)          #esize too big
@test_throws ArgumentError Unums.__general_unum_check(6, 0, z16, UInt16(64), z16, z64, z64)        #esize too big
@test_throws ArgumentError Unums.__general_unum_check(0, 0, z16, z16, z16, z64, UInt64(2))    #exponent too big
@test_throws ArgumentError Unums.__general_unum_check(0, 0, z16, z16, z16, Unums.ArrayNum{7}([z64, z64]), z64) #bad fraction
@test_throws ArgumentError Unums.__general_unum_check(7, 0, z16, z16, z16, z64, z64)          #bad fraction.
@test_throws ArgumentError Unums.__general_unum_check(8, 0, z16, z16, z16, Unums.ArrayNum{8}([z64, z64, z64, z64]), z64)

#actual tests on constructors using the safe unum constructor.
#test that fsize error gets thrown.
@test_throws ArgumentError unum(Unum{0,0}, o16, z16, z16, z64, z64)
#test that esize error gets thrown
@test_throws ArgumentError unum(Unum{0,0}, z16, o16, z16, z64, z64)
#test that exponent error gets thrown
@test_throws ArgumentError unum(Unum{0,0}, z16, z16, z16, z64, UInt64(2))
#test that the fraction error gets thrown
@test_throws ArgumentError unum(Unum{0,0}, z16, z16, z16, [z64, z64], z64)

#test that the constructor correctly trims fractions that are too long.
walpiri_half = unum(Unum{0,0}, z16, z16, z16, f64, z64)
@test walpiri_half.fraction == t64
@test walpiri_half.fsize == 0
@test walpiri_half.flags & Unums.UNUM_UBIT_MASK == Unums.UNUM_UBIT_MASK

#test the same thing in a really big number.
bigunum_trim1 = unum(Unum{4,7}, UInt16(63), z16, z16, [z64, t64], z64)
@test bigunum_trim1.fraction.a == [z64, z64]
@test bigunum_trim1.fsize == 63
@test bigunum_trim1.flags & Unums.UNUM_UBIT_MASK == Unums.UNUM_UBIT_MASK

#=
#test the unum_easy constructor
easy_walpiri_two = unum_easy(Unum{0,0}, z16, z64, o64)
@test easy_walpiri_two.fraction == z64
@test easy_walpiri_two.fsize == 0
@test easy_walpiri_two.flags == z16
#test that unum_easy will also take a sloppy VarInt.
easy_walpiri_two_oops = unum_easy(Unum{0,0}, z16, [f64, z64], o64)
@test easy_walpiri_two_oops.fraction == z64
@test easy_walpiri_two_oops.fsize == 0
@test easy_walpiri_two_oops.flags == z16

#unset the development environment
#test that we can create unsafe unums using the unsafe constructor.
unsafe_fsize = Unum{0,0}(o16, z16, z16, z64, z64)
unsafe_fsize_2 = unum_unsafe(unsafe_fsize)
unsafe_esize = Unum{0,0}(z16, o16, z16, z64, z64)
unsafe_esize_2 = unum_unsafe(unsafe_esize)
unsafe_exponent = Unum{0,0}(z16, o16, z16, z64, UInt64(2))
unsafe_exponent_2 = unum_unsafe(unsafe_exponent)
unsafe_fraction = Unum{0,0}(z16, o16, z16, [z64, z64], z64)
unsafe_fraction_2 = unum_unsafe(unsafe_fraction)
#then show that these trigger TypeErrors when passed through the safe constructor
@test_throws ArgumentError unum(unsafe_fsize)
@test_throws ArgumentError unum(unsafe_fsize_2)
@test_throws ArgumentError unum(unsafe_esize)
@test_throws ArgumentError unum(unsafe_esize_2)
@test_throws ArgumentError unum(unsafe_exponent)
@test_throws ArgumentError unum(unsafe_exponent_2)
@test_throws ArgumentError unum(unsafe_fraction)
@test_throws ArgumentError unum(unsafe_fraction_2)
=#
