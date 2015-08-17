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
#the base unum type
include("unum-unum.jl")
#and the derived ubound type
include("unum-ubound.jl")

###########################################################
#Utility functions

#fractrim:  Returns a SuperInt of specified length, bitshifted fully to the left.
function fractrim(frac::SuperInt, fsize::Integer, fwords::Integer)
  #note that if frac is Uint64, it can still be array-dereferenced as frac[1]
  #the only question is are we outputting an int or an int array.
  fsize_real = fsize + 1
  if (fwords == 1)
    if (fsize_real > 64)
      throw(ArgumentError("fraction size exceeds word limit"))
    end
    last(frac) & mask(-fsize_real)
  else
    l = length(frac)
    #copy array if there's enough parts to the array, otherwise pad with zeros
    res = (fwords <= l) ? frac[(l - fwords + 1):l] : res = [zeros(Uint64, fwords - l), frac]
    #now mask all the insignificant words with zeros.
    for idx = 1:fwords - (fsize >> 6 + 1)
      res[idx] = zero(Uint64)
    end
    #for the last word, treat it with an appropriate bitmask.
    res[fwords - fsize >> 6] &= mask(-(fsize_real % 64))
    res
  end
end


################################################################################
# EXPONENT ENCODING AND DECODING

#encodes an exponent as a biased value with parameter (esize, exponent)
function encode_exp(unbiasedexp::Integer)
  #remember msb is zero-indexed, but outputs a zero for the zero value
  esize = (unbiasedexp == 0) ? uint16(0) : uint16(msb(abs(unbiasedexp)) + 1)
  (esize, uint64(unbiasedexp + 2^esize))
end
#the inverse operation is finding the unbiased exponent of an Unum.
function decode_exp(esize::Uint16, exponent::Uint64)
  int(exponent) - 2^esize
end
function decode_exp(x::Unum)
  int(x.exponent) - 2^(x.esize)
end

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
