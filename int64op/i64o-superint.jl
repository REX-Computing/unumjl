#i64o-superint.jl
#definition of the superint union type and basic things to do with these values.
#the superint is a union of arbitrary length Uint64 and single value Uint64.
#operators are to be defined which seamlessly deal with all these numbers.

#Superints are arranged so that the Uint64 in position 1 is the most significant

#various helpful numbers

#sixteen bit numbers
const z16 = zero(Uint16)
const o16 = one(Uint16)
const f16 = uint16(0xFFFF)

#64 bit numbers
const z64 = zero(Uint64)
const o64 = one(Uint64)
const t64 = 0x8000_0000_0000_0000               #top bit
const f64 = 0xFFFF_FFFF_FFFF_FFFF               #full bits

#note in version 0.4, this will need to change to Union{}
SuperInt = Union(Uint64, Array{Uint64,1})

__copy_superint(a::Uint64) = a
__copy_superint(a::Array{Uint64, 1}) = copy(a)

superbits(a::Uint64) = bits(a)
superbits(a::Array{Uint64, 1}) = mapreduce(bits, (s1, s2) -> string(s1, s2), "", a)
