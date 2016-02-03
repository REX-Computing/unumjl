#unum-properties
#functions that assess properties of unum values.

#generally speaking, the "unum library form" of a test will have the form
#is_XXXXX, for some of these, they are equivalent to a julia form from floating
#point tests that are overloaded - e.g. isnan == is_nan.  A separate file
#unum-teoe-func.jl provides aliasing implementations for all of the function
#in appendix a of "The End of Error"

decode_exp{ESS,FSS}(x::Unum{ESS,FSS}) = decode_exp(x.esize, x.exponent)

doc"""
`decode_exp_frac(::Unum{ESS,FSS})` decodes an exponent but if the exponent is
subnormal (strange or otherwise) it shifts the fraction and adjusts the frac_size.
the quad (unbiased_exponent, fraction, fsize, zeroish) is returned.  Zeroish refers
to the state of both exponent and fraction being zero.

`decode_exp_frac(::Unum{ESS,FSS}, ::ArrayNum{FSS})` is for `FSS > 6`, and returns
the same quad, except preallocated space for the new fraction should be passed
to function, and the contents of this space will be bashed.
"""
@generated function decode_exp_frac{ESS,FSS}(x::Unum{ESS,FSS}, f::Union{ArrayNum{FSS}, UInt64} = z64)
  FSS > 6 && (f == UInt64) && throw(ArgumentError("FSS $FSS > 6 is invalid for this form of decode_exp_frac"))
  FSS < 7 && (f == ArrayNum{FSS}) && throw(ArgumentError("FSS $FSS < 6 is invalid for this form of decode_exp_frac"))

  ftype = f
  shift_code = FSS < 7 ? :(fraction <<= shft) : :(lsh!(fraction, shft))

  quote
    unbiased_exponent::Int = decode_exp(x)
    fraction::$ftype = x.fraction
    fsize::UInt16 = x.fsize
    zeroish::Bool = false

    #make modifications if we're subnormal.
    if is_exp_zero(x)
      if is_frac_zero(x)
        zeroish = true
      else
        shft::UInt16 = clz(x.fraction) + 1
        unbiased_exponent -= (shft - 1)
        $shift_code
        fsize -= min(shft, fsize)
      end
    end

    (unbiased_exponent, fraction, fsize, zeroish)
  end
end

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

#some really dumb ones, but we'll put these in for legibility.
is_ulp{ESS,FSS}(x::Unum{ESS,FSS})      = (@ubitof(x) != 0)
is_exact{ESS,FSS}(x::Unum{ESS,FSS})    = (@ubitof(x) == 0)
is_negative{ESS,FSS}(x::Unum{ESS,FSS}) = (@signof(x) != 0)
is_positive{ESS,FSS}(x::Unum{ESS,FSS}) = (@signof(x) == 0)
is_neg_def{ESS,FSS}(x::Unum{ESS,FSS})  = (!is_zero(x)) && is_negative(x)
is_pos_def{ESS,FSS}(x::Unum{ESS,FSS})  = (!is_zero(x)) && is_positive(x)
export is_ulp, is_exact, is_negative, is_positive

#a couple of testing conditions
@gen_code function __is_nan_or_inf{ESS,FSS}(x::Unum{ESS,FSS})
  #calculate expected fsize and esize.
  xesize = max_esize(ESS)
  xfsize = max_fsize(FSS)
  xexponent = max_biased_exponent(ESS)
  @code quote
    (x.fsize == $xfsize) || return false
    (x.esize == $xesize) || return false
    (x.exponent == $xexponent) || return false
  end

  if FSS < 7
    xfraction = mask_top(xfsize)
    @code :(x.fraction == $xfraction)
  else
    @code :(is_all_ones(x.fraction))
  end
end

is_nan{ESS,FSS}(x::Unum{ESS,FSS}) = is_ulp(x) && __is_nan_or_inf(x)
Base.isnan{ESS,FSS}(x::Unum{ESS,FSS}) = is_ulp(x) && __is_nan_or_inf(x)
export is_nan

#isinf matches the julia definiton and triggers on either positive or negative
#infinity.  is_pos_inf and is_neg_inf both are Unum-specific functions that detect
#the expected values.
is_inf{ESS,FSS}(x::Unum{ESS,FSS}) = is_exact(x) && __is_nan_or_inf(x)
is_pos_inf{ESS, FSS}(x::Unum{ESS, FSS}) = is_positive(x) && is_exact(x) && __is_nan_or_inf(x)
is_neg_inf{ESS, FSS}(x::Unum{ESS, FSS}) = is_negative(x) && is_exact(x) && __is_nan_or_inf(x)
export is_inf, is_pos_inf, is_neg_inf

#aliasing
Base.isinf{ESS,FSS}(x::Unum{ESS,FSS}) = is_exact(x) && __is_nan_or_inf(x)

@gen_code function is_finite{ESS,FSS}(x::Unum{ESS,FSS})
  #record the maximum esize and fsize values.  Any value less than this and
  #it's finite.
  mesize = max_esize(ESS)
  mfsize = max_fsize(FSS)
  mexponent = max_biased_exponent(ESS)
  @code quote
    x.esize < $mesize && return true
    x.fsize < $mfsize && return true
    x.exponent < $mexponent && return true
  end
  if (FSS < 7)
    mfraction = mask_top(mfsize)
    @code :(x.fraction < $mfraction)
  else
    @code :(!is_all_ones(x.fraction))
  end
end
Base.isfinite{ESS,FSS}(x::Unum{ESS,FSS}) = is_finite(x)

#NB:  The difference between "is_exp_zero" and "issubnormal" - is_exp_zero admits
#zero as a solution; issubnormal is in compliance with the standard julia
#issubnormal function and does not admit zero as a true result.
is_subnormal{ESS,FSS}(x::Unum{ESS,FSS}) = (x.exponent == z64) && is_not_zero(x.fraction)
is_exp_zero{ESS,FSS}(x::Unum{ESS,FSS}) = x.exponent == z64
@gen_code function is_strange_subnormal{ESS,FSS}(x::Unum{ESS,FSS})
  mesize::UInt16 = max_esize(ESS)
  @code :((x.exponent == z64) && (x.esize < $mesize))
end

Base.issubnormal{ESS,FSS}(x::Unum{ESS,FSS}) = is_subnormal(x)                    #alias the unum-form to the julia-compliant form.
#use ESS because this will be checked by the compiler, instead of at runtime.
is_frac_zero{ESS,FSS}(x::Unum{ESS,FSS}) = is_all_zero(x.fraction)
is_zero{ESS,FSS}(x::Unum{ESS,FSS}) = (x.exponent == z64) && is_exact(x) && is_frac_zero(x)

doc"""
  `is_unit(x::Unum{ESS,FSS})` tests if the value in a unum is +/- 1.  Because of
  asymmetric exponents, this is slightly more laborious than you might expect:
  all unums ESS != 0, there are two canonical representations for the value
  1, one being exponent 0; fraction 0 and the other being subnormal exponent,
  fraction 0b1000...0000.  When ESS == 0 there is only access to the subnormal
  form.
"""
function is_unit{ESS,FSS}(x::Unum{ESS,FSS})
  #asymmetric exponents make this slightly more laborious than might be expected
  #one is not an ulp, it is exact.
  is_ulp(x) && return false
  #case one:  An exponent of zero and nothing in the fraction.
  #note that when x.esize == 0, then decode_exp 0 is subnormal.
  (x.esize != 0) && (decode_exp(x) == 0) && is_all_zero(x.fraction) && return true
  is_subnormal(x) && (x.esize == 0) && (is_top(x.fraction)) && return true
  return false
end

is_one{ESS,FSS}(x::Unum{ESS,FSS}) = is_positive(x) && is_unit(x)
is_neg_one{ESS,FSS}(x::Unum{ESS,FSS}) = is_negative(x) && is_unit(x)
#checks if the value is sss ("smaller than small subnormal")
@generated function is_sss{ESS,FSS}(x::Unum{ESS,FSS})
  mesize::UInt16 = max_esize(ESS)
  :(is_ulp(x) && (x.esize == $mesize) && (x.exponent == z64) && is_all_zero(x.fraction))
end
is_pos_sss{ESS,FSS}(x::Unum{ESS,FSS}) = is_positive(x) && is_sss(x)
is_neg_sss{ESS,FSS}(x::Unum{ESS,FSS}) = is_negative(x) && is_sss(x)

################################################################################
##  MMR CHECKS
doc"""
  `is_mmr_frac(::Unum)` overloads the is_mmr_frac(::ArrayNum) procedure to allow
  for transparent checking of whether or not a Unum has the look of MMR, whether
  or not the Unum has a big or small structure
"""
@generated function is_mmr_frac{ESS,FSS}(x::Unum{ESS,FSS})
  xfsm1::UInt16 = FSS == 0 ? 0 : max_fsize(FSS) - 1
  if FSS < 7
    xfraction::UInt64 = FSS == 0 ? 0 : mask_top(xfsm1)
    :(x.fraction == $xfraction)
  else
    :(is_mmr_frac(x.fraction))
  end
end

doc"""
  `is_mmr(::Unum)` sign-agnostically checks to see if the passed unum is the positive
  'more than maxreal' interval, or the open bound ±(maxreal, ∞)
"""
@generated function is_mmr{ESS,FSS}(x::Unum{ESS,FSS})
  xesize = max_esize(ESS)
  xfsize = max_fsize(FSS)
  xexponent = max_biased_exponent(ESS)
  quote
    is_ulp(x) || return false
    x.esize == $xesize || return false
    x.fsize == $xfsize || return false
    x.exponent == $xexponent || return false
    is_mmr_frac(x) || return false
  end
end

doc""" `is_pos_mmr(::Unum)` checks to see if the passed unum is the positive 'more than maxreal' interval, or the open bound (maxreal, ∞)"""
is_pos_mmr{ESS,FSS}(x::Unum{ESS,FSS}) = is_positive(x) && is_mmr(x)

doc""" `is_neg_mmr(::Unum)` checks to see if the passed unum is the negative 'more than maxreal' interval, or the open bound (-∞, -maxreal)"""
is_neg_mmr{ESS,FSS}(x::Unum{ESS,FSS}) = is_negative(x) && is_mmr(x)

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
function is_magnitude_less_than_one{ESS,FSS}(x::Unum{ESS,FSS})
  #checking subnormal status.
  if (is_exp_zero(x))
    #check to see if the top bit is zero
    return (x.esize > 0) | is_top_frac_bit_zero(x)
  else
    #check to see if the top bit of the exponent is zero.
    return (decode_exp(x) < 0)
  end
end
