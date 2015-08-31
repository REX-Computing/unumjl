#unum-helpers.jl
#helper functions for the unum constructor, and functions that will frequently
#be used with the constructor.

###########################################################
#Utility functions

#literally grab the fraction length of a superlength.  No assumptions are made
#about the validity of the trailing bits...  pass l to make it faster.
function __frac_length(frac::SuperInt, l::Integer = length(frac))
  digits::Uint16 = (l << 6) - ctz(frac)
  #all zeroes means you have one zero digit.
  return uint16((digits == 0) ? 0 : digits - 1)
end

#fractrim:  Takes a superint value and returns a triplet: (fraction, fsize, ubit)
#this triplet represents the fraction SuperInt trimmed to fsize, a new fsize,
#in the case that it's exact and some zeros can be trimmed, and whether or not
#ubit needs to be thrown (were there values cast out by fsize)?
function __frac_trim(frac::SuperInt, fsize::Uint16)
  l::Uint16 = length(frac)
  #drop an error if the superint can't accomodate fsize.
  (fsize >= (l << 6)) && throw(ArgumentError("fraction array must accomodate fsize value for __frac_trim"))

  #create the fsize mask.
  high_mask = fillbits(-(fsize + 1), l)  #remember, the real fsize is fsize + 1
  low_mask = ~high_mask
  #do we need to set decide if we need to set the ubit
  #mask out the high bits and check to see if what remains is zero.
  #this needs to be in an array because that will collapse to the appropriate
  #one-dimensional array in the array case and collapse to a one-element array
  #in the single case, so that matches with the zeros() directive.
  ubit = ([low_mask & frac] == zeros(Uint64, l)) ? z16 : UNUM_UBIT_MASK
  #mask out the low bits and save that as the fraction.
  frac &= high_mask
  #we may need to trim the fraction further, in which case we alter fsize.
  #also take the "zero" case and make sure we represent at least one digit.
  fsize = (ubit == 0) ? __frac_length(frac, l) : fsize
  (frac, fsize, ubit)
end

#match the fraction to fss, setting the ubit if digits were thrown out in the
#process of trimming to fraction.
function __frac_match(frac::SuperInt, fss::Integer)
  flength = length(frac)
  cells = __frac_cells(fss)
  temp_frac = zeros(Uint64, cells)
  ubit = zero(Uint16)
  #create an appropriate superint
  if (flength < cells)
    #fill the remainder of resultfrac with data from frac
    temp_frac[cells - flength + 1:cells] = frac
    res = temp_frac
  else
    #mirror the previous process
    temp_frac = [frac][flength - cells + 1:flength]

    #demote from array to integer if cells is one
    (cells == 1) && (temp_frac = temp_frac[1])

    ubit = ([frac][1:flength - cells] == zeros(Uint64, flength - cells)) ? 0 : UNUM_UBIT_MASK
    if (ubit == 0)
      (res, __, ubit) = __frac_trim(temp_frac, max_fsize(fss))
    else
      #trim more, but only for masking purposes.
      (res, __, ___) = __frac_trim(temp_frac, max_fsize(fss))
    end
  end
  (res, ubit)
end

#calculates how many words of fraction are necessary to support a certain fss
__frac_cells(fss::Integer) = uint16(fss < 6 ? 1 : (1 << (fss - 6)))

################################################################################
# EXPONENT ENCODING AND DECODING
#encodes an exponent as a biased 2-tuple (esize, exponent)
#remember msb is zero-indexed, but outputs a zero for the zero value
function encode_exp(unbiasedexp::Integer)
  esize = (unbiasedexp == 0) ? z16 : uint16(64 - clz(uint64(abs(unbiasedexp))))
  (esize, uint64(unbiasedexp + 1 << esize))
end
#the inverse operation is finding the unbiased exponent of an Unum.
decode_exp(esize::Uint16, exponent::Uint64) = int(exponent) - (1 << esize)
#maxfsize returns the the maximum fraction size for a given FSS.
max_fsize(FSS) = uint16((1 << FSS) - 1)
max_esize(ESS) = uint16((1 << ESS) - 1)
max_exponent(ESS) = (1 << (1 << ESS - 1) - 1)
min_exponent(ESS) = -(1 << (1 << ESS - 1) - 1)
