#i64o-hlayer

__i64a_bits(a::UInt64) = bits(a)
__i64a_bits(a::I64Array{FSS}) = mapreduce(bits, (s1, s2) -> string(s1, s2), "", a.a)
