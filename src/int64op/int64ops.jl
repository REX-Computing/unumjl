#int64ops.jl
#collates all of the relevant int64 operations

#bring in some important UInt64 bitwise methods
include("./i64o-varint.jl")         #basic varint class definition
include("./i64o-constants.jl")      #functions generating int64 constants
include("./i64o-bitpatterns.jl")    #boolean functions reporting on bit patterns
include("./i64o-clzctz.jl")         #leading_zeros and trailing_zeros methods.
include("./i64o-masks.jl")          #mask generating operators
include("./i64o-shifts.jl")         #left and right shift operators
include("./i64o-comparison.jl")     #chaining comparison operators
include("./i64o-utilities.jl")      #other int64 utilities that help unums.
