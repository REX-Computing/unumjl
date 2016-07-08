#unum-properties
#functions that assess properties of unum values.

#generally speaking, the "unum library form" of a test will have the form
#is_XXXXX, for some of these, they are equivalent to a julia form from floating
#point tests that are overloaded - e.g. isnan == is_nan.  A separate file
#unum-teoe-func.jl provides aliasing implementations for all of the function
#in appendix a of "The End of Error"

@universal decode_exp(x::Unum) = decode_exp(x.esize, x.exponent)

doc"""
  `Unums.@signof(x)` extracts the 16-bit unsigned "sign" component of the flag.
"""
macro signof(x)
  :($x.flags & UNUM_SIGN_MASK)
end

doc"""`Unums.@ubitof(x)` extracts the 16-bit unsigned "ubit" component of the flag."""
macro ubitof(x)
  :($x.flags & UNUM_UBIT_MASK)
end

doc"""`Uunums.@flipsign(x)` flips the sign of the the unum x"""
macro flipsign(x)
  :($x.flags $= UNUM_SIGN_MASK)
end

@universal uflag!(x::Unum, f::UInt16) = (x.flags = f; x)

#some really dumb ones, but we'll put these in for legibility.
@universal is_ulp(x::Unum)      = (@ubitof(x) != 0)
@universal is_exact(x::Unum)    = (@ubitof(x) == 0)
@universal is_negative(x::Unum) = (@signof(x) != 0)
@universal is_positive(x::Unum) = (@signof(x) == 0)
@universal is_neg_def(x::Unum)  = (!is_zero(x)) && is_negative(x)
@universal is_pos_def(x::Unum)  = (!is_zero(x)) && is_positive(x)
export is_ulp, is_exact, is_negative, is_positive

#a couple of testing conditions
@universal function __is_nan_or_inf(x::Unum)
  (x.fsize == max_fsize(FSS)) || return false
  (x.esize == max_esize(ESS)) || return false
  (x.exponent == max_biased_exponent(ESS)) || return false

  if FSS < 7
    x.fraction == mask_top(max_fsize(FSS))
  else
    is_all_ones(x.fraction)
  end
end

@universal is_nan(x::Unum) = is_ulp(x) && __is_nan_or_inf(x)
@universal Base.isnan(x::Unum) = is_ulp(x) && __is_nan_or_inf(x)
export is_nan

#isinf matches the julia definiton and triggers on either positive or negative
#infinity.  is_pos_inf and is_neg_inf both are Unum-specific functions that detect
#the expected values.
@universal is_inf(x::Unum) = is_exact(x) && __is_nan_or_inf(x)
@universal is_pos_inf(x::Unum) = is_positive(x) && is_exact(x) && __is_nan_or_inf(x)
@universal is_neg_inf(x::Unum) = is_negative(x) && is_exact(x) && __is_nan_or_inf(x)
export is_inf, is_pos_inf, is_neg_inf
#aliasing to base definition
@universal Base.isinf(x::Unum) = is_exact(x) && __is_nan_or_inf(x)


@universal function is_finite(x::Unum)
  #record the maximum esize and fsize values.  Any value less than this and
  #it's finite.
  x.esize < max_esize(ESS) && return true
  x.fsize < max_fsize(FSS) && return true
  x.exponent < max_biased_exponent(ESS) && return true

  if (FSS < 7)
    x.fraction < mask_top(max_fsize(FSS))
  else
    is_not_ones(x.fraction)
  end
end
@universal Base.isfinite(x::Unum) = is_finite(x)

#NB:  The difference between "is_exp_zero" and "issubnormal" - is_exp_zero admits
#zero as a solution; issubnormal is in compliance with the standard julia
#issubnormal function and does not admit zero as a true result.
@universal is_subnormal(x::Unum) = (x.exponent == z64) && is_not_zero(x.fraction)
@universal is_exp_zero(x::Unum) = x.exponent == z64

doc"""
  Unums.is_strange_subnormal(x) returns if the unum value x is a "strange subnormal".
  A "strange subnormal" is a subnormal where the esize is not maxed out.  These
  subnormal values can be "corrected" to normal rerpresentations.
"""
@universal function is_strange_subnormal(x::Unum)
  (x.esize < max_esize(ESS)) && is_subnormal(x)
end

@universal Base.issubnormal(x::Unum) = (x.exponent == z64) && is_not_zero(x.fraction) #alias the unum-form to the julia-compliant form.
@universal is_frac_zero(x::Unum) = is_all_zero(x.fraction)
@universal is_zero(x::Unum) = (x.exponent == z64) && is_exact(x) && is_frac_zero(x)

doc"""
  `is_unit(x::Unum{ESS,FSS})` tests if the value in a unum is +/- 1.  Because of
  asymmetric exponents, this is slightly more laborious than you might expect:
  all unums ESS != 0, there are two canonical representations for the value
  1, one being exponent 0; fraction 0 and the other being subnormal exponent,
  fraction 0b1000...0000.  When ESS == 0 there is only access to the subnormal
  form.
"""
@universal function is_unit(x::Unum)
  #asymmetric exponents make this slightly more laborious than might be expected
  #one is not an ulp, it is exact.
  is_ulp(x) && return false
  #case one:  An exponent of zero and nothing in the fraction.
  #note that when x.esize == 0, then decode_exp 0 is subnormal.
  (x.esize != 0) && (decode_exp(x) == 0) && is_all_zero(x.fraction) && return true
  is_subnormal(x) && (x.esize == 0) && (is_top(x.fraction)) && return true
  return false
end

@universal is_one(x::Unum) = is_positive(x) && is_unit(x)
@universal is_neg_one(x::Unum) = is_negative(x) && is_unit(x)
#checks if the value is sss ("smaller than small subnormal")
@universal function is_sss(x::Unum)
  is_ulp(x) && (x.esize == max_esize(ESS)) && (x.exponent == z64) && is_all_zero(x.fraction)
end
@universal is_pos_sss(x::Unum) = is_positive(x) && is_sss(x)
@universal is_neg_sss(x::Unum) = is_negative(x) && is_sss(x)

################################################################################
##  MMR CHECKS
doc"""
  `is_mmr_frac(::Unum)` overloads the is_mmr_frac(::ArrayNum) procedure to allow
  for transparent checking of whether or not a Unum has the look of MMR, whether
  or not the Unum has a big or small structure
"""
@universal function is_mmr_frac(x::Unum)
  if FSS == 0
    x.fraction == 0
  elseif FSS < 7
    x.fraction == mask_top(max_fsize(FSS) - 0x0001)
  else
    is_mmr_frac(x.fraction)
  end
end

doc"""
  `is_mmr(::Unum)` sign-agnostically checks to see if the passed unum is the positive
  'more than maxreal' interval, or the open bound ±(maxreal, ∞)
"""
@universal function is_mmr(x::Unum)
  is_ulp(x) || return false
  x.esize == max_esize(ESS) || return false
  x.fsize == max_fsize(FSS) || return false
  x.exponent == max_biased_exponent(ESS)|| return false
  is_mmr_frac(x)
end

doc""" `is_pos_mmr(::Unum)` checks to see if the passed unum is the positive 'more than maxreal' interval, (maxreal, ∞)"""
@universal is_pos_mmr(x::Unum) = is_positive(x) && is_mmr(x)

doc""" `is_neg_mmr(::Unum)` checks to see if the passed unum is the negative 'more than maxreal' interval, (-∞, -maxreal)"""
@universal is_neg_mmr(x::Unum) = is_negative(x) && is_mmr(x)

export is_subnormal, is_exp_zero
export is_frac_zero, is_zero, is_sss, is_pos_sss, is_neg_sss
export is_mmr, is_pos_mmr, is_neg_mmr

doc"""
  `Unums.is_magnitude_less_than_one(::Unum)` checks to see if the magnitude (absolute
  value) is less than one.  This is important for multiplication, in particular
  checking for smaller than smallest subnormal and more than maxreal
  calculations.  As is evident by this awkward syntax, you're really not supposed
  to use this outside of the Unums namespace.
"""
@universal function is_magnitude_less_than_one(x::Unum)
  #checking subnormal status.
  if (is_exp_zero(x))
    #check to see if the top bit is zero
    return (x.esize > 0) | is_top_frac_bit_zero(x)
  else
    #check to see if the top bit of the exponent is zero.
    return (decode_exp(x) < 0)
  end
end
