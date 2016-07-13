#i64o-typedefs.jl

#a helper function which generates the appropriate number of cells for any given FSS
__cell_length(FSS) = 1 << (FSS - 6)

# a helper function that checks arraynum inputs.
function __check_ArrayNum(FSS, a::Array{UInt64,1})
  FSS < 7 && throw(ArgumentError("invalid FSS == $FSS < 7"))
  _al = __cell_length(FSS)
  length(a) < _al && throw(ArgumentError("invalid array length, should be at least $_al > $(length(a))"))
end

doc"""
`Unums.ArrayNum` is a variadic type which maps an `FSS` variable to an `Int64`
array of a size corresponding to `FSS`.
"""
@dev_check type ArrayNum{FSS}
  a::Array{UInt64,1}
end
