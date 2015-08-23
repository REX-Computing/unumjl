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

  if (x.flags & UBIT_MASK == UBIT_MASK)

    _sub_x = issubnormal(x) ? 0 : 1
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
    fsize = (fraction == 0) ? z16 : uint16(63 - lsb(fraction))

  else
    throw(ArgumentError("not yet"))
    #but, when we do it, we will add the single bit in and then use our friendly
    #carry machine.
  end

  Unum{ess,fss}(fsize, x.esize, x.flags & ~UBIT_MASK, fraction, exponent)
end
function prevunum(x::Unum)
end
function nextulp{ESS,FSS}(x::Unum{ESS,FSS})
  #check to see if we're an ulp
  if (x.flags & UBIT_MASK == UBIT_MASK)
    throw(ArgumentError("nextulp only works on exact unums"))
  end
  if !isfinite(x)
    throw(ArgumentError("nextulp doesn't work on infinite unums"))
  end
  #literally just turn on the ulp bit
  xp = unum(x)
  xp.flags |= UBIT_MASK
  xp
end

function prevulp{ESS,FSS}(x::Unum{ESS,FSS})
  #check to see if we're an ulp.
  if (x.flags & UBIT_MASK == UBIT_MASK)
    throw(ArgumentError("prevulp only works on exact unums"))
  end
  #check to make sure we aren't zero.
  if iszero(x)
    throw(ArgumentError("prevulp doesn't work on zero"))
  end
  scratchpad = x.fraction - t64 >> x.fsize
  xp = unum(x)
  xp.flags |= UBIT_MASK
  #check if we're subnormal
  if x.exponent == 0
    xp.fraction = scratchpad
  elseif scratchpad > x.fraction
    #check for carry loss.
    if xp.exponent == 1
      #do nothing.
      xp.fraction = scratchpad
      xp.exponent = 0
      xp.esize = 0
    else
      #shift over one.
      xp.fraction = scratchpad >> 1
      xp.fsize -= 1
      (xp.esize, xp.exponent) = encode_exp(decode_exp(xp) - 1)
    end
  end
  xp
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
  Unum{ess,fss}(uint16(2^fss - 1), uint16(2^ess-1), uint16(0b1), fillbits(-2^fss), mask(2^ess))
end
function nan!{ESS,FSS}(::Type{Unum{ESS,FSS}}) #for when you just need the noisy NaN
  Unum{ESS,FSS}(uint16(2^FSS - 1), uint16(2^ESS-1), uint16(0b11), fillbits(-2^FSS), mask(2^ESS))
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
  Unum{ess,fss}(uint16(2^fss - 1), uint16(2^ess-1), x.flags | UBIT_MASK, fillbits(-(2^fss-1)), mask(2^ess))
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
function fwords{ESS,FSS}(::Type{Unum{ESS,FSS}})
  (2 << (fsize - 6)) + 1
end
function isnan(x::Unum)
  fss = fsizesize(x)
  ess = esizesize(x)
  (x.fsize == (1 << fss - 1)) && (x.esize == (1 << ess - 1)) && (x.flags == 0b1) && (x.fraction == fillbits(-(1 << fss))) && (x.exponent == mask(1 << ess))
end
function isfinite(x::Unum)
  (x.fraction != fillbits(-2^fsizesize(x))) || (x.exponent != mask(2^esizesize(x)))
end

ispinf(x::Unum) = (x.flags & UNUM_SIGN_MASK == 0) && (x.exponent == mask(1 << esizesize(x))) && (x.fraction == fillbits(-(1 << fsizesize(x))))
isninf(x::Unum) = (x.flags & UNUM_SIGN_MASK != 0) && (x.exponent == mask(1 << esizesize(x))) && (x.fraction == fillbits(-(1 << fsizesize(x))))

function issubnormal(x::Unum)
  x.exponent == 0
end
function isfraczero(x::Unum)
  reduce((b, i) -> b && (i == zero(Uint64)), true, x.fraction)
end
#iszeroish checks to see if it's infinitesimal or if it's zero.
function iszeroish(x::Unum)
  fwords = length(x.fraction)
  x.fraction == ((fwords == 1) ? z64 : zeros(fwords)) && (x.exponent == z64)
end
function iszero(x::Unum)
  fwords = length(x.fraction)
  (x.fraction == ((fwords == 1) ? z64 : zeros(fwords))) && (x.exponent == z64) && ((x.flags & UNUM_UBIT_MASK) == 0)
end
function isinfinitesimal(x::Unum)
  fwords = length(x.fraction)
  (x.fraction == ((fwords == 1) ? z64 : zeros(fwords))) && (x.exponent == z64) && ((x.flags & UNUM_UBIT_MASK) != 0)
end
function isalmostinf(x::Unum)
  fwords = length(x.fraction)
  (x.fraction == fillbits(-(2^fsizesize(x) - 1))) && (x.exponent == mask(2^esizesize(x))) && ((x.flags & UNUM_UBIT_MASK) != 0)
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
