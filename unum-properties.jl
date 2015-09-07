#unum-properties
#functions that assess properties of unum values.
decode_exp(x::Unum) = decode_exp(x.esize, x.exponent)
export decode_exp


#a couple of really dumb ones, but we'll put these in for legibility.
is_ulp(x::Unum) = ((x.flags & UNUM_UBIT_MASK) != 0)
is_exact(x::Unum) = ((x.flags & UNUM_UBIT_MASK) == 0)
is_negative(x::Unum) = ((x.flags & UNUM_SIGN_MASK) != 0)
is_positive(x::Unum) = ((x.flags & UNUM_SIGN_MASK) == 0)
export is_ulp, is_exact, is_negative, is_positive

#a couple of testing conditions
import Base.isnan
function isnan{ESS,FSS}(x::Unum{ESS,FSS})
  (x.fsize == (1 << FSS - 1)) && (x.esize == (1 << ESS - 1)) && is_ulp(x) && (x.fraction == fillbits(-(1 << FSS), uint16(length(x.fraction)))) && (x.exponent == mask(1 << ESS))
end
export isnan

import Base.isinf
import Base.isfinite
#isinf matches the julia definiton and triggers on either positive or negative
#infinity.  is_pos_inf and is_neg_inf both are Unum-specific functions that detect
#the expected values.
isinf{ESS,FSS}(x::Unum{ESS,FSS}) = is_exact(x) && (x.esize == 1 << ESS - 1) && (x.exponent == mask(1 << ESS)) && (x.fsize == 1 << FSS - 1) && (x.fraction == fillbits(-(1 << FSS), uint16(length(x.fraction))))
is_pos_inf{ESS, FSS}(x::Unum{ESS, FSS}) = is_positive(x) && isinf(x)
is_neg_inf{ESS, FSS}(x::Unum{ESS, FSS}) = is_negative(x) && isinf(x)
#caution, isfinite is a rather slow algorithm
isfinite{ESS,FSS}(x::Unum{ESS,FSS}) = (x.exponent != mask(1 << ESS)) || (x.fraction != fillbits(-1 << FSS, uint16(length(x.fraction))))
export isinf, is_pos_inf, is_neg_inf, isfinite

import Base.issubnormal
#NB:  The difference between "isexpzero" and "issubnormal" - isexpzero admits
#zero as a solution; issubnormal is in compliance with the standard julia
#issubnormal function and does not admit zero as a true result.
issubnormal{ESS,FSS}(x::Unum{ESS,FSS}) = (x.exponent == z64) && ((ESS > 6) ? !(allzeros(x.fraction)) : x.fraction != 0)
isexpzero{ESS,FSS}(x::Unum{ESS,FSS}) = x.exponent == z64
is_strange_subnormal{ESS,FSS}(x::Unum{ESS,FSS}) = isexpzero(x) && (x.esize < max_esize(ESS))

#use ESS because this will be checked by the compiler, instead of at runtime.
isfraczero{ESS,FSS}(x::Unum{ESS,FSS}) = (ESS > 6) ? allzeros(x.fraction) : (x.fraction == 0)

iszero(x::Unum) = (x.exponent == z64) && is_exact(x) && isfraczero(x)
isone(x::Unum) = (decode_exp(x) == 0) && isfraczero(x)
#checks if the value is small subnormal
is_ssn(x::Unum) = (x.exponent == z64) && is_ulp(x) && isfraczero(x)
is_pos_ssn(x::Unum) = is_positive(x) && is_ssn(x)
is_neg_ssn(x::Unum) = is_negative(x) && is_ssn(x)
#checks if the value is more than maxreal
is_mmr{ESS,FSS}(x::Unum{ESS,FSS}) = is_ulp(x) && (x.exponent == mask(1 << ESS)) && (x.fraction == fillbits(-(1 << FSS - 1), uint16(length(x.fraction))))
is_pos_mmr(x::Unum) = is_positive(x) && is_mmr(x)
is_neg_mmr(x::Unum) = is_negative(x) && is_mmr(x)

export issubnormal, isexpzero
export isfraczero, iszero, is_ssn, is_pos_ssn, is_neg_ssn
export is_mmr, is_pos_mmr, is_neg_mmr
