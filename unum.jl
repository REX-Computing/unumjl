#unum.jl - a julia implementation of the unum
# this file is the module definition file and also contains
# includes for all of the components which make it work

#for now, only compatible with 64-bit architectures.
@assert(sizeof(Int) == 8, "currently only compatible with 64-bit architectures")

module Unums
#this module exports the Unum Type
export Unum

#bring in some important uint64 bitwise methods
include("unum-int64op.jl")
#helpers used in the unum type constructors andn pseudoconstructors
include("unum-helpers.jl")
#the base unum type and its pseudoconstructors
include("unum-unum.jl")
#and the derived ubound type
include("unum-ubound.jl")

include("unum-typefunctions.jl")
include("unum-onezero.jl")
include("unum-convert.jl")
include("unum-properties.jl")
include("unum-oddsandends.jl")
#some math stuff
include("unum-addition.jl")
include("unum-multiplication.jl")
include("unum-division.jl")
include("unum-comparison.jl")

import Base.bits

function describe(x::Unum)
  bits(x, " ")
end
function bits(x::Unum, space::ASCIIString = "")
  res = ""
  for idx = 0:fsizesize(x) - 1
    res = string((x.fsize >> idx) & 0b1, res)
  end
  res = string(space, res)
  for idx = 0:esizesize(x) - 1
    res = string((x.esize >> idx) & 0b1, res)
  end
  res = string(space, x.flags & 0b1, space, res)
  tl = length(x.fraction) * 64 - 1
  for idx = (tl-x.fsize):tl
    res = string(((x.fraction[integer(ceil((idx + 1) / 64))] >> (idx % 64)) & 0b1), res)
  end
  res = string(space, res)
  for idx = 0:x.esize
    res = string(((x.exponent[integer(ceil((idx + 1) / 64))] >> (idx % 64)) & 0b1), res)
  end
  res = string((x.flags & 0b10) >> 1, space, res)
  res
end
export bits

end #module
