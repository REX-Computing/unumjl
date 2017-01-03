#unum.jl
#collation includes for all the code that supports the unum type (but not the
#type definition itself, that must be forwarded separately.)

include("./unum-helpers.jl")
include("./unum-constants.jl")
include("./unum-properties.jl")
include("./unum-operations.jl")
include("./unum-convert.jl")
include("./unum-promote.jl")

#h-layer stuff

include("./unum-hlayer.jl")

#mathematical stuff

include("./math/unum-comparison.jl")
include("./math/unum-addition.jl")
include("./math/unum-subtraction.jl")
include("./math/unum-multiplication.jl")
include("./math/unum-division.jl")
include("./math/unum-sqrs.jl")
