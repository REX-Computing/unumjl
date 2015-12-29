#unum-multiplication.jl
#does multiplication for unums.

doc"""
  `mul!(::Unum{ESS,FSS}, ::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes two unums and
  multiplies them, storing the result in the third, g-layer

  `mul!(::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes a unum and multiplies it into
  a g-layer storing and overwriting the result.
  the result and overwriting the second, g-layer

  In both cases, a reference to the result gnum is returned.
"""
function mul!{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  put_unum!(b, c)
  mul!(a, c)
end

function mul!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  #override, based off of easy calculations, but also does
  #all necessary parity swapping for the system b.
  clear_ignore_sides!(b)
  __multiplication_override_check!(a, b)

  #all multiplications ignore the sign of the multiplicand.

  if should_calculate(b, LOWER_UNUM)
    __signless_multiply!(a, b, LOWER_UNUM)
  end

  if should_calculate(b, UPPER_UNUM)
    __signless_multiply!(a, b, UPPER_UNUM)
  end
  b
end

function __multiplication_override_check!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  ############################################
  # deal with NaNs.
  #if our multiplicand is nan, then set the product to nan.
  is_nan(a) && (@scratch_this_operation!(b))
  is_nan(b) && (ignore_both_sides!(b); return)

  #do the parity swap.
  if is_negative(a)
    parity_swap!(b)
  end

  if (is_inf(a))
    #infinity can't multiply across zero.
    is_twosided(b) && ((b.lower.flags & UNUM_SIGN_MASK) != (b.upper.flags & UNUM_SIGN_MASK)) && (@scratch_this_operation!(b))
    #infinity can't multiply times just zero, either
    should_calculate(b, LOWER_UNUM) && is_zero(b, LOWER_UNUM) && (@scratch_this_operation!(b))
    should_calculate(b, UPPER_UNUM) && is_zero(b, UPPER_UNUM) && (@scratch_this_operation!(b))
    #just set it to mult_sign_lower, and make it one sided, and make it inf.
    inf!(b, b.lower.flags & UNUM_SIGN_MASK, LOWER_UNUM); ignore_side!(b, LOWER_UNUM); set_onesided!(b)
  end
  #next, check infinities in the result.
  if should_calculate(b, LOWER_UNUM) && is_inf(b, LOWER_UNUM)
    is_zero(a) && (@scratch_this_operation!(b))
    ignore_side!(b, LOWER_UNUM)
  end
  if should_calculate(b, UPPER_UNUM) && is_inf(b, UPPER_UNUM)
    is_zero(a) && (@scratch_this_operation!(b))
    ignore_side!(b, UPPER_UNUM)
  end

  #next, check zeros. - since they're for sure finite we have no problems.
  (is_zero(a)) && (zero!(b, LOWER_UNUM); ignore_side!(b, LOWER_UNUM); set_onesided!(b))   #nuke the whole thing, it's the only way to be sure.
  should_calculate(b, LOWER_UNUM) && is_zero(b, LOWER_UNUM) && ignore_side!(b, LOWER_UNUM)
  should_calculate(b, UPPER_UNUM) && is_zero(b, UPPER_UNUM) && ignore_side!(b, UPPER_UNUM)

  #finally, check ones.
  (is_unit(a)) && ignore_both_sides!(b)
  if should_calculate(b, LOWER_UNUM) && is_unit(b.lower)
    copy_unum!(a, b.lower)
    b.lower.flags = (b.lower.flags & ~UNUM_FLAG_MASK) | (a.flags & UNUM_FLAG_MASK) $ UNUM_FLAG_MASK
    ignore_side!(b, LOWER_UNUM)
  end
  if should_calculate(b, UPPER_UNUM) && is_unit(b.upper)
    copy_unum!(a, b.upper)
    b.upper.flags = (b.upper.flags & ~UNUM_FLAG_MASK) | (a.flags & UNUM_FLAG_MASK) $ UNUM_FLAG_MASK
    ignore_side!(b, UPPER_UNUM)
  end
end

@gen_code function __signless_multiply!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  if FSS < 6
  elseif FSS == 6
    @code quote
    end
  else
  end
end


#=

# how to do multiplication?  Just chunk your 64-bit block into two 32-bit
# segments and do multiplication on those.
#
# Ah Al
# Bh Bl  -> AhBh (AhBl + BhAl) AlBl
#
# This should only require 2 Uint64s.  But, also remember that we have a
# 'phantom one' in front of potentially both segments, so we'll throw in a third
# UInt64 in front to handle that.

function __lower_scan(a::Array{UInt32, 1}, b::Array{UInt32, 1}, l::UInt16)
  for (aidx = 1:(l - 1))
    for (bidx = 1:(l - aidx))
      ((a[aidx] != 0) && (b[bidx] != 0)) && return UNUM_UBIT_MASK
    end
  end
  return z16
end


#amends a fraction to a subnormal number if necessary.
function __amend_to_subnormal{ESS,FSS}(T::Type{Unum{ESS,FSS}}, fraction::UInt64, unbiased_exp::Int, flags::UInt16)
  l::UInt16 = length(fraction)
  unbiased_exp < (min_exponent(ESS) - max_fsize(FSS) - 1) && return sss(Unum{ESS,FSS}, flags)
  #regenerate the fraction as follows:  First calcluate the subnormal shift.
  subnormshift = min_exponent(ESS) - unbiased_exp
  #detect if we're going to clobber bits when we shift, store in ubit variable.
  is_ubit::UInt16 = allzeros(fraction & fillbits(subnormshift, l)) ? 0 : UNUM_UBIT_MASK
  #then shift the fraction and throw in the shifted top bit.
  fraction = rsh(fraction, subnormshift) | __bit_from_top(subnormshift, l)
  #run an analysis on fsize as you might normally do.
  (fraction, fsize, is_ubit) = __frac_analyze(fraction, is_ubit, FSS)
  flags |= is_ubit
  return Unum{ESS,FSS}(fsize, max_esize(ESS), flags, fraction, z64)
end

#performs an exact mult on two unums a and b.
function __mult_exact{ESS, FSS}(a::Unum{ESS,FSS},b::Unum{ESS,FSS}, sign::UInt16)
  #cache subnormality of a and b.  Use "is_exp_zero" instead of "issubnormal"
  #to avoid the extra (not zero) check for issubnormal.
  _a_sn = is_exp_zero(a)
  _b_sn = is_exp_zero(b)

  #calculate and cache _aexp and _bexp
  _aexp::Int64 = decode_exp(a) + (_a_sn ? 1 : 0)
  _bexp::Int64 = decode_exp(b) + (_b_sn ? 1 : 0)

  #preliminary overflow and underflow tests save us from calculations in the
  #case these are definite outcomes.
  (_aexp + _bexp > max_exponent(ESS) + 1) && return mmr(Unum{ESS,FSS}, sign)
  (_aexp + _bexp < min_exponent(ESS) - max_fsize(FSS) - 2) && return sss(Unum{ESS,FSS}, sign)

  is_ubit::UInt16 = 0;
  fsize::UInt16 = 0;
  #run a chunk_mult on the a and b fractions
  (fraction, is_ubit) = __chunk_mult(a.fraction, b.fraction)

  #next, steal the carried add function from addition.  We're going to need
  #to re-add the fractions back due to algebra with the phantom bit.
  #
  # i.e.: (1 + a)(1 + b) = 1 + a + b + ab
  # => initial carry + a.fraction + b.fraction + chunkproduct
  #
  # considering the case of subnormality:
  # b - subnormal (1 + a)(0 + b) = 0 + 0 + b + ab
  # a - subnormal (0 + a)(1 + b) = 0 + a + 0 + ab
  # both subnormal:  Just ab.

  #set the carry to be one only if both are not subnormal.

  carry = (_a_sn || _b_sn) ? z64 : o64

  #only perform the respective adds if the *opposing* thing is not subnormal.
  _b_sn || ((carry, fraction) = __carried_add(carry, fraction, a.fraction))
  _a_sn || ((carry, fraction) = __carried_add(carry, fraction, b.fraction))

  if (carry == 0)
    #shift over the fraction as far as we need to.  (we know this isn't zero, because we did a zero check.)
    shift::Int64 = int64(leading_zeros(fraction) + 1)
    is_ubit |= (allzeros(fraction & fillbits(shift, __frac_cells(FSS)))) ? z16 : UNUM_UBIT_MASK
    fraction = fraction << shift
    shift *= -1
  else
    #carry may be as high as three!  So we must shift as necessary.
    (fraction, shift, is_ubit) = __shift_after_add(carry, fraction, is_ubit)
  end

  #the exponent is just the sum of the two exponents.
  unbiased_exp::Int64 = _aexp + _bexp + shift
  #have to repeat the overflow and underflow tests in light of carry shifts.
  (unbiased_exp > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, sign)
  (unbiased_exp < min_exponent(ESS)) && return __amend_to_subnormal(Unum{ESS,FSS}, fraction, unbiased_exp, is_ubit | sign)
  (esize, exponent) = encode_exp(unbiased_exp)

  #analyze the fraction to appropriately set fsize and ubit.
  (fraction, fsize, is_ubit) = __frac_analyze(fraction, is_ubit, FSS)
  flags = sign | is_ubit

  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end

function __mult_ulp{ESS, FSS}(a::Unum{ESS,FSS},b::Unum{ESS,FSS}, sign::UInt16)
  #because zero cannot be traversed by the ulp, we can do something very simple
  #here.

  #mmr and sss have a special multiplication handler.
  is_mmr(a) && return __mmr_mult(b, sign)
  is_mmr(b) && return __mmr_mult(a, sign)
  is_sss(a) && return __sss_mult(b, sign)
  is_sss(b) && return __sss_mult(a, sign)

  #assign "exact" and "bound" a's
  (exact_a, bound_a) = is_ulp(a) ? (unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK), __outward_exact(a)) : (a, a)
  (exact_b, bound_b) = is_ulp(b) ? (unum_unsafe(b, b.flags & ~UNUM_UBIT_MASK), __outward_exact(b)) : (b, b)

  #find the high and low bounds.  Pass this to a subsidiary function
  far_result  = __mult_exact(bound_a, bound_b, sign)
  near_result = __mult_exact(exact_a, exact_b, sign)

  if (sign != 0)
    ubound_resolve(open_ubound(far_result, near_result))
  else
    ubound_resolve(open_ubound(near_result, far_result))
  end
end

function __mmr_mult{ESS,FSS}(a::Unum{ESS,FSS}, sign::UInt16)
  #mmr_mult only yields something besides mmr if we are multiplying
  #by something between zero and one.
  (decode_exp(a) >= 1) && return mmr(Unum{ESS,FSS}, sign)

  #multiply a times the big_exact value for our unum.  This will determine
  #the inner bound for our ubound.
  val = __mult_exact(a, big_exact(Unum{ESS,FSS}), sign)

  #make sure there the sign bit is set correctly, and that we are using val as a
  #open lower bound, as denoted by the ubit.
  (val.flags != UNUM_UBIT_MASK | sign) && (val = unum_unsafe(val, UNUM_UBIT_MASK | sign))

  #create the appropriate ubounds, directed as appropriate.
  if (sign != 0)
    ubound_resolve(open_ubound(neg_mmr(Unum{ESS,FSS}), val))
  else
    ubound_resolve(open_ubound(val, pos_mmr(Unum{ESS,FSS})))
  end
end

function __sss_mult{ESS,FSS}(a::Unum{ESS,FSS}, sign::UInt16)
  #sss_mult only yields something besides sss if we are multiplying
  #by something between one and infinity.

  (decode_exp(a) < 0 && return sss(Unum{ESS,FSS}, sign))

  a_sub = is_ulp(a) ? __outward_exact(a) : a

  #calculate value.
  val = __mult_exact(a_sub, small_exact(Unum{ESS,FSS}), sign)

  #set the sign of val.
  (val.flags & UNUM_SIGN_MASK != sign) && (val = unum_unsafe(val, UNUM_UBIT_MASK | sign))

  #then create the appropriate ubounds, directed by the desired sign.
  if (sign != 0)
    ubound_resolve(open_ubound(val , neg_sss(Unum{ESS,FSS})))
  else
    ubound_resolve(open_ubound(pos_sss(Unum{ESS,FSS}), val))
  end
end
=#

import Base.*
function *{ESS,FSS}(x::Unum{ESS,FSS}, y::Unum{ESS,FSS})
  temp = zero(Gnum{ESS,FSS})
  mul!(x, y, temp)
  #return the result as the appropriate data type.
  emit_data(temp)
end
