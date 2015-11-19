#unum-helpers.jl
#helper functions for the unum constructor, and functions that will frequently
#be used with the constructor.
###########################################################
#Utility functions

#checking to make sure the parameters of frac_trim make sense.
function __check_frac_trim(frac::UInt64, fsize::UInt16)
  (fsize >= 64) && throw(ArgumentError("fsize $fsize too large for FSS < 7"))
  nothing
end

function __check_frac_trim!{FSS, r}(frac::ArrayNum{FSS}, fsize::UInt16, ::Type{Val{r}})
  (fsize > max_fsize(FSS)) && throw(ArgumentError("fsize $fsize too large for FSS $FSS"))
  nothing
end

#_frac_trim:  Takes a Uint64 value and returns a triplet: (fraction, fsize, ubit)
#this triplet represents the fraction VarInt trimmed to fsize, a new fsize,
#in the case that it's exact and some zeros can be trimmed, and whether or not
#ubit needs to be thrown (were there values cast out by fsize)?
@dev_check function __frac_trim(frac::UInt64, fsize::UInt16)
  #generate masks from fsize values using the internal functions.
  high_mask = mask_top(fsize)
  low_mask = mask_bot(fsize)
  #decide if we need to set the ubit
  #mask out the high bits and check to see if what remains is zero.
  #this needs to be in an array because that will collapse to the appropriate
  #one-dimensional array in the array case and collapse to a one-element array
  #in the single case, so that matches with the zeros() directive.
  ubit = is_all_zero(low_mask & frac) ? z16 : UNUM_UBIT_MASK
  #mask out the low bits and save that as the fraction.
  frac &= high_mask
  #we may need to trim the fraction further, in which case we alter fsize.
  #also take the "zero" case and make sure we represent at least one digit.
  fsize = (ubit == 0) ? __minimum_data_width(frac) : fsize
  (frac, fsize, ubit)
end

@dev_check function __frac_trim!{FSS, r}(frac::ArrayNum{FSS}, fsize::UInt16, a::Type{Val{r}})
  #temporarily we have to shim this to __frac_trim_internal because doubling
  #up @dev_check and @gen_code doesn't work.
  __frac_trim_internal!(frac, fsize, Val{r})
end

@gen_code function __frac_trim_internal!{FSS, r}(frac::ArrayNum{FSS}, fsize::UInt16, ::Type{Val{r}})
  #set the register, this is a UInt64 array.
  _register = registers[r]

  @code quote
    register = ArrayNum{FSS}($_register)
    #zero out the register.
    zero!(register)
    #set the register to be the mask bottom
    mask_bot!(register, fsize)
    #fill in the register with bits from the fraction.
    fill_mask!(register, frac)
    #check to see if it's all zero.
    ubit = is_all_zero(register) ? z16 : UNUM_UBIT_MASK
    #fill the register with bits from the top.
    mask_top!(register, fsize)
    #backfill the fraction comparing with the mask.
    fill_mask!(frac, register)
    #reset fsize by calculating _minimum_data_width
    fsize = (ubit == 0) ? __minimum_data_width(frac) : fsize
    #return the relevant triplet.
    (fsize, ubit)
  end
end

#=
#takes a peek at the fraction and decides if ubit needs to be set (if the boundary
#is not flush with max_fss), but also decides if fsize_of_exact needs to be set.
function __frac_analyze(fraction::UInt64, is_ubit::UInt16, fss::Int)
  #two possibilities:  fss is less than 6 (and the fraction is not on a 64-bit border)
  _mfs::Int16 = max_fsize(fss)
  if (fss < 6)
    #set the high mask
    high_mask::UInt64 = __frac_mask(fss)
    #generate the low mask and check it out.
    low_mask::UInt64 = ~high_mask
    is_ubit = (fraction & low_mask != 0) ? UNUM_UBIT_MASK : is_ubit

    #mask out the fraction.
    fraction = fraction & high_mask

    fsize = (is_ubit != 0) ? _mfs : __minimum_data_width(fraction)
    (fraction & high_mask, fsize, is_ubit)
  else
    #we don't need to check for lost bits because when 6 or greater, the fractions
    #are aligned with the 64-bit boundaries.
    (is_ubit != 0) && return (fraction, _mfs, is_ubit)
    (fraction, __minimum_data_width(fraction), z16)
  end
end

function __frac_analyze(fraction::Array{UInt64}, is_ubit::UInt16, fss::Int)
  #we don't need to check for lost bits because when 6 or greater, the fractions
  #are aligned with the 64-bit boundaries.
  (is_ubit != 0) && return (fraction, _mfs, is_ubit)
  (fraction, __minimum_data_width(fraction), z16)
end

#match the fraction to fss, setting the ubit if digits were thrown out in the
#process of trimming to fraction.

__frac_match_check(frac::Array{UInt64}, fss::Int)
end

function __frac_match(frac::Uint64, fss::Int)
end

function __frac_match(frac::Array{UInt64}, fss::Int)
  flength = length(frac)
  cells = __frac_cells(fss)
  temp_frac = zeros(UInt64, cells)
  ubit = zero(UInt16)
  #create an appropriate superint
  if (flength < cells)
    #fill the remainder of resultfrac with data from frac
    temp_frac[cells - flength + 1:cells] = frac
    res = temp_frac
  else
    #mirror the previous process
    temp_frac = frac[flength - cells + 1:flength]

    ubit = ([frac][1:flength - cells] == zeros(UInt64, flength - cells)) ? 0 : UNUM_UBIT_MASK
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
__frac_cells(fss::Int) = UInt16(fss < 6 ? 1 : (1 << (fss - 6)))

#set the lsb of a superint to 1 based on fss.  This function has undefined
#behavior if the passed superint already has a bit set at this location.
function __set_lsb(a::UInt64, fss::Int)
  return a | (0x8000_0000_0000_0000 >> (1 << fss - 1)))
end
function __set_lsb(a::Array{UInt64, 1}, fss::Int)
    return a | [zeros(UInt64, __frac_cells(fss) - 1); o64]
end
=#

################################################################################
# EXPONENT ENCODING AND DECODING
#encodes an exponent as a biased 2-tuple (esize, exponent)
#remember msb is zero-indexed, but outputs a zero for the zero value
function encode_exp(unbiasedexp::Int64)
  #make sure our unbiased exponent is a signed integer
  unbiasedexp = Int64(unbiasedexp)
  esize = UInt16(64 - leading_zeros(UInt64(abs(unbiasedexp - 1))))
  (esize, UInt64(unbiasedexp + 1 << esize - 1))
end
#the inverse operation is finding the unbiased exponent of an Unum.
decode_exp(esize::UInt16, exponent::UInt64) = Int64(exponent) - (1 << esize) + 1

#maxfsize returns the the maximum fraction size for a given FSS.
max_fsize(FSS) = UInt16((1 << FSS) - 1)
max_esize(ESS) = UInt16((1 << ESS) - 1)

#note the difference here.  ESS values are determined by julia's type system
#and therefore take the value Int.  esize values are set by the type definition
#and are unsigned 16-bit integers always.
max_biased_exponent(ESS::Int64) = UInt64((1 << (1 << ESS))) - one(UInt64)
max_biased_exponent(esize::UInt16) = UInt64(1 << (esize + 1)) - one(UInt64)

#note that these are the unbiased exponent values.
max_exponent(ESS) = Int64(1 << (1 << ESS - 1))
min_exponent(ESS) = Int64(-(1 << (1 << ESS - 1)) + 2)
