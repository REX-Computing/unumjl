#unum-test-int64op.jl

#some useful variables
msb1    = UInt64(0x8000_0000_0000_0000)
lsb1    = UInt64(0x0000_0000_0000_0001)
msb8    = UInt64(0xFF00_0000_0000_0000)
msb6    = UInt64(0xFC00_0000_0000_0000)
lsb6    = UInt64(0x0000_0000_0000_003F)
allbits = UInt64(0xFFFF_FFFF_FFFF_FFFF)
nobits  = UInt64(0x0000_0000_0000_0000)

z16 = zero(UInt16)
o16 = one(UInt16)
z64 = zero(UInt64)
o64 = one(UInt64)
f64 = 0xFFFF_FFFF_FFFF_FFFF
t64 = 0x8000_0000_0000_0000

@test_throws ArgumentError Unums.__check_ArrayNum(0, [z64])
@test_throws ArgumentError Unums.__check_ArrayNum(6, [z64])
@test_throws ArgumentError Unums.__check_ArrayNum(7, [z64])
@test_throws ArgumentError Unums.__check_ArrayNum(8, [z64, z64])

#test developer safety being disabled on ArrayNum type
@unum_dev_switch begin

  @unum_dev_on

  #ArrayNums of size < 7 are disallowed.
  @test_throws ArgumentError Unums.ArrayNum{0}([z64])
  @test_throws ArgumentError Unums.ArrayNum{1}([z64])
  @test_throws ArgumentError Unums.ArrayNum{2}([z64])
  @test_throws ArgumentError Unums.ArrayNum{3}([z64])
  @test_throws ArgumentError Unums.ArrayNum{4}([z64])
  @test_throws ArgumentError Unums.ArrayNum{5}([z64])
  @test_throws ArgumentError Unums.ArrayNum{6}([z64])

  #ArrayNums must have the minimum number of elements.
  @test_throws ArgumentError Unums.ArrayNum{7}([z64])
  @test_throws ArgumentError Unums.ArrayNum{8}([z64, z64])

  @unum_dev_off

  #these are OK now.
  Unums.ArrayNum{0}([z64])
  Unums.ArrayNum{6}([z64])
  Unums.ArrayNum{7}([z64])

  dev_check && Unums.__set_dev_check()
end

#but it's ok if we pass an ArrayNum an array with more elements than necessary.
bigger_array = Unums.ArrayNum{7}([z64, z64, z64, z64])
@test bigger_array.a == [z64, z64, z64, z64]
################################################################################
## SUPERINT CONSTANT GENERATION

@test zero(Unums.ArrayNum{7}).a == [nobits, nobits]
@test one(Unums.ArrayNum{7}).a  == [nobits, lsb1]
@test top(Unums.ArrayNum{7}).a  == [msb1, nobits]
@test zero(Unums.ArrayNum{8}).a == [nobits, nobits, nobits, nobits]
@test one(Unums.ArrayNum{8}).a  == [nobits, nobits, nobits, lsb1]
@test top(Unums.ArrayNum{8}).a  == [msb1, nobits, nobits, nobits]


#bit_from_top
#=
@test Unums.__bit_from_top(0,1)    == msb1
@test Unums.__bit_from_top(1,1)    == 0x4000_0000_0000_0000
@test Unums.__bit_from_top(63,1)   == lsb1
@test Unums.__bit_from_top(0, 2)   == [msb1, nobits]
@test Unums.__bit_from_top(63, 2)  == [lsb1, nobits]
@test Unums.__bit_from_top(64, 2)  == [nobits, msb1]
@test Unums.__bit_from_top(127, 2) == [nobits, lsb1]
=#

################################################################################
## BIT PATTERN DETECTION

#is_all_zero
@test  Unums.is_all_zero(nobits)
@test  Unums.is_all_zero(Unums.ArrayNum{7}([nobits, nobits]))
@test  Unums.is_all_zero(Unums.ArrayNum{8}([nobits, nobits, nobits, nobits]))
@test !Unums.is_all_zero(lsb1)
@test !Unums.is_all_zero(Unums.ArrayNum{7}([lsb1, nobits]))
@test !Unums.is_all_zero(Unums.ArrayNum{7}([nobits, msb1]))
@test !Unums.is_all_zero(Unums.ArrayNum{7}([lsb1, msb1]))
@test !Unums.is_all_zero(Unums.ArrayNum{8}([nobits, nobits, lsb1, nobits]))

#is_not_zero
@test !Unums.is_not_zero(nobits)
@test !Unums.is_not_zero(Unums.ArrayNum{7}([nobits, nobits]))
@test !Unums.is_not_zero(Unums.ArrayNum{8}([nobits, nobits, nobits, nobits]))
@test  Unums.is_not_zero(lsb1)
@test  Unums.is_not_zero(Unums.ArrayNum{7}([lsb1, nobits]))
@test  Unums.is_not_zero(Unums.ArrayNum{7}([nobits, msb1]))
@test  Unums.is_not_zero(Unums.ArrayNum{7}([lsb1, msb1]))
@test  Unums.is_not_zero(Unums.ArrayNum{8}([nobits, nobits, lsb1, nobits]))

#is_top
@test Unums.is_top(msb1)
@test Unums.is_top(Unums.ArrayNum{7}([msb1, nobits]))
@test Unums.is_top(Unums.ArrayNum{8}([msb1, nobits, nobits, nobits]))
@test !Unums.is_top(nobits)
@test !Unums.is_top(msb1 & lsb1)
@test !Unums.is_top(Unums.ArrayNum{7}([msb1, lsb1]))
@test !Unums.is_top(Unums.ArrayNum{7}([nobits, msb1]))
@test !Unums.is_top(Unums.ArrayNum{8}([msb1, nobits, nobits, msb1]))

#is_not_top
@test !Unums.is_not_top(msb1)
@test !Unums.is_not_top(Unums.ArrayNum{7}([msb1, nobits]))
@test !Unums.is_not_top(Unums.ArrayNum{8}([msb1, nobits, nobits, nobits]))
@test Unums.is_not_top(nobits)
@test Unums.is_not_top(msb1 & lsb1)
@test Unums.is_not_top(Unums.ArrayNum{7}([msb1, lsb1]))
@test Unums.is_not_top(Unums.ArrayNum{7}([nobits, msb1]))
@test Unums.is_not_top(Unums.ArrayNum{8}([msb1, nobits, nobits, msb1]))


################################################################################
## CLZ AND CTZ

#leading_zeros
@test leading_zeros(allbits) == 0
@test leading_zeros(nobits) == 64
@test leading_zeros(msb8) == 0
@test leading_zeros(lsb6) == 58
@test leading_zeros(UInt64(0b0001111000)) == 57
@test leading_zeros(Unums.ArrayNum{7}([nobits, 0x00FF_0000_0000_0000])) == 72
@test leading_zeros(Unums.ArrayNum{7}([0x0000_0000_0000_F00F, nobits])) == 48
@test leading_zeros(Unums.ArrayNum{7}([nobits, nobits])) == 128
#test trailing_zeros
@test trailing_zeros(allbits) == 0
@test trailing_zeros(nobits) == 64
@test trailing_zeros(msb8) == 56
@test trailing_zeros(lsb6) == 0
@test trailing_zeros(UInt64(0b0001111000)) == 3
@test trailing_zeros(Unums.ArrayNum{7}([nobits, 0x00FF_0000_0000_0000])) == 48
@test trailing_zeros(Unums.ArrayNum{7}([0x0000_0000_0000_F00F, nobits])) == 64
@test trailing_zeros(Unums.ArrayNum{7}([nobits, nobits])) == 128

################################################################################
## MASKS

#test mask generation
@test Unums.mask_top(UInt16(0)) == msb1
@test Unums.mask_bot(UInt16(62)) == lsb1
@test Unums.mask_top(UInt16(7)) == msb8
@test Unums.mask_bot(UInt16(57)) == lsb6
@test Unums.mask_top(UInt16(63)) == allbits

#test two cells.
twocellint = zero(Unums.ArrayNum{7})

Unums.mask_top!(twocellint, UInt16(0))
@test twocellint.a == [msb1, nobits]
Unums.mask_bot!(twocellint, UInt16(126))
@test twocellint.a == [nobits, lsb1]
Unums.mask_top!(twocellint, UInt16(63))
@test twocellint.a == [allbits, nobits]
Unums.mask_bot!(twocellint, UInt16(63))
@test twocellint.a == [nobits, allbits]
Unums.mask_top!(twocellint, UInt16(64))
@test twocellint.a == [allbits, msb1]
Unums.mask_bot!(twocellint, UInt16(62))
@test twocellint.a == [lsb1, allbits]
Unums.mask_bot!(twocellint, UInt16(127))
@test twocellint.a == [nobits, nobits]
Unums.mask_top!(twocellint, UInt16(127))
@test twocellint.a == [allbits, allbits]

#test four cells
fourcellint = zero(Unums.ArrayNum{8})
Unums.mask_top!(fourcellint, UInt16(64))
@test fourcellint.a == [allbits, msb1, nobits, nobits]
Unums.mask_bot!(fourcellint, UInt16(190))
@test fourcellint.a == [nobits, nobits, lsb1, allbits]
Unums.mask_top!(fourcellint, UInt16(255))
@test fourcellint.a == [allbits, allbits, allbits, allbits]
Unums.mask_bot!(fourcellint, UInt16(255))
@test fourcellint.a == [nobits, nobits, nobits, nobits]

#mask filling.
test_texture = [0x1234_5678_9ABC_DEF1, 0x2345_6789_ABCD_EF12]
test_mask    = [0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_0000_0000_0000]
test_masktex = [0x1234_5678_9ABC_DEF1, 0x2345_0000_0000_0000]
#test the and-ing process
txt = Unums.ArrayNum{7}(copy(test_texture))
msk = Unums.ArrayNum{7}(copy(test_mask))
Unums.fill_mask!(msk, txt)
@test msk.a == test_masktex

## bottom bits
@test Unums.bottom_bit(UInt16(0))  == 0x8000_0000_0000_0000
@test Unums.bottom_bit(UInt16(1))  == 0x4000_0000_0000_0000
@test Unums.bottom_bit(UInt16(2))  == 0x2000_0000_0000_0000
@test Unums.bottom_bit(UInt16(3))  == 0x1000_0000_0000_0000
@test Unums.bottom_bit(UInt16(13)) == 0x0004_0000_0000_0000
@test Unums.bottom_bit(UInt16(14)) == 0x0002_0000_0000_0000
@test Unums.bottom_bit(UInt16(15)) == 0x0001_0000_0000_0000
@test Unums.bottom_bit(UInt16(63)) == 0x0000_0000_0000_0001

twocellint = zero(Unums.ArrayNum{7})
@test Unums.bottom_bit!(twocellint, UInt16(63)).a == [o64, z64]
@test Unums.bottom_bit!(twocellint, UInt16(64)).a == [z64, t64]
@test Unums.bottom_bit!(twocellint).a == [z64, o64]
fourcellint = zero(Unums.ArrayNum{8})
@test Unums.bottom_bit!(fourcellint).a == [z64, z64, z64, o64]

################################################################################
## SHIFTS

#test leftshifts and rightshifts on multi-arrays
@test Unums.lsh(allbits, 4) == 0xFFFF_FFFF_FFFF_FFF0
@test Unums.rsh(allbits, 4) == 0x0FFF_FFFF_FFFF_FFFF
twocellint = Unums.ArrayNum{7}([allbits, allbits])
Unums.lsh!(twocellint,4)
@test twocellint.a == [allbits, 0xFFFF_FFFF_FFFF_FFF0]

twocellint.a = [allbits, allbits]
Unums.rsh!(twocellint,4)
@test twocellint.a == [0x0FFF_FFFF_FFFF_FFFF, allbits]


#test really long distance leftshifts and rightshifts
const allfour = [allbits, allbits, allbits, allbits]
const texture = [0x1234_5678_9ABC_DEF1, 0x2345_6789_ABCD_EF12, 0x3456_789A_BCDE_F123, 0x4567_89AB_CDEF_1234]

fourcellint = Unums.ArrayNum{8}(copy(allfour))
Unums.lsh!(fourcellint, 68)
@test fourcellint.a == [allbits, allbits, 0xFFFF_FFFF_FFFF_FFF0, nobits]

fourcellint.a = copy(allfour)
Unums.rsh!(fourcellint, 68)
@test fourcellint.a == [nobits, 0x0FFF_FFFF_FFFF_FFFF, allbits, allbits]

#textured shifts to make sure things are actually ok.
fourcellint.a = copy(texture)
Unums.lsh!(fourcellint, 4)
@test fourcellint.a ==  [0x2345_6789_ABCD_EF12, 0x3456_789A_BCDE_F123, 0x4567_89AB_CDEF_1234, 0x5678_9ABC_DEF1_2340]

fourcellint.a = copy(texture)
Unums.lsh!(fourcellint, 68)
@test fourcellint.a == [0x3456_789A_BCDE_F123, 0x4567_89AB_CDEF_1234, 0x5678_9ABC_DEF1_2340, nobits]

fourcellint.a = copy(texture)
Unums.rsh!(fourcellint, 4)
@test fourcellint.a == [0x0123_4567_89AB_CDEF, 0x1234_5678_9ABC_DEF1, 0x2345_6789_ABCD_EF12, 0x3456_789A_BCDE_F123]

fourcellint.a = copy(texture)
Unums.rsh!(fourcellint, 68)
@test fourcellint.a == [nobits, 0x0123_4567_89AB_CDEF, 0x1234_5678_9ABC_DEF1, 0x2345_6789_ABCD_EF12]

################################################################################
## COMPARISON

@test Unums.ArrayNum{7}([allbits, 0x0000_0000_0000_0001]) > Unums.ArrayNum{7}([allbits, nobits])
@test Unums.ArrayNum{7}([0x0000_0000_0000_0001, nobits]) > Unums.ArrayNum{7}([nobits, allbits])
@test Unums.ArrayNum{7}([allbits, nobits]) < Unums.ArrayNum{7}([allbits, 0x0000_0000_0000_0001])
@test Unums.ArrayNum{7}([nobits, allbits]) < Unums.ArrayNum{7}([0x0000_0000_0000_0001, nobits])


################################################################################
## UTILITIES

#test __minimum_data_width
@test Unums.__minimum_data_width(allbits) == 63
@test Unums.__minimum_data_width(nobits) == 0
@test Unums.__minimum_data_width(msb1) == 0
@test Unums.__minimum_data_width(lsb1) == 63
@test Unums.__minimum_data_width(msb8) == 7
@test Unums.__minimum_data_width(Unums.ArrayNum{7}([nobits, nobits])) == 0
@test Unums.__minimum_data_width(Unums.ArrayNum{7}([msb1, nobits])) == 0
@test Unums.__minimum_data_width(Unums.ArrayNum{7}([nobits, msb1])) == 64
@test Unums.__minimum_data_width(Unums.ArrayNum{7}([allbits, allbits])) == 127
@test Unums.__minimum_data_width(Unums.ArrayNum{7}([nobits, lsb1])) == 127
@test Unums.__minimum_data_width(Unums.ArrayNum{8}([nobits, nobits, nobits, lsb1])) == 255

#=
#test __allones_for_length
@test Unums.__allones_for_length(0x8000_0000_0000_0000,                  UInt16(0))
@test !Unums.__allones_for_length(z64,                                   UInt16(0))
@test Unums.__allones_for_length(0xF000_0000_0000_0000,                  UInt16(3))
@test !Unums.__allones_for_length(0xD000_0000_0000_0000,                 UInt16(3))
@test Unums.__allones_for_length(0xFFFF_0000_0000_0000,                  UInt16(15))
@test Unums.__allones_for_length(f64,                                    UInt16(63))
@test Unums.__allones_for_length(ArrayNum{7}([0x8000_0000_0000_0000, z64]),           UInt16(0))
@test Unums.__allones_for_length(ArrayNum{7}([f64, z64]),                             UInt16(63))
@test Unums.__allones_for_length(ArrayNum{7}([f64, t64]),                             UInt16(64))
@test Unums.__allones_for_length(ArrayNum{7}([f64, 0xC000_0000_0000_0000]),           UInt16(65))
@test Unums.__allones_for_length(ArrayNum{8}([f64, f64, 0xC000_0000_0000_0000, z64]), UInt16(129))
=#
