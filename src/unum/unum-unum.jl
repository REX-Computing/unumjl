#unum-unum.jl

#contains information about the unum type and helper functions directly related to constructor.

#the unum type is an abstract type.  We'll be overloading the call function later
#so we can do "pseudo-constructions" on this type.

abstract Unum{ESS, FSS} <: Utype

type UnumSmall{ESS, FSS} <: Unum{ESS, FSS}
  fsize::UInt16
  esize::UInt16
  flags::UInt16
  fraction::UInt64
  exponent::UInt64
  function UnumSmall(fsize, esize, flags, fraction, exponent)
    __check_unum_param_dev(ESS, FSS, fsize, esize, fraction, exponent)
    new(fsize, esize, flags, fraction, exponent)
  end
end

#copy constructor
UnumSmall{ESS,FSS}(x::UnumSmall{ESS,FSS}) = UnumSmall{ESS,FSS}(x.fsize, x.esize, x.flags, x.fraction, x.exponent)
UnumSmall{ESS,FSS}(x::UnumSmall{ESS,FSS}, flags::UInt16) = UnumSmall{ESS,FSS}(x.fsize, x.esize, flags, x.fraction, x.exponent)

type UnumLarge{ESS, FSS} <: Unum{ESS, FSS}
  fsize::UInt16
  esize::UInt16
  flags::UInt16
  fraction::Array{UInt64}
  exponent::UInt64
  function UnumLarge(fsize, esize, flags, fraction, exponent)
    __check_unum_param_dev(ESS, FSS, fsize, esize, fraction, exponent)
    new(fsize, esize, flags, fraction, exponent)
  end
end

#copy constructor
UnumLarge{ESS,FSS}(x::UnumSmall{ESS,FSS}) = UnumLarge{ESS,FSS}(x.fsize, x.esize, x.flags, x.fraction, x.exponent)
UnumLarge{ESS,FSS}(x::UnumSmall{ESS,FSS}, flags::UInt16) = UnumLarge{ESS,FSS}(x.fsize, x.esize, flags, x.fraction, x.exponent)

#override call to allow direct instantiation using the Unum{ESS,FSS} pseudo-constructor.
function call{ESS, FSS}(::Type{Unum{ESS,FSS}}, fsize::UInt16, esize::UInt16, flags::UInt16, fraction::UInt64, exponent::UInt64)
  (FSS > 6) && throw(ArgumentError("FSS = $FSS > 6 requires an UInt64 array"))
  (ESS > 6) && throw(ArgumentError("ESS = $ESS > 6 currently not allowed."))
  UnumSmall{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end

function call{ESS,FSS}(::Type{Unum{ESS, FSS}}, fsize::UInt16, esize::UInt16, flags::UInt16, fraction::Array{UInt64}, exponent::UInt64)
  (ESS > 6) && throw(ArgumentError("ESS = $ESS > 6 currently not allowed."))
  (FSS > 11) && throw(ArgumentError("FSS = $FSS > 11 currently not allowed"))
  (FSS < 7) && throw(ArgumentError("FSS = $FSS < 7 should be passed a single Uint64"))
  #calculate the number of cells that fraction will have.
  frac_length = length(fraction)
  need_length = 1 << (FSS - 6)
  (frac_length < need_length) && throw(ArgumentError("insufficient array elements to create unum with desired FSS ($FSS requires $need_length > $frac_length)"))
  UnumLarge{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end

#the "unum" constructor is a safe, pruning constructor.
#note that the first argument to the is pseudo-constructor must be a type value
#that relays the environment signature for the desired unum.

function unum{ESS,FSS}(::Type{Unum{ESS,FSS}}, fsize::UInt16, esize::UInt16, flags::UInt16, fraction, exponent::UInt64)
  #checks to make sure everything is safe.
  __check_unum_param(ESS, FSS, fsize, esize, fraction, exponent)

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
unum{ESS,FSS}(x::Unum{ESS,FSS}, subflags::UInt16) = unum(Unum{ESS,FSS}, x.fsize, x.esize, subflags, x.fraction, x.exponent)

#an "easy" constructor which is safe, and takes an unbiased exponent value, and
#a superint value
function unum_easy{ESS,FSS}(::Type{Unum{ESS,FSS}}, flags::UInt16, fraction, exponent::Int)
  #decode the exponent
  (esize, exponent) = encode_exp(exponent)
  #match the length of fraction to FSS, set the ubit if there's trimming that
  #had to be done.
  (fraction, ubit) = __frac_match(fraction, FSS)
  #let's be lazy about the fsize.  The safe unum pseudoconstructor will
  #handle trimming that down.
  fsize = max_fsize(FSS)
  unum(Unum{ESS,FSS}, fsize, esize, flags, fraction, exponent)
end
export unum, unum_easy


#masks for the unum flags variable.
const UNUM_SIGN_MASK = UInt16(0x0002)
const UNUM_UBIT_MASK = UInt16(0x0001)
const UNUM_FLAG_MASK = UInt16(0x0003)
#nb: in the future we may implement g-layer shortcuts:
#in our implementation, these values are sufficient criteria they describe
#are true.  If these flags are not set, further checks must be done.
const UNUM_NAN__MASK = UInt16(0x8000)
const UNUM_ZERO_MASK = UInt16(0x4000)
const UNUM_INF__MASK = UInt16(0x2000)
const UNUM_NINF_MASK = UInt16(0x1000)
const UNUM_SSS__MASK = UInt16(0x0800)
const UNUM_SHORTCUTS = UInt16(0xF800)
