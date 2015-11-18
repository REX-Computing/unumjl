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
@test_throws ArgumentError Unum{0,0}(o16, z16, z16, z64, z64)
#test that esize error gets thrown
@test_throws ArgumentError Unum{0,0}(z16, o16, z16, z64, z64)
#test that exponent error gets thrown
@test_throws ArgumentError Unum{0,0}(z16, z16, z16, z64, UInt64(2))
#test that the fraction error gets thrown
@test_throws ArgumentError Unum{0,0}(z16, z16, z16, [z64, z64], z64)

#make sure that the constructor doesn't trim fractions that aren't too long.
warlpiri_one = Unum{0,0}(z16, z16, z16, t64, z64)
@test warlpiri_one.fraction == t64
@test warlpiri_one.fsize == z16
@test warlpiri_one.flags == z16

#test that the constructor correctly trims fractions that are too long.
warlpiri_some = Unum{0,0}(z16, z16, z16, f64, z64)
@test warlpiri_some.fraction == t64
@test warlpiri_some.fsize == z16
@test warlpiri_some.flags & Unums.UNUM_UBIT_MASK == Unums.UNUM_UBIT_MASK

#test the same thing in a really big number.
bigunum_trim1 = Unum{4,7}(UInt16(63), z16, z16, [z64, t64], z64)
@test bigunum_trim1.fraction.a == [z64, z64]
@test bigunum_trim1.fsize == 63
@test bigunum_trim1.flags & Unums.UNUM_UBIT_MASK == Unums.UNUM_UBIT_MASK

#test the unum_easy constructor
easy_warlpiri_two = unum(Unum{0,0}, z16, z64, 1)
@test easy_warlpiri_two.exponent == o64
@test easy_warlpiri_two.fraction == z64
@test easy_warlpiri_two.fsize == z16
@test easy_warlpiri_two.flags == z16

if Unums.__DEV_MODE
  #unset the development environment
  Unums.__unset_dev_check()
  @test !(Unums.__dev_check_state())
  #unsafe unums can be created using the unsafe constructor.
  unsafe_fsize = Unums.UnumSmall{0,0}(o16, z16, z16, z64, z64)
  @test unsafe_fsize.fsize == o16
  unsafe_esize = Unums.UnumSmall{0,0}(z16, o16, z16, z64, z64)
  @test unsafe_esize.esize == o16
  unsafe_exponent = Unums.UnumSmall{0,0}(z16, o16, z16, z64, UInt64(2))
  @test unsafe_exponent.exponent == UInt64(2)

  #then show that these trigger TypeErrors when passed through the safe constructor
  @test_throws ArgumentError Unum{0,0}(unsafe_fsize)
  @test_throws ArgumentError Unum{0,0}(unsafe_esize)
  @test_throws ArgumentError Unum{0,0}(unsafe_exponent)
  Unums.__set_dev_check()
end
