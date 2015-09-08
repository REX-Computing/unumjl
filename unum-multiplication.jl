#unum-multiplication.jl
#does multiplication for unums.

function *{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #count how many uints go into the unum.
  #we can break this up into two cases, and maybe merge them later.
  #remember, a and b must have the same environment.

  #some obviously simple checks.
  #check for nans
  (isnan(a) || isnan(b)) && return nan(Unum{ESS,FSS})
  #check for infinities
  (isinf(a) || isinf(b)) && return ((a.flags & UNUM_SIGN_MASK) == (b.flags & UNUM_SIGN_MASK)) ? pos_inf(Unum{ESS,FSS}) : neg_inf(Unum{ESS,FSS})

  #zero checking
  (iszero(a) || iszero(b)) && return zero(Unum{ESS,FSS})
  #one checking
  (isone(a)) && return b
  (isone(b)) && return a

  #check to see if we're an ulp.
  if (is_ulp(a) || is_ulp(b))
    __mult_ulp(a, b)
  else
    __mult_exact(a, b)
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
# Uint64 in front to handle that.

function __lower_scan(a::Array{Uint32, 1}, b::Array{Uint32, 1}, l::Uint16)
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
  l::Uint16 = length(a) << 1

  #take these two Uint64 arrays and reinterpret them as Uint32 arrays
  a_32 = reinterpret(Uint32, (l == 2) ? [a] : a)
  b_32 = reinterpret(Uint32, (l == 2) ? [b] : b)

  #scan the lower bits to see if we are ulp.
  ulp_flag::Uint16 = __lower_scan(a_32, b_32, l)

  #the scratchpad must have an initial segment to determine carries.
  scratchpad = zeros(Uint32, l + 1)
  #create an array for carries.
  carries    = zeros(Uint32, l)
  #populate the column just before the left carry. first indexsum is length(a_32)
  for (aidx = 1:(l - 1))
    #skip this if either is a zero
    (a_32[aidx] == 0) || (b_32[l-aidx] == 0) && continue

    #do a mulitply of the two numbers into a 64-bit integer.
    temp_res::Uint64 = a_32[aidx] * b_32[l - aidx]
    #in this round we just care about the high 32-bit register
    temp_res_high::Uint32 = (temp_res >> 32)

    scratchpad[1] += temp_res_high
    (scratchpad[1] < temp_res_high) && (carries[1] += 1)
  end

  #now proceed with the rest of the additions.
  for aidx = 1:l
    a_32[aidx] == 0 && continue
    for bidx = (l + 1 - aidx):l
      b_32[bidx] == 0 && continue

      temp_res = a_32[aidx] * b_32[bidx]
      temp_res_low::Uint32 = temp_res
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

  (l == 2) && return ((uint64(scratchpad[3]) << 32) | scratchpad[2], ulp_flag)
  (reinterpret(Uint64, scratchpad[(l >> 1):length(scratchpad)]), ulp_flag)
end

#performs an exact mult on two unums a and b.
function __mult_exact{ESS, FSS}(a::Unum{ESS,FSS},b::Unum{ESS,FSS})
  #figure out the sign.  Xor does the trick.
  flags = (a.flags & UNUM_SIGN_MASK) $ (b.flags & UNUM_SIGN_MASK)
  #calculate and cache _aexp and _bexp
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  #preliminary overflow and underflow tests save us from calculations in the
  #case these are definite outcomes.
  (_aexp + _bexp > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, flags)
  (_aexp + _bexp < min_exponent(ESS) - 3) && return ssn(Unum{ESS,FSS}, flags)

  #run a chunk_mult on the a and b fractions
  (fraction, res_ulp) = __chunk_mult(a.fraction, b.fraction)
  flags |= res_ulp
  #next, steal the carried add function from addition.  We're going to need
  #to re-add the fractions back due to algebra with the phantom bit.
  #
  # i.e.: (1 + a)(1 + b) = 1 + a + b + ab
  # => initial carry + a.fraction + b.fraction + chunkproduct
  #
  (carry, fraction) = __carried_add(o64, fraction, a.fraction)
  (carry, fraction) = __carried_add(carry, fraction, b.fraction)

  #carry may be as high as three!  So we must shift as necessary.
  (fraction, shift, check) = __shift_after_add(carry, fraction)
  #for now, just throw fsize as exact fsize.
  fsize = __fsize_of_exact(fraction)
  #the exponent is just the sum of the two exponents.
  unbiased_exp::Int16 = _aexp + _bexp + shift
  #have to repeat the overflow and underflow tests in light of carry shifts.
  (unbiased_exp > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, flags)
  (unbiased_exp < min_exponent(ESS)) && return ssn(Unum{ESS,FSS}, flags)
  (esize, exponent) = encode_exp(unbiased_exp)
  #deal with ubit later.
  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end

function __mult_ulp{ESS, FSS}(a::Unum{ESS,FSS},b::Unum{ESS,FSS})
  #because zero cannot be traversed by the ulp, we can do something very simple
  #here.

  #mmr and ssn have a special multiplication handler.
  is_mmr(a) && return __mmr_mult(b, ((a.flags & UNUM_SIGN_MASK) == (b.flags & UNUM_SIGN_MASK)))
  is_mmr(b) && return __mmr_mult(a, ((a.flags & UNUM_SIGN_MASK) == (b.flags & UNUM_SIGN_MASK)))
  is_ssn(a) && return __ssn_mult(b, ((a.flags & UNUM_SIGN_MASK) == (b.flags & UNUM_SIGN_MASK)))
  is_ssn(b) && return __ssn_mult(a, ((a.flags & UNUM_SIGN_MASK) == (b.flags & UNUM_SIGN_MASK)))

  #assign "exact" and "bound" a's
  (exact_a, bound_a) = is_ulp(a) ? (unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK), __outward_exact(a)) : (a, a)
  (exact_b, bound_b) = is_ulp(b) ? (unum_unsafe(b, b.flags & ~UNUM_UBIT_MASK), __outward_exact(b)) : (b, b)

  #find the high and low bounds.  Pass this to a subsidiary function
  far_result  = __mult_exact(bound_a, bound_b)
  near_result = __mult_exact(exact_a, exact_b)

  if ((a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK))
    ubound_resolve(open_ubound(far_result, near_result))
  else
    ubound_resolve(open_ubound(near_result, far_result))
  end
end

function __mmr_mult{ESS,FSS}(a::Unum{ESS,FSS}, sign::Uint16)
  #mmr_mult only yields something besides mmr if we are multiplying
  #by something between zero and one.
  (decode_exp(a) >= 0) && return mmr(Unum{ESS,FSS}, sign)

  #multiply a times the big_exact value for our unum.  This will determine
  #the inner bound for our ubound.
  val = __mult_exact(a, big_exact(Unum{ESS,FSS}))

  #make sure there the sign bit is set correctly, and that we are using val as a
  #open lower bound, as denoted by the ubit.
  (val.flags != UNUM_UBIT_MASK | sign) && (val = unum_unsafe(val, UNUM_UBIT_MASK | sign))

  #create the appropriate ubounds, directed as appropriate.
  if (sign != 0)
    Ubound(neg_mmr(Unum{ESS,FSS}), val)
  else
    Ubound(val, pos_mmr(Unum{ESS,FSS}))
  end
end

function __ssn_mult{ESS,FSS}(a::Unum{ESS,FSS}, sign::Uint16)
  #ssn_mult only yields something besides ssn if we are multiplying
  #by something between one and infinity.
  (decode_exp(a) < 0 && return ssn(Unum{ESS,FSS}, sign))

  #calculate value.
  val = __mult_exact(a, small_exact(Unum{ESS,FSS}))

  #highly unlikely, but we need to take care of this case.
  is_exact(val) && (val = inward_ulp(val))

  #set the sign of val.
  (val.flags & UNUM_SIGN_MASK != sign) && (val = unum_unsafe(val, UNUM_UBIT_MASK | sign))

  #then create the appropriate ubounds, directed by the desired sign.
  if (sign != 0)
    ubound_resolve(Ubound(val , neg_ssn(Unum{ESS,FSS})))
  else
    ubound_resolve(Ubound(pos_ssn(Unum{ESS,FSS}), val))
  end
end
