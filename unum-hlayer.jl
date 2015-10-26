#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
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
    res = string(bitof(x.fraction, idx) == 0 ? 0 : 1, res)
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
