#unum-helpers.jl
#helper functions for the unum constructor, and functions that will frequently
#be used with the constructor.
###########################################################
#Utility functions

#_frac_trim:  Takes a Uint64 value and returns a triplet: (fraction, fsize, ubit)
#this triplet represents the fraction VarInt trimmed to fsize, a new fsize,
#in the case that it's exact and some zeros can be trimmed, and whether or not
#ubit needs to be thrown (were there values cast out by fsize)?
function __frac_trim(frac::UInt64, fsize::UInt16)
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

@gen_code function __frac_trim!{FSS}(frac::ArrayNum{FSS}, fsize::UInt16)
  @code quote
    middle_cell = div(fsize, 0x0040) + 1

    #use bot_array from i64o-masks.jl.
    bot_array[2] = mask_bot(fsize % 0x0040)

    #set up an accumulator, and a mask variable.
    accum::UInt64 = z64
    mask::UInt64 = z64
  end

  for (idx = 1:__cell_length(FSS))
    @code quote
      @inbounds mask = bot_array[sign($idx - middle_cell) + 2]
      @inbounds accum |= mask & frac[$idx]
      @inbounds frac[$idx] &= ~mask
    end
  end

  @code quote
    if (accum == 0)
      return (__minimum_data_width(frac), 0)
    else
      return (fsize, UNUM_UBIT_MASK)
    end
  end
end

################################################################################
# EXPONENT ENCODING AND DECODING
doc"""
`Unums.encode_exp(::Int64)` returns a duple `(esize, exponent)` which returns the
most compact Unum representation for an unbiased exponent.  This does not
account for subnormal representations.
"""
function encode_exp(unbiasedexp::Int64)
  #make sure our unbiased exponent is a signed integer
  unbiasedexp = Int64(unbiasedexp)
  esize = UInt16(64 - leading_zeros(UInt64(abs(unbiasedexp - 1))))
  (esize, UInt64(unbiasedexp + 1 << esize - 1))
end

doc"""
`Unums.decode_exp(::UInt16, ::UInt64)` takes a duple `(esize, exponent)` and
returns the unbiased exponent which is represented by this value.  This does
not account for subnormal representations.
"""
#the inverse operation is finding the unbiased exponent of an Unum.
decode_exp(esize::UInt16, exponent::UInt64) = Int64(exponent) - (1 << esize) + 1

doc"""
`Unums.max_fsize(::Int64)` retrieves the maximum possible fsize value based on
the FSS value.
"""
max_fsize(FSS::Int64) = UInt16((1 << FSS) - 1)
doc"""
`Unums.max_esize(::Int64)` retrieves the maximum possible esize value based on
the ESS value.
"""
max_esize(ESS::Int64) = UInt16((1 << ESS) - 1)

doc"""
`Unums.max_biased_exponent(::Int64)` retrieves the maximum possible biased exponent
for a given ESS.  Passing a UInt16 instead to `max_biased_exponent(::UInt16)`
signals that your are passing an esize value, instead of a ESS value.  Note that
there is no correspoding min_biased_exponent, because that is always 0.
"""
max_biased_exponent(ESS::Int64) = UInt64((1 << (1 << ESS))) - one(UInt64)
max_biased_exponent(esize::UInt16) = UInt64(1 << (esize + 1)) - one(UInt64)

doc"""
`Unums.max_exponent(::Int64)` retrieves the maximum possible unbiased exponent for a given ESS.
"""
max_exponent(ESS::Int64) = Int64(1 << (1 << ESS - 1))

doc"""
`Unums.min_exponent(::Int64)` retrieves the minimum possible unbiased exponent
for a given ESS, not counting subnormal representations.
`min_exponent(ESS::Int64, FSS::Int64)` accounts for this.
"""
min_exponent(ESS::Int64) = Int64(-(1 << (1 << ESS - 1)) + 2)
#and then a minimum exponent that takes into account subnormality.
min_exponent(ESS::Int64, FSS::Int64) = min_exponent(ESS) - (max_fsize(FSS) + 1)
