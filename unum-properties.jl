#unum-properties
#functions that assess properties of unum values.
decode_exp(x::Unum) = decode_exp(x.esize, x.exponent)
export decode_exp

#a couple of testing conditions
import Base.isnan
function isnan{ESS,FSS}(x::Unum{ESS,FSS})
  (x.fsize == (1 << FSS - 1)) && (x.esize == (1 << ESS - 1)) && (x.flags == 0b1) && (x.fraction == fillbits(-(1 << FSS), uint16(length(x.fraction)))) && (x.exponent == mask(1 << ESS))
end
export isnan


import Base.isinf
import Base.isfinite
#isinf matches the julia definiton and triggers on either positive or negative
#infinity.  is_pos_inf and is_neg_inf both are Unum-specific functions that detect
#the expected values.
isinf{ESS,FSS}(x::Unum{ESS,FSS}) = (x.flags & UNUM_UBIT_MASK == 0) && (x.esize == 1 << ESS - 1) && (x.exponent == mask(1 << ESS)) && (x.fsize == 1 << FSS - 1) && (x.fraction == fillbits(-(1 << FSS), uint16(length(x.fraction))))
is_pos_inf{ESS, FSS}(x::Unum{ESS, FSS}) = ((x.flags & UNUM_SIGN_MASK) == 0) && isinf(x)
is_neg_inf{ESS, FSS}(x::Unum{ESS, FSS}) = ((x.flags & UNUM_SIGN_MASK) != 0) && isinf(x)
#caution, isfinite is a rather slow algorithm
isfinite{ESS,FSS}(x::Unum{ESS,FSS}) = (x.exponent != mask(1 << ESS)) || (x.fraction != fillbits(-1 << FSS, uint16(length(x.fraction))))
export isinf, is_pos_inf, is_neg_inf, isfinite


# a helper function for issubnormal, and isfraczero.  Optimized to be fast.
function __breakaway_checkzeros(a::Array{Uint64})
  for idx = length(a):-1:1
    a[idx] != 0 && return false
  end
  true
end

import Base.issubnormal
issubnormal{ESS,FSS}(x::Unum{ESS,FSS}) = (x.exponent == 0) && ((ESS > 6) ? !(__breakaway_checkzeros(x.fraction)) : x.fraction != 0)

#use ESS because this will be checked by the compiler, instead of at runtime.
isfraczero{ESS,FSS}(x::Unum{ESS,FSS}) = (ESS > 6) ? __breakaway_checkzeros(x.fraction) : (x.fraction == 0)

iszero(x::Unum) = (x.exponent == z64) && ((x.flags & UNUM_UBIT_MASK) == 0) && isfraczero(x)
#checks if the value is small subnormal
is_ssn(x::Unum) = (x.exponent == z64) && ((x.flags & UNUM_UBIT_MASK) != 0) && isfraczero(x)
is_pos_ssn(x::Unum) = (x.flags & UNUM_SIGN_MASK == 0) && is_ssn(x)
is_neg_ssn(x::Unum) = (x.flags & UNUM_SIGN_MASK != 0) && is_ssn(x)
#checks if the value is more than maxreal
is_mmr{ESS,FSS}(x::Unum{ESS,FSS}) = (x.flags & UNUM_UBIT_MASK != 0) && (x.exponent == mask(1 << ESS)) && (x.fraction == fillbits(-(1 << FSS - 1), uint16(length(x.fraction))))
is_pos_mmr(x::Unum) = (x.flags & UNUM_SIGN_MASK == 0) && is_mmr(x)
is_neg_mmr(x::Unum) = (x.flags & UNUM_SIGN_MASK != 0) && is_mmr(x)

isulp(x::Unum) = ((x.flags & UNUM_UBIT_MASK) != 0)
export issubnormal
export isfraczero, iszero, is_ssn, is_pos_ssn, is_neg_ssn
export is_mmr, is_pos_mmr, is_neg_mmr, isulp
