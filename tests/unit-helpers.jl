#test-helpers.jl

#test __frac_trim(frac, fsize) - this is a function solely used in the
#constructor. __frac_trim takes a dump of bits (frac) in superint
#and trims it down to size according to (fsize).  NB.  fsize the variable
#represents the actual number of fraction bits *minus one*.  outputs
#the new superint, the fsize (as potentially modified), and a ubit.

#in a 64-bit single width superint.  Trim for fsize = 0, i.e. down to 1 bit.
@test Unums.__frac_trim(nobits,  uint16(0)) == (nobits, 0, 0)
@test Unums.__frac_trim(allbits, uint16(0)) == (msb1  , 0, Unums.UNUM_UBIT_MASK)
#Trim for fsize = 1, i.e. down to two bits.
@test Unums.__frac_trim(nobits,  uint16(1)) == (nobits, 0, 0) #note this is the same as above
@test Unums.__frac_trim(allbits, uint16(1)) == (0xC000_0000_0000_0000, 1, Unums.UNUM_UBIT_MASK)
#in this case we have a distant uncertain-causing bit and also a trailing zero.
#The trim should not move to 0, and the ubit should be flagged.
@test Unums.__frac_trim(0x8010_0000_0000_0000, uint16(0)) == (msb1, 0, Unums.UNUM_UBIT_MASK)
@test Unums.__frac_trim(0x8010_0000_0000_0000, uint16(3)) == (msb1, 3, Unums.UNUM_UBIT_MASK)
@test Unums.__frac_trim(0xFFFF_FFFF_FFFF_FFFC, uint16(61)) == (0xFFFF_FFFF_FFFF_FFFC, 61, 0)
@test Unums.__frac_trim(0xFFFF_FFFF_FFFF_FFFC, uint16(63)) == (0xFFFF_FFFF_FFFF_FFFC, 61, 0)
@test Unums.__frac_trim(allbits, uint16(63)) == (allbits, 63, 0)
#test two-cell SuperInt with fractrim.
@test Unums.__frac_trim([nobits, nobits], uint16(0)) == ([nobits, nobits], 0, 0)
@test Unums.__frac_trim([nobits, nobits], uint16(127)) == ([nobits, nobits], 0, 0)
@test Unums.__frac_trim([lsb1, nobits], uint16(0)) == ([nobits, nobits], 0, Unums.UNUM_UBIT_MASK)
@test Unums.__frac_trim([lsb1, nobits], uint16(63)) == ([nobits, nobits], 63, Unums.UNUM_UBIT_MASK)
@test Unums.__frac_trim([nobits, lsb1], uint16(63)) == ([nobits, lsb1], 63, 0)
#test three-cell SuperInts with fractrim.
@test Unums.__frac_trim([nobits, nobits, nobits], uint16(0)) == ([nobits, nobits, nobits], 0, 0)
@test Unums.__frac_trim([nobits, nobits, nobits], uint16(191)) == ([nobits, nobits, nobits], 0 ,0)
@test Unums.__frac_trim([allbits, allbits, allbits], uint16(63)) == ([nobits, nobits, allbits], 63, Unums.UNUM_UBIT_MASK)
@test Unums.__frac_trim([allbits, allbits, allbits], uint16(191)) == ([allbits, allbits, allbits,], 191, 0)

#make sure we can't try to trim something to more bits than it has.
@test_throws ArgumentError Unums.__frac_trim(nobits, uint16(64))

#testing the frac_match, which expands or contracts a SuperInt to match the fss, and throws
#the ubit flag if it makes sense.

#downshifting from a long SuperInt to a much smaller one.
#having any bits in less significant cells will throw the ubit.
@test Unums.__frac_match([lsb1, nobits], 1) == (nobits, Unums.UNUM_UBIT_MASK)
@test Unums.__frac_match([nobits, msb1], 2) == (msb1, 0)
#having clear less significant cells, but some digits in more siginificant cells
#still throws the ubit.
@test Unums.__frac_match([nobits, allbits], 4) == (0xFFFF_0000_0000_0000, Unums.UNUM_UBIT_MASK)
#upshifting from a shorter SuperInt to a bigger one merely pads with zeros
@test Unums.__frac_match(allbits, 7) == ([nobits, allbits], 0)
@test Unums.__frac_match(allbits, 8) == ([nobits, nobits, nobits, allbits], 0)
@test Unums.__frac_match([allbits, msb1], 8) == ([nobits, nobits, allbits, msb1], 0)


#test encoding and decoding exponents
#remember, esize is the size of the exponent *minus one*.

#a helpful table.
#  esize    values     representation
#------------------------------------
#   0        0          <subnormal>
#            1          1
#------------------------------------
#   1        00         <subnormal>
#            01         0
#            10         1
#            11         2
#------------------------------------
#   2        000        <subnormal>
#            001        -2
#            010        -1
#            011        0
#            100        1
#            101        2
#            110        3
#            111        4
#------------------------------------
#   3        0000       <subnormal>
#            0001       -6
#            0010       -5
#  etc.

#spot checking exponent encoding for intent.
@test (1, 1) == Unums.encode_exp(0)
@test (2, 2) == Unums.encode_exp(-1)
@test (0, 1) == Unums.encode_exp(1)
@test (3, 4) == Unums.encode_exp(-3)
@test (1, 3) == Unums.encode_exp(2)

@test Unums.max_exponent(0) == 1
@test Unums.min_exponent(0) == 1
@test Unums.max_exponent(1) == 4
@test Unums.min_exponent(1) == -2
@test Unums.max_exponent(2) == 8
@test Unums.min_exponent(2) == -6
@test Unums.max_exponent(3) == 127
@test Unums.min_exponent(3) == -127
@test Unums.max_exponent(4) == 32767
@test Unums.min_exponent(4) == -32767

#comprehensive checking of all exponents in the range -1000..1000

for e = -1000:1000
  @test e == Unums.decode_exp(Unums.encode_exp(e)...)
end

#checking max_fsize function
#helpful table.
#FSS    maximum fsize bitrep   fsize  real_fsize
# 0        [0]                   0        1
# 1         1                    1        2
# 2        11                    3        4
# 3       111                    7        8
# 4      1111                   15       16
#...

@test Unums.max_fsize(0) == 0
@test Unums.max_fsize(1) == 1
@test Unums.max_fsize(2) == 3
@test Unums.max_fsize(3) == 7
@test Unums.max_fsize(4) == 15
@test Unums.max_fsize(5) == 31
@test Unums.max_fsize(6) == 63
@test Unums.max_fsize(7) == 127
@test Unums.max_fsize(8) == 255

@test Unums.__frac_cells(0) == 1
@test Unums.__frac_cells(1) == 1
@test Unums.__frac_cells(2) == 1
@test Unums.__frac_cells(3) == 1
@test Unums.__frac_cells(4) == 1
@test Unums.__frac_cells(5) == 1
@test Unums.__frac_cells(6) == 1
@test Unums.__frac_cells(7) == 2
@test Unums.__frac_cells(8) == 4

@test Unums.__set_lsb(zero(Uint64), 0) = 0x8000_0000_0000_0000
@test Unums.__set_lsb(zero(Uint64), 5) = 0x0000_0001_0000_0000
@test Unums.__set_lsb(zero(Uint64), 6) = 0x0000_0000_0000_0001
@test Unums.__set_lsb(zeros(Uint64, 2), 7) = [0x0000_0000_0000_0001, 0x0]
@test Unums.__set_lsb(zeros(Uint64, 4), 8) = [0x0000_0000_0000_0001, 0x0, 0x0, 0x0]
