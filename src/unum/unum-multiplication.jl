#unum-multiplication.jl
#does multiplication for unums.

function *{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #count how many uints go into the unum.
  #we can break this up into two cases, and maybe merge them later.
  #remember, a and b must have the same environment.

  #some obviously simple checks.
  #check for nans
  (isnan(a) || isnan(b)) && return nan(Unum{ESS,FSS})

  #evaluate the sign of the result.
  mult_sign::UInt16 = ((a.flags & UNUM_SIGN_MASK) $ (b.flags & UNUM_SIGN_MASK))

  #check for infinities
  if (isinf(a))
    return is_zero(b) ? nan(Unum{ESS,FSS}) : inf(Unum{ESS,FSS}, mult_sign)
  end

  if (isinf(b))
    return is_zero(a) ? nan(Unum{ESS,FSS}) : inf(Unum{ESS,FSS}, mult_sign)
  end

  #zero checking
  (is_zero(a) || is_zero(b)) && return zero(Unum{ESS,FSS})
  #one checking
  (is_unit(a)) && return (unum_unsafe(b, (b.flags & UNUM_UBIT_MASK) | mult_sign))
  (is_unit(b)) && return (unum_unsafe(a, (a.flags & UNUM_UBIT_MASK) | mult_sign))

  #check to see if we're an ulp.
  if (is_ulp(a) || is_ulp(b))
    __mult_ulp(a, b, mult_sign)
  else
    __mult_exact(a, b, mult_sign)
  end
end

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

# chunk_mult handles simply the chunked multiply of two superints
function __chunk_mult(a::SuperInt, b::SuperInt)
  #note that frag_mult fails for absurdly high length integer arrays.
  l::UInt16 = length(a) << 1

  #take these two UInt64 arrays and reinterpret them as UInt32 arrays
  a_32 = reinterpret(UInt32, (l == 2) ? [a] : a)
  b_32 = reinterpret(UInt32, (l == 2) ? [b] : b)

  #scan the lower bits to see if we are ulp.
  ulp_flag::UInt16 = __lower_scan(a_32, b_32, l)

  #the scratchpad must have an initial segment to determine carries.
  scratchpad = zeros(UInt32, l + 1)
  #create an array for carries.
  carries    = zeros(UInt32, l)
  #populate the column just before the left carry. first indexsum is length(a_32)
  for (aidx = 1:(l - 1))
    #skip this if either is a zero
    (a_32[aidx] == 0) || (b_32[l-aidx] == 0) && continue

    #do a mulitply of the two numbers into a 64-bit integer.
    temp_res::UInt64 = a_32[aidx] * b_32[l - aidx]
    #in this round we just care about the high 32-bit register
    temp_res_high::UInt32 = (temp_res >> 32)

    scratchpad[1] += temp_res_high
    (scratchpad[1] < temp_res_high) && (carries[1] += 1)
  end

  #now proceed with the rest of the additions.
  for aidx = 1:l
    a_32[aidx] == 0 && continue
    for bidx = (l + 1 - aidx):l
      b_32[bidx] == 0 && continue

      temp_res = a_32[aidx] * b_32[bidx]
      temp_res_low::UInt32 = temp_res
      temp_res_high = (temp_res >> 32)

      scratchindex = aidx + bidx - l

      scratchpad[scratchindex] += temp_res_low
      (temp_res_low > scratchpad[scratchindex]) && (carries[scratchindex] += 1)

      scratchpad[scratchindex + 1] += temp_res_high
      (temp_res_high > scratchpad[scratchindex + 1]) && (carries[scratchindex + 1] += 1)
    end
  end

  #go through and resolve the carries.
  for idx = 1:length(carries)
    scratchpad[idx + 1] += carries[idx]
    #don't worry, this is mathematically forbidden from tripping on the last carry.
    (scratchpad[idx + 1] < carries[idx]) && (carries[idx + 1] += 1)
  end

  #check to make sure the lowest register in the scratchpad is zero.
  (scratchpad[1] != 0) && (ulp_flag |= UNUM_UBIT_MASK)

  (l == 2) && return ((UInt64(scratchpad[3]) << 32) | scratchpad[2], ulp_flag)

  (reinterpret(UInt64, scratchpad[2:end]), ulp_flag)
end

#amends a fraction to a subnormal number if necessary.
function __amend_to_subnormal{ESS,FSS}(T::Type{Unum{ESS,FSS}}, fraction::UInt64, unbiased_exp::Integer, flags::UInt16)
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
    shift::Int64 = int64(clz(fraction) + 1)
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
