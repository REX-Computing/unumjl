#unum-properties

#unum type properties
#typemax and typemin should report infinities
import Base.typemax
typemax{ESS,FSS}(::Type{Unum{ESS,FSS}}) = pinf(Unum{ESS,FSS})
export typemax
maxreal{ESS,FSS}(::Type{Unum{ESS,FSS}}) = Unum{ESS,FSS}(uint16(2^FSS-1), uint16(2^ESS-1), z16, fillbits(-2^FSS + 1), uint64(2^2^ESS - 1))
export maxreal

import Base.typemin
typemin{ESS,FSS}(::Type{Unum{ESS,FSS}}) = ninf(Unum{ESS,FSS})
export typemin
minreal{ESS,FSS}(::Type{Unum{ESS,FSS}}) = Unum{ESS,FSS}(uint16(2^FSS-1), uint16(2^ESS-1), SIGN_MASK, fillbits(-2^FSS + 1), uint64(2^2^ESS - 1))
export minreal

#machine epsilon
import Base.eps
#find the next unum after the number one.
function eps{ESS,FSS}(::Type{Unum{ESS,FSS}})
end
#find the next unum after any given number.
#conveniently also is the width of the ubound adjacent, represented there.
function eps(x::Unum)
end
export eps

#nextfloat, prevfloat
import Base.nextfloat
import Base.prevfloat
function nextfloat(x::Unum)
end
function prevfloat(x::Unum)
end
#nextunum and prevunum are slightly different, they output the next scaled to
#the current specificity.
function nextunum(x::Unum)
  ess = esizesize(x)
  fss = fsizesize(x)

  if (x.flags & UNUM_UBIT_MASK == UNUM_UBIT_MASK)

    _sub_x::Uint64 = issubnormal(x) ? z64 : o64
    (carry, fraction) = __carried_add(_sub_x, x.fraction, (t64 >> x.fsize))

    #table of conditions
    # started subnormal?  |  carry value?  | delta-exp
    # 0                   |  0             | 0
    # 0                   |  1             | 1
    # 1                   |  1             | 0
    # 1                   |  2             | 1
    # delta-exp = carry - _sub_x
    exponent = uint64(x.exponent + carry - _sub_x)
    #change the number of fraction bits to get the best representation
    fsize = (fraction == 0) ? z16 : uint16(63 - ctz(fraction))

  else
    throw(ArgumentError("not yet"))
    #but, when we do it, we will add the single bit in and then use our friendly
    #carry machine.
  end

  Unum{ess,fss}(fsize, x.esize, x.flags & ~UNUM_UBIT_MASK, fraction, exponent)
end
function prevunum(x::Unum)
end
function nextulp{ESS,FSS}(x::Unum{ESS,FSS})
  #check to see if we're an ulp
  if (x.flags & UNUM_UBIT_MASK == UNUM_UBIT_MASK)
    throw(ArgumentError("nextulp only works on exact unums"))
  end
  if !isfinite(x)
    throw(ArgumentError("nextulp doesn't work on infinite unums"))
  end
  #literally just turn on the ulp bit
  unum_unsafe(x, x.flags | UNUM_UBIT_MASK)
end

function prevulp{ESS,FSS}(x::Unum{ESS,FSS})
  #check to see if we're an ulp.
  if (x.flags & UNUM_UBIT_MASK == UNUM_UBIT_MASK)
    throw(ArgumentError("prevulp only works on exact unums"))
  end
  #check to make sure we aren't zero.
  if iszero(x)
    throw(ArgumentError("prevulp doesn't work on zero"))
  end
  scratchpad = x.fraction - t64 >> x.fsize
  flags = x.flags | UNUM_UBIT_MASK
  #check if we're subnormal
  if x.exponent == 0
    fraction = scratchpad
    exponent = x.exponent
    esize = x.esize
    fsize = x.fsize
  elseif scratchpad > x.fraction
    #check for carry loss.
    if x.exponent == 1
      #do nothing.
      fraction = scratchpad
      exponent = z64
      esize = z16
      fsize = x.fsize
    else
      #shift over one.
      fraction = scratchpad >> 1
      fsize = uint16(x.fsize - 1)
      (esize, exponent) = encode_exp(decode_exp(xp) - 1)
    end
  else
    fsize = x.fsize
    esize = x.esize
    exponent = x.exponent
    fraction = scratchpad
  end

  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end
export nextfloat
export prevfloat
export nextunum
export prevunum
export nextulp
export prevulp

#NaN's and Inf's (plural'd abbreviations take apostrophes!)
function nan(x::Unum)
  ess = esizesize(x)
  fss = fsizesize(x)
  Unum{ess,fss}(uint16(2^fss - 1), uint16(2^ess-1), uint16(0b1), fillbits(-(1 << fss), __frac_cells(fss)), mask(1 << ess))
end
function nan!{ESS,FSS}(::Type{Unum{ESS,FSS}}) #for when you just need the noisy NaN
  Unum{ESS,FSS}(uint16(2^FSS - 1), uint16(2^ESS-1), uint16(0b11), fillbits(-(1 << FSS), __frac_cells(FSS)), mask(1 << ESS))
end

function almostpinf{ESS,FSS}(::Type{Unum{ESS,FSS}})
  Unum{ESS,FSS}(uint16(2^FSS - 1), uint16(2^ESS-1), UBIT_MASK, fillbits(-(2^FSS-1)), mask(2^ESS))
end
function almostninf{ESS,FSS}(::Type{Unum{ESS,FSS}})
  Unum{ESS,FSS}(uint16(2^FSS - 1), uint16(2^ESS-1), UBIT_MASK | SIGN_MASK, fillbits(-(2^FSS-1)), mask(2^ESS))
end
#almostinf takes the sign of whatever you're passing it.
function almostinf(x::Unum)
  ess = esizesize(x)
  fss = fsizesize(x)
  Unum{ess,fss}(uint16(2^fss - 1), uint16(2^ess-1), x.flags | UNUM_UBIT_MASK, fillbits(-(2^fss-1)), mask(2^ess))
end
export nan
export nan!
export pinf
export ninf
export almostpinf
export almostninf
export almostinf

decode_exp(x::Unum) = decode_exp(x.esize, x.exponent)
export decode_exp

#a couple of testing conditions
import Base.isnan
import Base.isfinite
import Base.issubnormal

function isnan(x::Unum)
  fss = fsizesize(x)
  ess = esizesize(x)
  (x.fsize == (1 << fss - 1)) && (x.esize == (1 << ess - 1)) && (x.flags == 0b1) && (x.fraction == fillbits(-(1 << fss), uint16(length(x.fraction)))) && (x.exponent == mask(1 << ess))
end

function isfinite(x::Unum)
  (x.fraction != fillbits(-1 << fsizesize(x), uint16(length(x.fraction)))) || (x.exponent != mask(1 << esizesize(x)))
end

ispinf(x::Unum) = (x.flags & UNUM_SIGN_MASK != 0) && (x.exponent == mask(1 << esizesize(x))) && (x.fraction != fillbits(-(1 << fsizesize(x)),uint16(length(x.fraction))))
isninf(x::Unum) = (x.flags & UNUM_SIGN_MASK != 0) && (x.exponent == mask(1 << esizesize(x))) && (x.fraction == fillbits(-(1 << fsizesize(x)),uint16(length(x.fraction))))

function issubnormal(x::Unum)
  x.exponent == 0
end
function isfraczero(x::Unum)
  reduce((b, i) -> b && (i == zero(Uint64)), true, x.fraction)
end
#iszeroish checks to see if it's infinitesimal or if it's zero.
function iszeroish(x::Unum)
  fwords::Uint16 = length(x.fraction)
  x.fraction == ((fwords == 1) ? z64 : zeros(fwords)) && (x.exponent == z64)
end
function iszero(x::Unum)
  fwords= length(x.fraction)
  (x.fraction == ((fwords == 1) ? z64 : zeros(fwords))) && (x.exponent == z64) && ((x.flags & UNUM_UBIT_MASK) == 0)
end
function isinfinitesimal(x::Unum)
  fwords::Uint16 = length(x.fraction)
  (x.fraction == ((fwords == 1) ? z64 : zeros(fwords))) && (x.exponent == z64) && ((x.flags & UNUM_UBIT_MASK) != 0)
end
function isalmostinf(x::Unum)
  fwords::Uint16 = length(x.fraction)
  (x.fraction == fillbits(-(1 << fsizesize(x) - 1), fwords)) && (x.exponent == mask(1 << esizesize(x))) && ((x.flags & UNUM_UBIT_MASK) != 0)
end
function isalmostpinf(x::Unum)
  isalmostinf(x) && (x.flags == UNUM_UBIT_MASK)
end
function isalmostninf(x::Unum)
  isalmostinf(x) && (x.flags == (UNUM_UBIT_MASK | UNUM_SIGN_MASK))
end
function isulp(x::Unum)
  ((x.flags & UNUM_UBIT_MASK) != 0)
end
export isnan
export isfinite
export ispinf
export isninf
export issubnormal
export isinfinitesimal
export isalmostinf
export isalmostpinf
export isalmostninf
export isulp
export iszero
