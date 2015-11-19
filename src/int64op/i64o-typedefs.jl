#i64o-typedefs.jl
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

function __check_ArrayNum(FSS, a::Array{UInt64,1})
  FSS < 7 && throw(ArgumentError("invalid FSS == $FSS < 7"))
  _al = __cell_length(FSS)
  length(a) < _al && throw(ArgumentError("invalid array length, should be at least $_al > $(length(a))"))
end

doc"""
`Unums.ArrayNum` is a variadic type which maps an `FSS` variable to an `Int64`
array of a size corresponding to `FSS`.

In development mode, a check is in place to make sure `FSS` matches the array
length.
"""
type ArrayNum{FSS}
  a::Array{UInt64,1}
  @dev_check FSS function ArrayNum(a::Array{UInt64,1})
    new(a)
  end
end
