#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
#unum-unum.jl

#contains information about the unum type and helper functions directly related to constructor.

function __check_block_unum(ESS, FSS, fsize, esize, fraction, exponent)
  fsize < (1 << FSS)              || throw(ArgumentError("fsize $(fsize) too big for FSS $(FSS)"))
  esize < (1 << ESS)              || throw(ArgumentError("esize $(esize) too big for ESS $(ESS)"))

  #when you have esize == 63 ALL THE VALUES ARE VALID, but bitshift op will do something strange.
  ((esize == 63) || exponent < (1 << (esize + 1))) || throw(ArgumentError("exponent $(exponent) too big for esize $(esize)"))
  length(fraction) == __frac_cells(FSS) || throw(ArgumentError("size mismatch between supplied fraction array $(length(fraction)) and expected $(__frac_cells(FSS))"))
end


immutable Unum{ESS, FSS} <: Utype
  fsize::UInt16
  esize::UInt16
  flags::UInt16
  fraction::SuperInt
  exponent::UInt64  #realistically, we won't need huge exponents

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
  # the Unum constructor, then should ONLY be used when you have assurance that
  # the unum is safe (as in within the g-layer of any given calculation)

  function Unum(fsize::UInt16, esize::UInt16, flags::UInt16, fraction::SuperInt, exponent::UInt64)
    #check to make sure fsize is within FSS, esize within ESS
    if (__unum_isdev())
      __check_block_unum(ESS, FSS, fsize, esize, fraction, exponent)
    end

    #because fraction could be assigned an existing array, we should do a safe copy.
    if (__frac_cells(ESS) == 1)
      temp_fraction = fraction
    else
      temp_fraction = zeros(UInt64, length(fraction))
      temp_fraction[:] = fraction
    end

    new(fsize, esize, flags, temp_fraction, exponent)
  end
end

#the "unum" constructor is a safe, pruning constructor.
#note that the first argument to the is pseudo-constructor must be a type value
#that relays the environment signature for the desired unum.
function unum{ESS,FSS}(::Type{Unum{ESS,FSS}}, fsize::UInt16, esize::UInt16, flags::UInt16, fraction::SuperInt, exponent::UInt64)
  #checks to make sure everything is safe.
  __check_block_unum(ESS, FSS, fsize, esize, fraction, exponent)

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

#unum copy constructor, unsafe version
unum_unsafe{ESS,FSS}(x::Unum{ESS,FSS}) = Unum{ESS,FSS}(x.fsize, x.esize, x.flags, x.fraction, x.exponent)
#substituting flags
unum_unsafe{ESS,FSS}(x::Unum{ESS,FSS}, subflags::UInt16) = Unum{ESS,FSS}(x.fsize, x.esize, subflags, x.fraction, x.exponent)
unum_unsafe{ESS,FSS}(::Type{Unum{ESS,FSS}}, fsize::UInt16, esize::UInt16, flags::UInt16, fraction::SuperInt, exponent::UInt64) = Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)


#an "easy" constructor which is safe, and takes an unbiased exponent value, and
#a superint value
function unum_easy{ESS,FSS}(::Type{Unum{ESS,FSS}}, flags::UInt16, fraction::SuperInt, exponent::Integer)
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

export unum
export unum_unsafe
export unum_easy

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
const UNUM_sss__MASK = UInt16(0x0800)
const UNUM_SHORTCUTS = UInt16(0xF800)
