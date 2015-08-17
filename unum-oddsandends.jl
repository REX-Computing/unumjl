#unum-oddsandends.jl
#mathematical odds and ends

#literally calculate the value of the Unum.  Please don't use this for Infs and NaNs

function calculate(x::Unum)
  #the sub`normal case
  if (x.exponent == 0)
    2.0^(x.exponent - 2.0^(x.esize) + 1) * (big(x.fraction) / 2.0^64)
  else #the normalcase
    2.0^(x.exponent - 2.0^(x.esize)) * (1 + big(x.fraction) / 2.0^64)
  end
end

#sorts two unums by magnitude (distance from zero), and throws in the calculated
#exponents, while we're at it.
function magsort(a, b)
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)

  if (_aexp < _bexp)                #first parse through the exponents
    (b, a, _bexp, _aexp)
  elseif (_aexp > _bexp)
    (a, b, _aexp, _bexp)
  elseif (a.fraction < b.fraction)  #then parse through the fractions
    (b, a, _bexp, _aexp)
  elseif (a.fraction > b.fraction)
    (a, b, _aexp, _bexp)
  elseif (isulp(a) && !isulp(b))
    (a, b, _aexp, _bexp)
  else
    (b, a, _bexp, _aexp)
  end
end

function isnegative(x::Unum)
  return (x.flags & 0b10 == 0b10)
end
export isnegative

import Base.floor
import Base.ceil
import Base.round
function floor(x::Unum)
end
function ceil(x::Unum)
end
function round(x::Unum)
end
export floor
export ceil
export round
