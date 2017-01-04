#ubound.jl
#collation includes for all the code that supports the ubound type (but not the
#type definition itself, that must be forwarded separately.)

include("./math/ubound-comparison.jl")
include("./math/ubound-addition.jl")
include("./math/ubound-subtraction.jl")
include("./math/ubound-multiplication.jl")
include("./math/ubound-operations.jl")
include("./math/ubound-division.jl")
include("./math/ubound-sqrs.jl")

include("ubound-resolve.jl")
include("ubound-hlayer.jl")
include("ubound-properties.jl")
