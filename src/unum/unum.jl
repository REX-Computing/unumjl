#unum.jl
#collation includes for all the code that supports the unum type (but not the
#type definition itself, that must be forwarded separately.)

include("./unum-helpers.jl")
include("./unum-constants.jl")
include("./unum-properties.jl")
include("./unum-operations.jl")
include("./unum-convert.jl")
#include("./unum-fracops.jl")

#h-layer stuff

#include("./unum-hlayer.jl")

#mathematical stuff


include("./math/unum-comparison.jl")
#include("./unum-addition.jl")
#include("./unum-subtraction.jl")
#include("./unum-multiplication.jl")
#include("./unum-division.jl")
