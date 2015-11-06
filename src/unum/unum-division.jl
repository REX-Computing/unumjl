#unum-division.jl - currently uses the goldschmidt method, but will also
#implement other division algorithms.

function /{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #some basic test cases.

  #check NaNs
  (isnan(a) || isnan(b)) && return nan(Unum{ESS,FSS})

  #division by zero is ALWAYS a NaN in unums.
  is_zero(b) && return nan(Unum{ESS,FSS})

  div_sign::UInt16 = ((a.flags & UNUM_SIGN_MASK) $ (b.flags & UNUM_SIGN_MASK))
  #division from inf is always inf (except inf/inf), with a possible sign change
  if is_inf(a)
    is_inf(b) && return nan(Unum{ESS,FSS})
    return inf(Unum{ESS,FSS}, div_sign)
  end
  #division by inf is always zero.
  is_inf(b) && return zero(Unum{ESS,FSS})

  is_unit(b) && return unum_unsafe(a, (a.flags & UNUM_UBIT_MASK) | div_sign)

  if (is_ulp(a) || is_ulp(b))
    __div_ulp(a, b, div_sign)
  else
    __div_exact(a, b, div_sign)
  end
end

#dividing by smaller than small subnormal yields the entire number line beyond
#number / small_exact.
function __div_sss{ESS,FSS}(a::Unum{ESS,FSS}, div_sign::UInt16)
  #decide if we're going to exceed mmr anyways.
  total_exp = decode_exp(a) - min_exponent(ESS) + max_fsize(FSS)
  (total_exp > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, div_sign)

  a_sub = is_exact(a) ? a : __inward_exact(a)
  innerbound = __div_exact(a_sub, small_exact(Unum{ESS,FSS}), div_sign)

  outerbound = mmr(Unum{ESS,FSS}, div_sign)
  return ubound_resolve(open_ubound((div_sign != 0 ? (outerbound, innerbound) : (innerbound, outerbound))...))
end

#dividing by more than maxreal yields all numbers tinier than number / big_exact.
function __div_mmr{ESS,FSS}(a::Unum{ESS,FSS}, div_sign::UInt16)
  #decide if we're going to push beyond ssn
  total_exp = decode_exp(a) - max_exponent(ESS)
  (total_exp < min_exponent(ESS) - max_fsize(FSS)) &&  return sss(Unum{ESS,FSS}, div_sign)

  innerbound = sss(Unum{ESS,FSS}, div_sign)
  a_sub = is_exact(a) ? a : __outward_exact(a)
  outerbound = __div_exact(a_sub, big_exact(Unum{ESS,FSS}), div_sign)
  return ubound_resolve(open_ubound((div_sign != 0 ? (outerbound, innerbound) : (innerbound, outerbound))...))
end

#dividing by small subnormal yields all numbers smaller than number / small subnormal.
function __sss_div{ESS,FSS}(a::Unum{ESS,FSS}, div_sign::UInt16)
  #decide if we're going to actually get any bigger
  (decode_exp(a) > 0) && return sss(Unum{ESS,FSS}, div_sign)

  innerbound = sss(Unum{ESS,FSS}, div_sign)
  outerbound = __div_exact(small_exact(Unum{ESS,FSS}), a, div_sign)
  return ubound_resolve(open_ubound((div_sign != 0 ? (outerbound, innerbound) : (innerbound, outerbound))...))
end

function __mmr_div{ESS,FSS}(a::Unum{ESS,FSS}, div_sign::UInt16)
  (decode_exp(a) < 0) && return mmr(Unum{ESS,FSS}, div_sign)

  a_sub = is_exact(a) ? a : __outward_exact(a)

  innerbound = __div_exact(big_exact(Unum{ESS,FSS}), a_sub, div_sign)
  outerbound = mmr(Unum{ESS,FSS}, div_sign)
  return ubound_resolve(open_ubound((div_sign != 0 ? (outerbound, innerbound) : (innerbound, outerbound))...))
end

function __div_ulp{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, div_sign::UInt16)
  is_zero(a) && return zero(Unum{ESS,FSS})

  is_sss(b) && return __div_sss(a, div_sign)
  is_sss(a) && return __sss_div(b, div_sign)
  is_mmr(a) && return __mmr_div(b, div_sign)
  is_mmr(b) && return __div_mmr(a, div_sign)

  #assign "exact" and "bound" a's
  (exact_a, bound_a) = is_ulp(a) ? (unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK), __outward_exact(a)) : (a, a)
  (exact_b, bound_b) = is_ulp(b) ? (unum_unsafe(b, b.flags & ~UNUM_UBIT_MASK), __outward_exact(b)) : (b, b)
  #find the high and low bounds.  Pass this to a subsidiary function
  far_result  = __div_exact(bound_a, exact_b, div_sign)
  near_result = __div_exact(exact_a, bound_b, div_sign)
  if ((a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK))
    ubound_resolve(open_ubound(far_result, near_result))
  else
    ubound_resolve(open_ubound(near_result, far_result))
  end
end

#sfma is "simple fused multiply add".  Following assumptions hold:
#first, number has the value 1.XXXXXXX, factor is
function __sfma(carry, number, factor)
  (fracprod, _) = Unums.__chunk_mult(number, factor)
  (_carry, fracprod) = Unums.__carried_add(carry, number, fracprod)
  ((carry & 0x1) != 0) && ((_carry, fracprod) = Unums.__carried_add(_carry, factor, fracprod))
  ((carry & 0x2) != 0) && ((_carry, fracprod) = Unums.__carried_add(_carry, lsh(factor, 1), fracprod))
  (_carry, fracprod)
end

#performs a simple multiply, Assumes that number 1 has a hidden bit of exactly one
#and number 2 has a hidden bit of exactly zero
#(1 + a)(0 + b) = b + ab
function __smult(a::VarInt, b::VarInt)
  (fraction, _) = Unums.__chunk_mult(a, b)
  carry = one(UInt64)

  #only perform the respective adds if the *opposing* thing is not subnormal.
  ((carry, fraction) = Unums.__carried_add(carry, fraction, b))

  #carry may be as high as three!  So we must shift as necessary.
  (fraction, shift, is_ubit) = Unums.__shift_after_add(carry, fraction, _)
  lsh(fraction, 1)
end

const __EXACT_INDEX_TABLE = [0, 0, 0, 0, 0, 0, 2, 3, 5, 9, 17, 33, 65]
const __HALFMASK_TABLE = [0xEFFF_FFFF_FFFF_FFFF, 0xCFFF_FFFF_FFFF_FFFF, 0x0FFF_FFFF_FFFF_FFFF, 0x00FF_FFFF_FFFF_FFFF, 0x0000_FFFF_FFFF_FFFF, 0x0000_0000_FFFF_FFFF]

function __check_exact(a::VarInt, b::VarInt, fss)
  if (fss == 0)
    return a == b
  elseif (fss < 6)
    return ((a & __HALFMASK_TABLE[fss]) == 0) && ((b & __HALFMASK_TABLE[fss]) == 0)
  elseif (fss == 6)
    return (a[1] == 0) && (b[1] == 0) && (a[2] & __HALFMASK_TABLE[6] == 0) && (b[2] & __HALFMASK_TABLE[6] == 0)
  elseif (fss > 6)
    #possibly, a is all zero.
    for idx = 1:__EXACT_INDEX_TABLE[fss]
      ((a[idx] != 0) || (b[idx] != 0)) && return false
    end
    return true
  end
end

#helper function all ones.  decides if fraction has enough ones.
function allones(fss)
  (fss < 6) && return ((1 << (1 << fss)) - 1) << (64 - (1 << fss))
  (fss == 6) && return f64
  [f64 for i = 1:__frac_cells(fss)]
end

function __div_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, sign::UInt16)
  #multiplication by zero is always zero, except 0/0 which is covered by
  #division by zero rule in the outer division function.
  is_zero(a) && return zero(Unum{ESS,FSS})
  #division by inf will almost always be zero.
  if is_inf(b)
    #unless the numerator is also infinite
    is_inf(a) && return nan(Unum{ESS,FSS})
    return zero(Unum{ESS,FSS})
  end

  div_length::UInt16 = length(a.fraction) + ((FSS >= 6) ? 1 : 0)

  #calculate the exponent.
  exp_f::Int64 = decode_exp(a) - decode_exp(b) + (issubnormal(a) ? 1 : 0) - (issubnormal(b) ? 1 : 0)

  #first bring the numerator into coherence.
  numerator::VarInt = (FSS >= 6) ? [z64, a.fraction] : a.fraction

  #save the old numerator.
  if (issubnormal(a))
    shift::UInt64 = leading_zeros(numerator) + 1
    numerator = lsh(numerator, shift)
    exp_f -= shift
  end
  _numerator = __copy_superint(numerator)
  carry::UInt64 = 1

  #next bring the denominator into coherence.
  denominator::VarInt = (FSS >= 6) ? [z64, b.fraction] : b.fraction
  if issubnormal(b)
    shift = leading_zeros(denominator)
    denominator = lsh(denominator, shift)
    exp_f += shift
  else
    #shift the phantom one over.
    denominator = rsh(denominator, 1) | fillbits(-1, div_length)
    exp_f -= 1
  end

  #save the old denominator.
  _denominator = __copy_superint(denominator)

  #bail out if the exponent is too big or too small.
  (exp_f > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, sign)
  (exp_f < min_exponent(ESS) - max_fsize(FSS) - 2) && return sss(Unum{ESS,FSS}, sign)

  is_ulp::UInt16 = z16
  frac_mask::VarInt = (FSS < 6) ? (fillbits(int64(-(max_fsize(FSS) + 1)), o16)) : [z64, [f64 for idx=1:__frac_cells(FSS)]]

  if (!justtop(denominator))
    #figure out the mask we need.
    if (FSS <= 5)
      division_mask = fillbits(-(max_fsize(FSS) + 4), o16)
    else
      division_mask = [0xF000_0000_0000_0000, [f64 for idx=1:__frac_cells(FSS)]]
    end

    #iteratively improve x.
    for (idx = 1:32)  #we will almost certainly not get to 32 iterations.
      (_, factor) = __carried_diff(o64, ((FSS >= 6) ? zeros(UInt64, div_length) : z64), denominator)
      (carry, numerator) = __sfma(carry, numerator, factor)
      (_, denominator) = __sfma(z64, denominator, factor)

      allzeros(~denominator & division_mask) && break
      #note that we could mask out denominator and numerator with "division_mask"
      #but we're not going to bother.
    end

    #append the carry, shift exponent as necessary.
    if carry > 1
      numerator = rsh(numerator, 1) | (carry & 0x1 << 63)
      carry = 1
      exp_f += 1
    end

    numerator &= division_mask
    is_ulp = UNUM_UBIT_MASK
    fsize::UInt16 = max_fsize(FSS)

    frac_delta::VarInt = (FSS < 6) ? (t64 >> max_fsize(FSS)) : [z64, o64, [z64 for idx=1:(__frac_cells(FSS) - 1)]]
    #check our math to assign ULPs

    reseq = __smult((numerator & frac_mask), _denominator)
    (carry2, np1) = __carried_add(o64, numerator & frac_mask, frac_delta)
    resph = __smult(np1, _denominator)

    if _numerator < reseq
      (carry, numerator) = __carried_diff(carry, numerator, frac_delta)
    #if being exact is possible, run a check exact.
    elseif _numerator == reseq
      __check_exact(numerator, _denominator, FSS) && (is_ulp = 0)
    elseif _numerator == resph
      __check_exact(np1, _denominator, FSS) && (is_ulp = 0)
      (carry, numerator) = (carry2, np1)
    elseif _numerator > resph
      (carry, numerator) = (carry2, np1)
    end

    #question:: Do we need to shift the exp_f as well here?
    (carry < 1) && (numerator = rsh(numerator, 1))
    (carry > 1) && (numerator = lsh(numerator, 1))
  else
    #note that when we pass this calculation step, the denominator is exactly 0.5
    #so we must augment the result exponent by one.
    exp_f += 1
  end

  (exp_f < min_exponent(ESS)) && return __amend_to_subnormal(Unum{ESS,FSS}, numerator, exp_f, is_ulp | sign)

  (esize, exponent) = encode_exp(exp_f)

  if (FSS < 6)
    fraction = numerator & frac_mask
  elseif (FSS == 6)
    fraction = numerator[2]
  else
    fraction = numerator[2:end]
  end

  (is_ulp & UNUM_UBIT_MASK == 0) && (fsize = __minimum_data_width(fraction))

  Unum{ESS,FSS}(fsize, esize, sign | is_ulp, fraction, exponent)
end
