#i64o-varint.jl
#definition of the varint union type and basic things to do with these values.
#the superint is a union of arbitrary length UInt64 and single value UInt64.
#operators are to be defined which seamlessly deal with all these numbers.

#Varints are arranged so that the UInt64 in position 1 is the most significant

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

__cell_length(FSS) = 1 << (FSS - 6)

__check_I64Array(FSS, a::Array{UInt64,1})
  FSS < 7 && throw(ArgumentError("invalid FSS == $FSS < 7"))
  _al = __cell_length(FSS)
  length(a) != _al && throw(ArgumentError("invalid array length, should be $_al != $(length(a))"))
end

type I64Array{FSS}
  a::Array{UInt64,1}
  @dev_check FSS function I64Array(a::Array{UInt64,1})
    new(a)
  end
end

__i64a_bits(a::UInt64) = bits(a)
__i64a_bits(a::I64Array{FSS}) = mapreduce(bits, (s1, s2) -> string(s1, s2), "", a.a)
