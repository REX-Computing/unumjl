#unum-unum.jl

#contains information about the unum type and some basic helper functions.

immutable Unum{ESS, FSS} <: Real
  fsize::Uint16
  esize::Uint16
  flags::Uint16
  fraction::SuperInt
  exponent::Uint64  #realistically, we won't need huge exponents

  #inner constructor makes sure that the fsize and esize agree with the fsizesize
  #and esizesize environment, and the fraction and exponent.  note the resulting
  #constructor in general will be an UNSAFE constructor.
  #currently for debugging purposes it performs four checks:
  #
  #1) is the FSS OK?
  #2) is the ESS OK?
  #3) is exponent appropriate for ESS?
  #3) is the SuperInt of the correct size for ESS?
  #
  # In the future, these checks will be pushed to the safe unum (lower case)
  # constructor and we may decide to make these checks conditional on a
  # development environment variable, for performance purposes.
  #
  # the Unum constructor, then should ONLY be used when you have assurance that
  # the unum is safe (as in within the g-layer of any given calculation)

  function Unum(fsize::Uint16, esize::Uint16, flags::Uint16, fraction::SuperInt, exponent::Uint64)
    #check to make sure fsize is within FSS, esize within ESS

    ##TEMPORARY CHECK BLOCK
    if (fsize >= 1 << FSS)
      println(STDERR, "$(fsize) too big for $(FSS)")
      throw(TypeError)
    end
    if (esize >= 1 << ESS)
      println(STDERR, "$(esize) too big for $(ESS)")
      throw(TypeError)
    end
    if (exponent >= (1 << esize))
      println(STDERR, "$(exponent) too big for $(esize)")
      throw(TypeError)
    end
    if (length(frac) != fracwords(FSS))
      println(STDERR, "size mismatch between supplied fraction array $(length(frac)) and expected $(fracwords(ESS))")
      throw(TypeError)
    end
    ##END TEMPORARY CHECK BLOCK

    new(fsize, esize, flags, fraction, exponent)
  end
end

#the "unum" constructor is a safe, pruning constructor.
#note that the first argument to the is pseudo-constructor must be a type value
#that relays the environment signature for the desired unum.
function unum{ESS,FSS}(::Type{Unum{ESS,FSS}}, fsize::Uint16, esize::Uint16, flags::Uint16, fraction::SuperInt, exponent::Uint64)
  #checks to make sure everything is safe.
  if (fsize >= 1 << FSS)
    println(STDERR, "$(fsize) too big for $(FSS)")
    throw(TypeError)
  end
  if (esize >= 1 << ESS)
    println(STDERR, "$(esize) too big for $(ESS)")
    throw(TypeError)
  end
  if (exponent >= (1 << esize))
    println(STDERR, "$(exponent) too big for $(esize)")
    throw(TypeError)
  end
  if (length(frac) != fracwords(FSS))
    println(STDERR, "size mismatch between supplied fraction array $(length(frac)) and expected $(fracwords(FSS))")
    throw(TypeError)
  end

  #mask out values outside of the flag range.
  flags &= UNUM_FLAG_MASK

  #trim fraction to the length of fsize.  Return the trimmed fsize value and
  #ubit, if appropriate.
  (fraction, fsize, ubit) = __frac_trim(fraction, fsize)
  #apply the ubit change.
  flags |= ubit

  #generate the new Unum.
  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end

#unum copy pseudo-constructor, safe version
unum{ESS,FSS}(x::Unum{ESS,FSS}) = unum(Unum{ESS,FSS}, x.fsize, x.esize, x.flags, x.fraction, x.exponent)
#and a unum copy that substitutes the flags
unum{ESS,FSS}(x::Unum{ESS,FSS}, subflags::Uint16) = unum(Unum{ESS,FSS}, x.fsize, x.esize, subflags, x.fraction, x.exponent)

#unum copy constructor, unsafe version
unum_unsafe{ESS,FSS}(x::Unum{ESS,FSS}) = Unum{ESS,FSS}(x.fsize, x.esize, x.flags, x.fraction, x.exponent)
#substituting flags
unum_unsafe{ESS,FSS}(x::Unum{ESS,FSS}, subflags::Uint16) = Unum{ESS,FSS}(x.fsize, x.esize, subflags, x.fraction, x.exponent)

#an "easy" constructor which is safe, and takes an unbiased exponent value, and
#a superint value
function unum_easy{ESS,FSS}(::Type{Unum{ESS,FSS}}, flags::Uint16, exponent::Int16, fraction::SuperInt)
  #decode the exponent
  (esize, exponent) = encode_exp(exponent)
  #match the length of fraction to FSS, set the ubit if there's trimming that
  #had to be done.
  (fraction, ubit) = __frac_match(fraction, FSS)
  #let's be lazy about the fsize.  The safe unum pseudoconstructor will
  #handle trimming that down.
  fsize = uint16(min(length(fraction) * 64, (1 << (FSS + 1)) - 1))
  unum(Unum{ESS,FSS}, fsize, esize, flags, fraction, exponent)
end

#masks for the unum flags variable.
const UNUM_SIGN_MASK = uint16(0x0002)
const UNUM_UBIT_MASK = uint16(0x0001)
const UNUM_FLAG_MASK = uint16(0x0003)
#nb: in the future we may implement g-layer shortcuts:
#in our implementation, these values are sufficient criteria they describe
#are true.  If these flags are not set, further checks must be done.
const UNUM_NAN__MASK = uint16(0x8000)
const UNUM_ZERO_MASK = uint16(0x4000)
const UNUM_INF__MASK = uint16(0x2000)
const UNUM_NINF_MASK = uint16(0x1000)
const UNUM_SSN__MASK = uint16(0x0800)
const UNUM_SHORTCUTS = uint16(0xF800)
