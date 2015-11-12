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

#ArrayNums of size < 7 are disallowed.
@test_throws ArgumentError Unums.ArrayNum{1}([z64])
@test_throws ArgumentError Unums.ArrayNum{2}([z64])
@test_throws ArgumentError Unums.ArrayNum{3}([z64])
@test_throws ArgumentError Unums.ArrayNum{4}([z64])
@test_throws ArgumentError Unums.ArrayNum{5}([z64])
@test_throws ArgumentError Unums.ArrayNum{6}([z64])
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
#=
#test mask generation
@test Unums.mask(1) == lsb1
@test Unums.mask(-1) == msb1
@test Unums.mask(-8) == msb8
@test Unums.mask(6) == lsb6
@test Unums.mask(64) == allbits
@test Unums.mask(-64) == allbits

#test the fillbits machinery.  One cell - should be identical to mask.
@test Unums.fillbits(0,   1) == nobits
@test Unums.fillbits(1,   1) == lsb1
@test Unums.fillbits(-1,  1) == msb1
@test Unums.fillbits(64,  1) == allbits
@test Unums.fillbits(-64, 1) == allbits
#test two cells.
@test Unums.fillbits(-1,   2) == [msb1, nobits]
@test Unums.fillbits(1,    2) == [nobits, lsb1]
@test Unums.fillbits(64,   2) == [nobits, allbits]
@test Unums.fillbits(-64,  2) == [allbits, nobits]
@test Unums.fillbits(65,   2) == [lsb1, allbits]
@test Unums.fillbits(-65,  2) == [allbits, msb1]
@test Unums.fillbits(0,    2) == [nobits, nobits]
@test Unums.fillbits(128,  2) == [allbits, allbits]
@test Unums.fillbits(-128, 2) == [allbits, allbits]
#test three cells
@test Unums.fillbits(65,  3) == [nobits, lsb1, allbits]
@test Unums.fillbits(-65, 3) == [allbits, msb1, nobits]

################################################################################
## SHIFTS

#test leftshifts and rightshifts on multi-arrays
@test Unums.lsh(allbits, 4) == 0xFFFF_FFFF_FFFF_FFF0
@test Unums.rsh(allbits, 4) == 0x0FFF_FFFF_FFFF_FFFF
@test Unums.lsh([allbits, allbits],4) == [allbits, 0xFFFF_FFFF_FFFF_FFF0]
@test Unums.rsh([allbits, allbits],4) == [0x0FFF_FFFF_FFFF_FFFF, allbits]
#test really long distance leftshifts and rightshifts
@test Unums.lsh([allbits, allbits, allbits, allbits], 68) == [allbits, allbits, 0xFFFF_FFFF_FFFF_FFF0, nobits]
@test Unums.rsh([allbits, allbits, allbits, allbits], 68) == [nobits, 0x0FFF_FFFF_FFFF_FFFF, allbits, allbits]
#textured shifts to make sure things are actually ok.
@test Unums.lsh([0x1234_5678_9ABC_DEF0, 0x2345_6789_ABCD_EF01, 0x3456_789A_BCDE_F012], 4) ==  [0x234_5678_9ABC_DEF02, 0x345_6789_ABCD_EF013, 0x456_789A_BCDE_F0120]
@test Unums.lsh([0x1234_5678_9ABC_DEF0, 0x2345_6789_ABCD_EF01, 0x3456_789A_BCDE_F012], 68) == [0x345_6789_ABCD_EF013, 0x456_789A_BCDE_F0120, nobits]
@test Unums.rsh([0x1234_5678_9ABC_DEF0, 0x2345_6789_ABCD_EF01, 0x3456_789A_BCDE_F012], 4) ==  [0x01234_5678_9ABC_DEF, 0x02345_6789_ABCD_EF0, 0x13456_789A_BCDE_F01]
@test Unums.rsh([0x1234_5678_9ABC_DEF0, 0x2345_6789_ABCD_EF01, 0x3456_789A_BCDE_F012], 68) == [nobits, 0x01234_5678_9ABC_DEF, 0x02345_6789_ABCD_EF0]

################################################################################
## COMPARISON

@test [allbits, 0x0000_0000_0000_0001] > [allbits, nobits]
@test [0x0000_0000_0000_0001, nobits] > [nobits, allbits]
@test [allbits, nobits] < [allbits, 0x0000_0000_0000_0001]
@test [nobits, allbits] < [0x0000_0000_0000_0001, nobits]

################################################################################
## UTILITIES

#test __minimum_data_width
@test Unums.__minimum_data_width(allbits) == 63
@test Unums.__minimum_data_width(nobits) == 0
@test Unums.__minimum_data_width(msb1) == 0
@test Unums.__minimum_data_width(lsb1) == 63
@test Unums.__minimum_data_width(msb8) == 7
@test Unums.__minimum_data_width([nobits, nobits]) == 0
@test Unums.__minimum_data_width([msb1, nobits]) == 0
@test Unums.__minimum_data_width([nobits, msb1]) == 64
@test Unums.__minimum_data_width([allbits, allbits]) == 127
@test Unums.__minimum_data_width([nobits, lsb1]) == 127
@test Unums.__minimum_data_width([nobits, nobits, nobits, lsb1]) == 255

#test __allones_for_length
@test Unums.__allones_for_length(0x8000_0000_0000_0000,                  UInt16(0))
@test !Unums.__allones_for_length(z64,                                   UInt16(0))
@test Unums.__allones_for_length(0xF000_0000_0000_0000,                  UInt16(3))
@test !Unums.__allones_for_length(0xD000_0000_0000_0000,                 UInt16(3))
@test Unums.__allones_for_length(0xFFFF_0000_0000_0000,                  UInt16(15))
@test Unums.__allones_for_length(f64,                                    UInt16(63))
@test Unums.__allones_for_length([0x8000_0000_0000_0000, z64],           UInt16(0))
@test Unums.__allones_for_length([f64, z64],                             UInt16(63))
@test Unums.__allones_for_length([f64, t64],                             UInt16(64))
@test Unums.__allones_for_length([f64, 0xC000_0000_0000_0000],           UInt16(65))
@test Unums.__allones_for_length([f64, f64, 0xC000_0000_0000_0000, z64], UInt16(129))
=#

@test implementation_incomplete
