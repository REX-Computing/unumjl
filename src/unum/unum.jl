#unum.jl
#collation includes for all the code that supports the unum type (but not the
#type definition itself, that must be forwarded separately.)

include("./unum-typeproperties.jl")
include("./unum-helpers.jl")
include("./unum-constants.jl")
include("./unum-properties.jl")
include("./unum-operations.jl")
include("./unum-convert.jl")
include("./unum-comparison.jl")

#h-layer stuff

include("./unum-hlayer.jl")

#mathematical stuff

include("./unum-addition.jl")
