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
  ubit = allzeros(low_mask & frac) ? z16 : UNUM_UBIT_MASK
  #mask out the low bits and save that as the fraction.
  frac &= high_mask
  #we may need to trim the fraction further, in which case we alter fsize.
  #also take the "zero" case and make sure we represent at least one digit.
  fsize = (ubit == 0) ? __fsize_of_exact(frac) : fsize
  (frac, fsize, ubit)
end

#__frac_mask: takes an FSS value and generates the corresponding superint frac_mask.
#generally useful only for FSS values less than 6.
function __frac_mask(fss::Integer)
  (fss < 6) && return fillbits(-(max_fsize(fss) + 1), o16)
  (fss == 6) && return f64
  return [f64 for i=1:__frac_cells(fss)]
end

#takes a peek at the fraction and decides if ubit needs to be set (if the boundary
#is not flush with max_fss), but also decides if fsize_of_exact needs to be set.
function __frac_analyze(fraction::SuperInt, is_ubit::Uint16, fss::Integer)
  #two possibilities:  fss is less than 6 (and the fraction is not on a 64-bit border)
  _mfs::Int16 = max_fsize(fss)
  if (fss < 6)
    #set the high mask
    high_mask::Uint64 = __frac_mask(fss)
    #check if we're already a ubit, then trim to high mask.
    (is_ubit != 0) && return (fraction & high_mask, _mfs, is_ubit)

    #generate the low mask and check it out.
    low_mask::Uint64 = ~high_mask
    is_ubit = (fraction & low_mask != 0) ? UNUM_UBIT_MASK : 0

    fsize = (is_ubit != 0) ? _mfs : __fsize_of_exact(fraction)
    (fraction & high_mask, fsize, is_ubit)
  else
    #we don't need to check for lost bits because when 6 or greater, the fractions
    #are aligned with the 64-bit boundaries.
    (is_ubit != 0) && return (fraction, _mfs, is_ubit)
    (fraction, __fsize_of_exact(fraction), is_ubit)
  end
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

#set the lsb of a superint to 1 based on fss.  This function has undefined
#behavior if the passed superint already has a bit set at this location.
function __set_lsb(a::SuperInt, fss::Integer)
  (fss > 6) && (return a + [o64, zeros(Uint64, __frac_cells(fss) - 1)])
  return a + 1 << (64 - (1 << fss))
end

################################################################################
# EXPONENT ENCODING AND DECODING
#encodes an exponent as a biased 2-tuple (esize, exponent)
#remember msb is zero-indexed, but outputs a zero for the zero value
function encode_exp(unbiasedexp::Integer)
  #make sure our unbiased exponent is a signed integer
  unbiasedexp = int64(unbiasedexp)
  esize = uint16(64 - clz(uint64(abs(unbiasedexp - 1))))
  (esize, uint64(unbiasedexp + 1 << esize - 1))
end
#the inverse operation is finding the unbiased exponent of an Unum.
decode_exp(esize::Uint16, exponent::Uint64) = int(exponent) - (1 << esize) + 1

#maxfsize returns the the maximum fraction size for a given FSS.
max_fsize(FSS) = uint16((1 << FSS) - 1)
max_esize(ESS) = uint16((1 << ESS) - 1)
max_exponent(ESS) = 1 << (1 << ESS - 1)
min_exponent(ESS) = -(1 << (1 << ESS - 1)) + 2
