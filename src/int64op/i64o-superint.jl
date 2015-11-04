#i64o-superint.jl
#definition of the superint union type and basic things to do with these values.
#the superint is a union of arbitrary length UInt64 and single value UInt64.
#operators are to be defined which seamlessly deal with all these numbers.

#Superints are arranged so that the UInt64 in position 1 is the most significant

#various helpful numbers

#sixteen bit numbers
const z16 = zero(UInt16)
const o16 = one(UInt16)
const f16 = UInt16(0xFFFF)

#64 bit numbers
const z64 = zero(UInt64)
const o64 = one(UInt64)
const t64 = 0x8000_0000_0000_0000               #top bit
const f64 = 0xFFFF_FFFF_FFFF_FFFF               #full bits

__i64a_bits(a::UInt64) = bits(a)
__i64a_bits(a::Array{UInt64, 1}) = mapreduce(bits, (s1, s2) -> string(s1, s2), "", a)
