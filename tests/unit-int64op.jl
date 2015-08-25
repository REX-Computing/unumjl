#unum-test-int64op.jl

#some useful variables
msb1    = uint64(0x8000_0000_0000_0000)
lsb1    = uint64(0x0000_0000_0000_0001)
msb8    = uint64(0xFF00_0000_0000_0000)
msb6    = uint64(0xFC00_0000_0000_0000)
lsb6    = uint64(0x0000_0000_0000_003F)
allbits = uint64(0xFFFF_FFFF_FFFF_FFFF)
nobits  = uint64(0x0000_0000_0000_0000)

#test bitof
@test Unums.bitof(allbits, 0)  == lsb1
@test Unums.bitof(nobits, 0)   == nobits
@test Unums.bitof(allbits, 63) == msb1
@test Unums.bitof(nobits, 63)  == nobits
#test bit_from_top
@test Unums.__bit_from_top(1,1)    == msb1
@test Unums.__bit_from_top(2,1)    == 0x4000_0000_0000_0000
@test Unums.__bit_from_top(64,1)   == lsb1
@test Unums.__bit_from_top(1, 2)   == [nobits, msb1]
@test Unums.__bit_from_top(64, 2)  == [nobits, lsb1]
@test Unums.__bit_from_top(65, 2)  == [msb1, nobits]
@test Unums.__bit_from_top(128, 2) == [lsb1, nobits]

#test clz
@test clz(allbits) == 0
@test clz(nobits) == 64
@test clz(msb8) == 0
@test clz(lsb6) == 58
@test clz(uint64(0b0001111000)) == 57
@test clz(uint16(0b0001111000)) == 9
@test clz([0x00FF_0000_0000_0000, nobits]) == 72
@test clz([nobits, 0x0000_0000_0000_F00F]) == 48
@test clz([nobits, nobits]) == 128
#test ctz
@test ctz(allbits) == 0
@test ctz(nobits) == 64
@test ctz(msb8) == 56
@test ctz(lsb6) == 0
@test ctz(uint64(0b0001111000)) == 3
@test ctz(uint16(0b0001111000)) == 3
@test ctz([0x00FF_0000_0000_0000, nobits]) == 48
@test ctz([nobits, 0x0000_0000_0000_F00F]) == 64
@test ctz([nobits, nobits]) == 128

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
@test Unums.fillbits(0) == nobits
@test Unums.fillbits(1) == lsb1
@test Unums.fillbits(-1) == msb1
@test Unums.fillbits(64) == allbits
@test Unums.fillbits(-64) == allbits
#test two cells.
@test Unums.fillbits(-1, 2) == [nobits, msb1]
@test Unums.fillbits(1, 2) == [lsb1, nobits]
@test Unums.fillbits(64, 2) == [allbits, nobits]
@test Unums.fillbits(-64, 2) == [nobits, allbits]
@test Unums.fillbits(65, 2) == [allbits, lsb1]
@test Unums.fillbits(-65, 2) == [msb1, allbits]#@test Unums.fi
@test Unums.fillbits(0, 2) == [nobits, nobits]
@test Unums.fillbits(128, 2) == [allbits, allbits]
@test Unums.fillbits(-128, 2) == [allbits, allbits]
#test three cells
@test Unums.fillbits(65,3) == [allbits, lsb1, nobits]
@test Unums.fillbits(-65,3) == [nobits, msb1, allbits]

#test leftshifts and rightshifts on multi-arrays
@test Unums.lsh(allbits, 4) == 0xFFFF_FFFF_FFFF_FFF0
@test Unums.rsh(allbits, 4) == 0x0FFF_FFFF_FFFF_FFFF
@test Unums.lsh([allbits, allbits],4) == [0xFFFF_FFFF_FFFF_FFF0, allbits]
@test Unums.rsh([allbits, allbits],4) == [allbits, 0x0FFF_FFFF_FFFF_FFFF]
#test really long distance leftshifts and rightshifts
@test Unums.lsh([allbits, allbits, allbits, allbits], 68) == [nobits, 0xFFFF_FFFF_FFFF_FFF0, allbits, allbits]
@test Unums.rsh([allbits, allbits, allbits, allbits], 68) == [allbits, allbits, 0x0FFF_FFFF_FFFF_FFFF, nobits]
