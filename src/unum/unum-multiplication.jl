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
  set_g_flags!(a)
  mul!(a, c)
end

function mul!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  clear_ignore_sides!(b)
  set_g_flags!(a)
  __multiplication_override_check!(a, b)
  is_negative(a) && parity_swap!(b)
  #do the parity swap.  From here on, all procedures assume that a is positive.

  should_calculate(b, LOWER_UNUM) && __multiplication_soft_calc(a, b, LOWER_UNUM)
  should_calculate(b, UPPER_UNUM) && __multiplication_soft_calc(a, b, UPPER_UNUM)

  if is_onesided(b)
    if is_exact(a)
      if is_exact(b.lower)
        should_calculate(b, LOWER_UNUM) && __signless_exact_multiply!(a, b, LOWER_UNUM)
      else
        set_twosided!(b)
        copy_unum!(b.lower, b.upper)
        #do the upper side calculation.
        onesided_mult(a, b, UPPER_UNUM)
        #do the lower side calculation.
        onesided_mult(a, b, LOWER_UNUM)
      end
    else
      if is_exact(b.lower)
        if should_calculate(b, LOWER_UNUM)
          set_twosided!(b)
          #move b to the buffer.
          copy_unum!(b.lower, b.buffer)
          #copy a to both sides of the unum.
          put_unum!(a, b, LOWER_UNUM)
          put_unum!(a, b, UPPER_UNUM)
          b.lower.flags = (b.lower.flags & ~UNUM_SIGN_MASK) | (b.buffer.flags & UNUM_SIGN_MASK)
          b.upper.flags = (b.upper.flags & ~UNUM_SIGN_MASK) | (b.buffer.flags & UNUM_SIGN_MASK)
          onesided_mult(b.buffer, b, UPPER_UNUM)
          onesided_mult(b.buffer, b, LOWER_UNUM)
        end
      else
      end
    end
  else
    nan!(b)
  end
end

#multiplies an exact number times one of the sides of the number.
@generated function onesided_mult{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  paritycheck = symbol((side == :upper) ? "is_positive" : "is_negative" )
  exactfn = symbol(side, "_exact!")
  ulpfn = symbol((side == :upper) ? "lower_ulp!" : "upper_ulp!")
  quote
    $paritycheck(b.$side) ? $exactfn(b.$side) : make_exact!(b.$side)
    __multiplication_soft_calc(a, b, Val{side})
    should_calculate(b, Val{side}) &&  __signless_exact_multiply!(a, b, Val{side})
    force_from_flags!(b, b.$side, Val{side})
    is_exact(b.$side) && $ulpfn(b.$side)
  end
end

#soft_calcs
@generated function __multiplication_soft_calc{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  quote
    (is_g_zero(b.$side) || is_zero(b.$side)) && (zero!(b, Val{side}); ignore_side!(b, Val{side}))
    is_unit(a) && (ignore_side!(b, Val{side}))
    if is_unit(b.$side)
      temp_sign::UInt16 = b.$side.flags & UNUM_SIGN_MASK
      copy_unum_with_gflags!(a, b.$side)
      #we need to also copy over the sign flag.
      b.$side.flags = (b.$side.flags & ~UNUM_SIGN_MASK) | temp_sign
      ignore_side!(b,Val{side})
    end
  end
end

#multiplication override is split into a "hard check" and some "soft checks".  The
#hard checks have to be done globally, while the "soft checks" are done on
#individual streams.
function __multiplication_override_check!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  ############################################
  # deal with NaNs.
  #if our multiplicand is nan, then set the product to nan.
  is_nan(a) && (@scratch_this_operation!(b))
  is_nan(b) && (ignore_both_sides!(b); return)

  if (is_g_inf(a))
    #infinity can't multiply across zero.
    is_twosided(b) && ((b.lower.flags & UNUM_SIGN_MASK) != (b.upper.flags & UNUM_SIGN_MASK)) && (@scratch_this_operation!(b))
    #infinity can't multiply times just zero, either
    should_calculate(b, LOWER_UNUM) && is_zero(b, LOWER_UNUM) && (@scratch_this_operation!(b))
    should_calculate(b, UPPER_UNUM) && is_zero(b, LOWER_UNUM) && (@scratch_this_operation!(b))
    #set to onesided.
    inf!(b, (b.lower.flags & UNUM_SIGN_MASK), LOWER_UNUM); ignore_side!(b, LOWER_UNUM); set_onesided!(b)
  end
  #next, check that infinities on either side don't mess things up.
  if should_calculate(b, LOWER_UNUM) && is_inf(b, LOWER_UNUM)
    is_g_zero(a) && (@scratch_this_operation!(b))
    ignore_side!(b, LOWER_UNUM)
  end
  if should_calculate(b, UPPER_UNUM) && is_inf(b, UPPER_UNUM)
    is_g_zero(a) && (@scratch_this_operation!(b))
    ignore_side!(b, UPPER_UNUM)
  end
  #finally, check if a is zero, in which case we can just nuke everything.
  if is_g_zero(a)
    zero!(b, LOWER_UNUM)
    set_onesided!(b)
    ignore_side!(b, LOWER_UNUM)
  end
  #finally check if a is one, in which case we just leave all alone.
  if is_unit(a)
    ignore_both_sides!(b)
  end
end

@gen_code function __signless_exact_multiply!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  max_exp = max_exponent(ESS)
  sml_exp = min_exponent(ESS, FSS)
  min_exp = min_exponent(ESS)

  @code quote
    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b.$side)
    a_dev::UInt64 = is_exp_zero(a) * o64
    b_dev::UInt64 = is_exp_zero(b.$side) * o64

    b.scratchpad.flags |= b.$side.flags & UNUM_SIGN_MASK

    scratchpad_exp::Int64 = a_exp + b_exp + a_dev + b_dev
    #preliminary comparisons that will stop us from performing unnecessary
    #steps.
    (scratchpad_exp > $max_exp + 1) && (@preserve_sflags b mmr!(b, b.$side.flags & UNUM_SIGN_MASK, Val{$side}); return)
    (scratchpad_exp < $sml_exp - 2) && (@preserve_sflags b sss!(b, b.$side.flags & UNUM_SIGN_MASK, Val{$side}); return)
  end

  if FSS < 6
    @code :(b.scratchpad.fraction = __chunk_mult_small(a.fraction, b.$side.fraction))
  elseif FSS == 6
    :(nan!(b))
  else
    :(nan!(b))
  end

  @code quote
    #fraction multiplication:  where va is "virtual bit" that is 1 for normals or 0 for subnormals.
    #  va + a
    #  vb + b
    #  va*vb + vb * a + va * b + ab
    #
    carry::UInt64 = o64 - (a_dev | b_dev) #if either a or b is subnormal, the carry is zero.
    #note that adding the fractions back in has a cross-multiplied effect.
    (b_dev == 0) && (carry = __carried_add_frac!(carry, a, b.scratchpad))
    (a_dev == 0) && (carry = __carried_add_frac!(carry, b.$side, b.scratchpad))
    #next, do carry analysis. carry can be 0, 1, 2, or 3 at the most.

    if (carry == 0)
      #shift over the fraction as far as we need to.
      shift::Int64 = leading_zeros(b.scratchpad.fraction) + 1
    else
      scratchpad_exp += 1
      if scratchpad_exp > $max_exp
        @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)
      else
        #shift things over by one since we went up in size.
        __rightshift_frac_with_underflow_check!(b.scratchpad, 1)
        #carry from the carry over into the fraction.
        (carry == 3) && set_frac_top!(b.scratchpad)
        #re-encode the exponent.
        (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
      end
    end

    copy_unum_with_gflags!(b.scratchpad, b.$side)
    #(b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
    #flip the ubit.
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
