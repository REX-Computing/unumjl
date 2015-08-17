#unum-test-helpers.jl

#test unum helpers.

#testing unum initialization helpers.

#testing "fractrim"
#one bit at the most significant bit
@test Unums.fractrim(msb1, 0, 1) == msb1
#having more bits of data should result in trimming from the left.
@test Unums.fractrim(msb8, 5, 1) == msb6
#test at the boundary.
@test Unums.fractrim(allbits, 63, 1) == allbits
#test something strange; as the value is too big, it should throw an error.
@test_throws ArgumentError Unums.fractrim(allbits, 69, 1)
#test inputting a one-word value and getting back a padded array, with the
#input as the most significant result.
@test Unums.fractrim(msb8, 69, 2) == [zero(Uint64), msb8]
#test inputting an array and getting back a trimmed int
@test Unums.fractrim([zero(Uint64), msb8], 5, 1) == msb6
#test inputting an array and getting back a trimmed array
@test Unums.fractrim([zero(Uint64), msb8, zero(Uint64)], 69, 2) == [msb6, zero(Uint64)]
#test inputting an array and getting back a trimmed array, but with a shorter
#trim than the number of space words.
@test Unums.fractrim([zeros(Uint64, 2), msb8, allbits], 69, 3) == [zero(Uint64), msb6, allbits]

#testing fsizesize and esizesize
@test Unums.fsizesize(zero(Unum{3,4})) == 4
@test Unums.esizesize(zero(Unum{3,4})) == 3
