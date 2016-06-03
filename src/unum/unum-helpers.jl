#unum-helpers.jl
#helper functions for the unum constructor, and functions that will frequently
#be used with the constructor.
###########################################################
#Utility functions

################################################################################
# frac_trim - actively trims the fraction to size, setting a ubit as appropriate.

function trim(frac::UInt64, fsize::UInt16)
  frac & mask_top(fsize)
end

function trim!{FSS}(frac::ArrayNum{FSS}, fsize::UInt16)
  middle_cell = div(fsize, 0x0040) + 1
  frac.a[middle_cell] &= mask_top(fsize % 0x0040)
  for idx = (middle_cell + 1):__cell_length(FSS)
    frac.a[idx] = 0
  end
end
#generates the frac_trim!() functions
doc"""
  `Unums.frac_trim!(x::Unum, fsize::UInt16)` strictly trims a fraction to a
  certain size.  This doesn't set the ubit flag if digits are cut off, for that,
  use `Unums.trim_and_set_ubit!`
"""
@fracproc trim fsize

doc"""
  `Unums.exact_trim!(x::Unum)` detects exact unums and trims them to the shortest
  fsize.
"""
@universal function exact_trim!(x::Unum)
  is_ulp(x) && return x  #kick out if we're an ulp.
  tz = ctz(x.fraction)
  x.fsize = (tz == 0x0040) ? 0 : (0x003f - tz)
  return x
end

################################################################################
# trim_and_set_ubit - sets the ubit of the fraction if there is trailing data past the
# desired fsize.

needs_ubit(frac::UInt64, fsize::UInt16) = (frac & mask_bot(fsize)) != 0
function needs_ubit{FSS}(frac::ArrayNum{FSS}, fsize::UInt16)
  accum::UInt64 = zero(UInt64)
  middle_cell = div(fsize, 0x0040) + 1
  accum = frac.a[middle_cell] & mask_bot(fsize % 0x0040)
  for idx = (middle_cell + 1):__cell_length(FSS)
    accum |= frac.a[idx]
  end
  return (accum != 0)
end

doc"""
  `Unums.trim_and_set_ubit!(x::Unum, fsize::UInt16)` is a utility to adjust the
  fsize of a unum.  It checks to see if setting the fsize would need require the
  ubit flag to be thrown, throws it, and then resizes it.
"""
@universal function trim_and_set_ubit!(x::Unum, fsize::UInt16)
  x.flags |= (needs_ubit(x.fraction, fsize) * UNUM_UBIT_MASK)
  frac_trim!(x, fsize)
  return x
end

doc"""
  `Unums.rsh_and_set_ubit!(x::Unum, shift::UInt16)` is a utility that shifts the
  unum fraction to the right and sets the ubit if the fraction gets shifted past
  the right side of the unum.
"""
@universal function rsh_and_set_ubit!(x::Unum, shift::UInt16)
  mfsize::UInt16 = max_fsize(FSS)
  x.flags |= (needs_ubit(x.fraction, mfsize - shift) * UNUM_UBIT_MASK)
  x.fsize = min(x.fsize + shift, mfsize)
  frac_rsh!(x, shift)
  return x
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

doc"""
`Unums.zero_ulp_index(esize, fsize)` generates an index, based on esize and fsize
that corresponds to how many places to the left of 2 the corresponding "zero ulp"
will be.
"""
#calculates how many decimal places to the right of two a given zero ulp represents.
zero_ulp_index(esize::UInt16, fsize::UInt16) = (o16 << esize) - o16 + fsize

doc"""
`Unums.zero_ulp_params(::Type{Unum{ESS,FSS}}, index)` finds the best parameters
for the zero ulp, given the index of the desired ulp and the constraints set by
ESS and FSS.
"""
@universal function zero_ulp_params(T::Type{Unum}, index::UInt16)
  #first check if we need max_esize.
  mesize = max_esize(ESS)
  mfsize = max_fsize(FSS)

  #are we exceeding the max_esize limit?
  max_eindex = o16 << max_esize(ESS) - o16
  (index > max_eindex) && return (mesize, min(mfsize, index - max_eindex))

  #next, take the logarithm of the index to figure out how far we go.
  esize::UInt16 = 0x000F - clz(index + o16)
  #the remainder becomes the fraction
  fsize::UInt16 = index - o16 << esize + o16
  #unless we have to shortchange it.
  (esize, min(fsize, mfsize))
end
