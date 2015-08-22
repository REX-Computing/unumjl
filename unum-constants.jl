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

import Base.nan
function nan{ESS,FSS}(::Type{Unum{ESS,FSS}})
  esize = uint16(1 << ESS - 1)
  fsize = uint16(1 << FSS - 1)
  Unum{ESS,FSS}(fsize, esize, UNUM_UBIT_MASK, fillbits(1 << FSS, __frac_cells(FSS)), mask(1 << ESS))
end
export nan

import Base.inf
function inf{ESS,FSS}(::Type{Unum{ESS,FSS}})
  esize = uint16(1 << ESS - 1)
  fsize = uint16(1 << FSS - 1)
  Unum{ESS,FSS}(fsize, esize, z16, fillbits(1 << FSS, __frac_cells(FSS)), mask(1 << ESS))
end
pinf{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = inf(T)
ninf{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = unum_unsafe(inf(T), UNUM_SIGN_MASK)
export inf
export pinf
export ninf
