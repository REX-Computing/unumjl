#unum-test-int64op.jl

#some useful variables
msb1    = uint64(0x8000_0000_0000_0000)
lsb1    = uint64(0x0000_0000_0000_0001)
msb8    = uint64(0xFF00_0000_0000_0000)
msb6    = uint64(0xFC00_0000_0000_0000)
lsb6    = uint64(0x0000_0000_0000_003F)
allbits = uint64(0xFFFF_FFFF_FFFF_FFFF)
nobits  = uint64(0x0000_0000_0000_0000)

################################################################################
## SUPERINT CONSTANT GENERATION

@test Unums.superzero(1) == nobits
@test Unums.superone(1) ==  lsb1
@test Unums.supertop(1) ==  msb1
@test Unums.superzero(2) == [nobits, nobits]
@test Unums.superone(2) ==  [nobits, lsb1]
@test Unums.supertop(2) ==  [msb1, nobits]
@test Unums.superzero(4) == [nobits, nobits, nobits, nobits]
@test Unums.superone(4) ==  [nobits, nobits, nobits, lsb1]
@test Unums.supertop(4) ==  [msb1, nobits, nobits, nobits]

#bit_from_top
@test Unums.__bit_from_top(0,1)    == msb1
@test Unums.__bit_from_top(1,1)    == 0x4000_0000_0000_0000
@test Unums.__bit_from_top(63,1)   == lsb1
@test Unums.__bit_from_top(0, 2)   == [msb1, nobits]
@test Unums.__bit_from_top(63, 2)  == [lsb1, nobits]
@test Unums.__bit_from_top(64, 2)  == [nobits, msb1]
@test Unums.__bit_from_top(127, 2) == [nobits, lsb1]

################################################################################
## BIT PATTERN DETECTION

#is_all_zero
@test Unums.is_all_zero(nobits)
@test Unums.is_all_zero([nobits, nobits])
@test Unums.is_all_zero([nobits, nobits, nobits, nobits])
@test !Unums.is_all_zero(lsb1)
@test !Unums.is_all_zero([lsb1, nobits])
@test !Unums.is_all_zero([nobits, msb1])
@test !Unums.is_all_zero([lsb1, msb1])
@test !Unums.is_all_zero([nobits, nobits, lsb1, nobits])

#is_not_zero
@test !Unums.is_not_zero(nobits)
@test !Unums.is_not_zero([nobits, nobits])
@test !Unums.is_not_zero([nobits, nobits, nobits, nobits])
@test Unums.is_not_zero(lsb1)
@test Unums.is_not_zero([lsb1, nobits])
@test Unums.is_not_zero([nobits, msb1])
@test Unums.is_not_zero([lsb1, msb1])
@test Unums.is_not_zero([nobits, nobits, lsb1, nobits])

#is_top
@test Unums.is_top(msb1)
@test Unums.is_top([msb1, nobits])
@test Unums.is_top([msb1, nobits, nobits, nobits])
@test !Unums.is_top(nobits)
@test !Unums.is_top(msb1 & lsb1)
@test !Unums.is_top([msb1, lsb1])
@test !Unums.is_top([nobits, msb1])
@test !Unums.is_top([msb1, nobits, nobits, msb1])

#is_not_top
@test !Unums.is_not_top(msb1)
@test !Unums.is_not_top([msb1, nobits])
@test !Unums.is_not_top([msb1, nobits, nobits, nobits])
@test Unums.is_not_top(nobits)
@test Unums.is_not_top(msb1 & lsb1)
@test Unums.is_not_top([msb1, lsb1])
@test Unums.is_not_top([nobits, msb1])
@test Unums.is_not_top([msb1, nobits, nobits, msb1])

################################################################################
## CLZ AND CTZ

#clz
@test clz(allbits) == 0
@test clz(nobits) == 64
@test clz(msb8) == 0
@test clz(lsb6) == 58
@test clz(uint64(0b0001111000)) == 57
@test clz([nobits, 0x00FF_0000_0000_0000]) == 72
@test clz([0x0000_0000_0000_F00F, nobits]) == 48
@test clz([nobits, nobits]) == 128
#test ctz
@test ctz(allbits) == 0
@test ctz(nobits) == 64
@test ctz(msb8) == 56
@test ctz(lsb6) == 0
@test ctz(uint64(0b0001111000)) == 3
@test ctz([nobits, 0x00FF_0000_0000_0000]) == 48
@test ctz([0x0000_0000_0000_F00F, nobits]) == 64
@test ctz([nobits, nobits]) == 128

################################################################################
## MASKS

#test mask generation
@test Unums.mask(1) == lsb1
@test Unums.mask(-1) == msb1
@test Unums.mask(-8) == msb8
@test Unums.mask(6) == lsb6
@test Unums.mask(64) == allbits
@test Unums.mask(-64) == allbits
#note the difference between "mask(int)" which does a total number of bits in
#one direction or the other and "mask(range)" which uses zero-indexed ranges.
@test Unums.mask(0:3) == uint64(0x0000_0000_0000_000F)
@test Unums.mask(4:7) == uint64(0x0000_0000_0000_00F0)
@test Unums.mask(0:63) == allbits

#test the fillbits machinery.  One cell - should be identical to mask.
one16 = uint16(1)
@test Unums.fillbits(0,   one16) == nobits
@test Unums.fillbits(1,   one16) == lsb1
@test Unums.fillbits(-1,  one16) == msb1
@test Unums.fillbits(64,  one16) == allbits
@test Unums.fillbits(-64, one16) == allbits
#test two cells.
two16 = uint16(2)
@test Unums.fillbits(-1,   two16) == [msb1, nobits]
@test Unums.fillbits(1,    two16) == [nobits, lsb1]
@test Unums.fillbits(64,   two16) == [nobits, allbits]
@test Unums.fillbits(-64,  two16) == [allbits, nobits]
@test Unums.fillbits(65,   two16) == [lsb1, allbits]
@test Unums.fillbits(-65,  two16) == [allbits, msb1]
@test Unums.fillbits(0,    two16) == [nobits, nobits]
@test Unums.fillbits(128,  two16) == [allbits, allbits]
@test Unums.fillbits(-128, two16) == [allbits, allbits]
#test three cells
three16 = uint16(3)
@test Unums.fillbits(65, three16) == [nobits, lsb1, allbits]
@test Unums.fillbits(-65, three16) == [allbits, msb1, nobits]

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
