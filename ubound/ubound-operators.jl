#ubound-addition.jl
#addition and subtraction on the ubound class.

#forward to respective files

include("ubound-addition.jl")
include("ubound-subtraction.jl")
include("ubound-division.jl")
include("ubound-multiplication.jl")
include("ubound-sqrs.jl")

################################################################################
## width

function width{ESS,FSS}(b::Ubound{ESS,FSS})
  b.highbound - b.lowbound
end
export width
