#unum-onezero.jl
#implements the one and zero functions for unums.

#SOME MATHEMATICAL CONSTANTS
import Base.zero    #make sure we know about this so we're not clobbering it
function zero{ESS,FSS}(::Type{Unum{ESS,FSS}})
  Unum{ESS,FSS}(uint16(0b0), uint16(0b0), uint16(0b0), uint64(0), uint64(0))
end
function zero(x::Unum)
  Unum{fsizesize(x),esizesize(x)}(uint16(0b0), uint16(0b0), uint16(0b0), uint64(0), uint64(0))
end
export zero

import Base.one
function one{ESS,FSS}(::Type{Unum{ESS,FSS}})
  Unum{ESS,FSS}(uint16(0b0), uint16(0b0), uint16(0b0), uint64(0), uint64(0b1))
end
function one(x::Unum)
  Unum{fsizesize(x),esizesize(x)}(uint16(0b0), uint16(0b0), uint16(0b0), uint64(0), uint64(0b1))
end
export one
