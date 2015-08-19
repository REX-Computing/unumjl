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
@test Unums.bitof(allbits, 0) == lsb1
@test Unums.bitof(nobits, 0) == nobits
@test Unums.bitof(allbits, 63) == msb1
@test Unums.bitof(nobits, 63) == nobits

#test lsbmsb
@test Unums.lsbmsb(allbits) == (0,63)
@test Unums.lsbmsb(msb8) == (56,63)
@test Unums.lsbmsb(lsb6) == (0, 5)
@test Unums.lsbmsb(0b0001111000) == (3,6)

#test mask generation
@test Unums.mask(1) == lsb1
@test Unums.mask(-1) == msb1
@test Unums.mask(-8) == msb8
@test Unums.mask(6) == lsb6
@test Unums.mask(0:3) == uint64(0x0000_0000_0000_000F)
@test Unums.mask(4:7) == uint64(0x0000_0000_0000_00F0)
@test Unums.mask(0:63) == allbits
