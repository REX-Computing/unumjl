#unum-unum.jl

#contains information about the unum type and some basic helper functions.

type Unum{ESS, FSS} <: Real
  fsize::Uint16
  esize::Uint16
  flags::Uint16
  fraction::SuperInt
  exponent::Uint64  #realistically, we won't need huge exponents

  #inner constructor makes sure that the fsize and esize agree with the fsizesize
  #and esizesize environment, and the fraction and exponent
  function Unum(fsize::Uint16, esize::Uint16, flags::Uint16, frac::SuperInt, exp::Uint64)
    #check to make sure fsize is within FSS, esize within ESS
    if (fsize >= 2 ^ FSS)
      println("$(fsize) too big for $(FSS)")
      throw(TypeError)
    end
    if (esize >= 2 ^ ESS)
      println("$(esize) too big for $(ESS)")
      throw(TypeError)
    end
    #mask the flags to eliminate irrelevant data.
    flags &= 0b11

    fracwords = int(ceil((2 ^ FSS) / 64))

    #next initialize fraction arrays.
    fraction = fractrim(frac, fsize, fracwords)
    #to initialize the esize array, you MUST pass a vector of int64s that has
    #the correct size (or less)
    exponent = exp

    new(fsize, esize, flags, fraction, exponent)
  end
end

function unum{ESS,FSS}(x::Unum{ESS,FSS})
  Unum{ESS,FSS}(x.fsize, x.esize, x.flags, x.fraction, x.exponent)
end

#and a unum copy that substitutes the flags
function unum{ESS,FSS}(x::Unum{ESS,FSS}, subflags::Uint16)
  Unum{ESS,FSS}(x.fsize, x.esize, subflags, x.fraction, x.exponent)
end
