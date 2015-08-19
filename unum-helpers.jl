#unum-helpers.jl
#helper functions for the unum constructor, and functions that will frequently
#be used with the constructor.

###########################################################
#Utility functions

#fractrim:  Takes a superint value and returns a triplet: (fraction, fsize, ubit)
#this triplet represents the fraction SuperInt trimmed to fsize, a new fsize,
#in the case that it's exact and some zeros can be trimmed, and whether or not
#ubit needs to be thrown (were there values cast out by fsize)?
function __frac_trim(frac::SuperInt, fsize::Uint16)
  #create the fsize mask.
  high_mask = fillbits(-(fsize + 1))  #remember, the real fsize is fsize + 1
  low_mask = ~high_mask
  #do we need to set decide if we need to set the ubit
  #mask out the high bits and check to see if what remains is zero.
  #this needs to be in an array because that will collapse to the appropriate
  #one-dimensional array in the array case and collapse to a one-element array
  #in the single case, so that matches with the zeros() directive.
  ubit = ([low_mask & frac] == zeros(Uint64, length(frac))) ? 0 : UNUM_UBIT_MASK
  #mask out the low bits and save that as the fraction.
  frac &= high_mask
  #we may need to trim the fraction further, in whic case we alter fsize
  fsize = (ubit == 0) ? fsize = (frac.length << 6) - lsb(frac) : fsize
  (frac, fsize, ubit)
end

#match the fraction to fss, setting the ubit if digits were thrown out in the
#process of trimming to fraction.
function __frac_match(frac::SuperInt, fss::Integer)
  flength = length(frac)
  words = __frac_words(fss)
  #create an appropriate superint
  resultfrac = zeros(Uint64, words)
  if (flength < words)
    #fill the remainder of resultfrac with data from frac
    resultfrac[words - flength + 1:words] = frac
    #trim it if necessary.
    (frac, __, ubit) = __frac_trim(frac, max_fsize(fss))
  else
    #mirror the previous process
    resultfrac = frac[flength - words + 1:flength]
    ubit = (frac[1:flength - words] == zeros(Uint64, flength - words)) ? 0 : UNUM_UBIT_MASK
    if (ubit == 0)
      (frac, __, ubit) = __frac_trim(frac, max_fsize(fss))
    else
      #match the
      (frac, __, ___) = __frac_trim(frac, max_fsize(fss))
    end
  end
  (frac, ubit)
end

#calculates how many words of fraction are necessary to support a certain fss
__frac_words(fss::Integer) = fss < 6 ? 1 : (1 << (fss - 6))


################################################################################
# EXPONENT ENCODING AND DECODING

#encodes an exponent as a biased 2-tuple (esize, exponent)
#remember msb is zero-indexed, but outputs a zero for the zero value
function encode_exp(unbiasedexp::Integer)
  esize = (unbiasedexp == 0) ? z16 : uint16(msb(abs(unbiasedexp)) + 1)
  (esize, uint64(unbiasedexp + 2^esize))
end
#the inverse operation is finding the unbiased exponent of an Unum.
decode_exp(esize::Uint16, exponent::Uint64) = int(exponent) - (1 << esize)
#maxfsize returns the the maximum fraction size for a given FSS.
max_fsize(FSS) = (1 << (FSS + 1)) - 1
