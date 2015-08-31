#unum-onezero.jl
#implements the one and zero functions for unums.

#SOME MATHEMATICAL CONSTANTS
import Base.zero    #make sure we know about this so we're not clobbering it
function zero{ESS,FSS}(::Type{Unum{ESS,FSS}})
  Unum{ESS,FSS}(uint16(0b0), uint16(0b0), uint16(0b0), superzero(__frac_cells(FSS)), uint64(0))
end
function zero(x::Unum)
  Unum{fsizesize(x),esizesize(x)}(uint16(0b0), uint16(0b0), uint16(0b0), superzero(__frac_cells(FSS)), uint64(0))
end
export zero

import Base.one
function one{ESS,FSS}(::Type{Unum{ESS,FSS}})
  Unum{ESS,FSS}(uint16(0b0), uint16(0b0), uint16(0b0), superzero(__frac_cells(FSS)), uint64(0b1))
end
function one(x::Unum)
  Unum{fsizesize(x),esizesize(x)}(uint16(0b0), uint16(0b0), uint16(0b0), superzero(__frac_cells(FSS)), uint64(0b1))
end
export one

import Base.nan
function nan{ESS,FSS}(::Type{Unum{ESS,FSS}})
  esize::Uint16 = 1 << ESS - 1
  fsize::Uint16 = 1 << FSS - 1
  Unum{ESS,FSS}(fsize, esize, UNUM_UBIT_MASK, fillbits(-(1 << FSS), __frac_cells(FSS)), mask(1 << ESS))
end
function nan!{ESS,FSS}(::Type{Unum{ESS,FSS}})
  esize::Uint16 = 1 << ESS - 1
  fsize::Uint16 = 1 << FSS - 1
  Unum{ESS,FSS}(fsize, esize, UNUM_UBIT_MASK | UNUM_SIGN_MASK, fillbits(-(1 << FSS), __frac_cells(FSS)), mask(1 << ESS))
end
export nan, nan!

import Base.inf
function inf{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask = z16)
  esize::Uint16 = 1 << ESS - 1
  fsize::Uint16 = 1 << FSS - 1
  Unum{ESS,FSS}(fsize, esize, signmask, fillbits(-(1 << FSS), __frac_cells(FSS)), mask(1 << ESS))
end
pos_inf{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = inf(T)
neg_inf{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = inf(T, UNUM_SIGN_MASK)
export inf, pos_inf, neg_inf

#mmr and ssn - "more than maxreal" and "smaller than subnormal", ubits for very small things.
function mmr{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask = z16)
  esize   ::Uint16 = 1 << ESS - 1
  fsize   ::Uint16 = 1 << FSS - 1
  max_exp ::Uint64 = 1 << (esize + 1) - 1
  Unum{ESS,FSS}(fsize, esize, signmask | UNUM_UBIT_MASK, fillbits(1 - (1 << FSS), __frac_cells(FSS)), max_exp)
end
function ssn{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask = z16)
  esize::Uint16 = 1 << ESS - 1
  fsize::Uint16 = 1 << FSS - 1
  Unum{ESS,FSS}(fsize, esize, signmask | UNUM_UBIT_MASK, zeros(Uint64,__frac_cells(FSS)), z64)
end
pos_mmr{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = mmr(T)
neg_mmr{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = mmr(T, UNUM_SIGN_MASK)
pos_ssn{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = ssn(T)
neg_ssn{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = ssn(T, UNUM_SIGN_MASK)
export mmr, ssn, pos_mmr, neg_mmr, pos_ssn, neg_ssn

#a function that generates the "big_exact value of either the positive or neegative sign."
function big_exact{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask = z16)
  esize   ::Uint16 = 1 << ESS - 1
  fsize   ::Uint16 = 1 << FSS - 2
  max_exp ::Uint64 = 1 << (esize + 1) - 1
  Unum{ESS,FSS}(fsize, esize, signmask, fillbits(1 - (1 << FSS), __frac_cells(FSS)), max_exp)
end
pos_big_exact{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = big_exact(T)
neg_big_exact{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = big_exact(T, UNUM_SIGN_MASK)
export big_exact, pos_bigexact, neg_bigexact

function small_exact{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask = z16)
  esize   ::Uint16 = 1 << ESS - 1
  fsize   ::Uint16 = 1 << FSS - 1
  Unum{ESS,FSS}(fsize, esize, signmask, __bit_from_top(fsize + 1, __frac_cells(FSS)), z64)
end
pos_small_exact{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = small_exact(T)
neg_small_exact{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = small_exact(T, UNUM_SIGN_MASK)
