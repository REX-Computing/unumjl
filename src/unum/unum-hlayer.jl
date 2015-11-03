#unum-hlayer.jl - human layer things in the unum library.

import Base.bits
function describe{ESS,FSS}(x::Unum{ESS, FSS})
  dstring = is_ulp(x) ? string(calculate(prev_exact(x)), " -> ", calculate(next_exact(x))) : string("exact ", calculate(x))
  is_pos_mmr(x) && (dstring = "mmr{$ESS, $FSS}")
  is_neg_mmr(x) && (dstring = "-mmr{$ESS, $FSS}")
  is_pos_sss(x) && (dstring = "sss{$ESS, $FSS}")
  is_neg_sss(x) && (dstring = "-sss{$ESS, $FSS}")

  string(bits(x, " "), " (aka ", dstring, ")")
end

###NOTE THIS NEEDS TO BE FIXED


function bits{ESS,FSS}(x::Unum{ESS,FSS}, space::ASCIIString = "")
  res = ""
  for idx = 0:FSS - 1
    res = string((x.fsize >> idx) & 0b1, res)
  end
  res = string(space, res)
  for idx = 0:ESS - 1
    res = string((x.esize >> idx) & 0b1, res)
  end
  res = string(space, x.flags & 0b1, space, res)
  tl = length(x.fraction) * 64 - 1
  for idx = (tl-x.fsize):tl
    res = string(bits(x.fraction), res)
  end
  res = string(space, res)
  for idx = 0:x.esize
    res = string(((x.exponent[integer(ceil((idx + 1) / 64))] >> (idx % 64)) & 0b1), res)
  end
  res = string((x.flags & 0b10) >> 1, space, res)
  res
end
export bits

import Base.show
#function show(io::IO, value::Unum)
  #for now, just punt to describe.  Eventually we'll make a decimal converter.
#  print(io, "$describe(value)")
#end
export show
