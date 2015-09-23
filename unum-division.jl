#unum-division.jl - currently uses the goldschmidt method, but will also
#implement other division algorithms.

function /{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #some basic test cases.

  #check NaNs
  (isnan(a) || isnan(b)) && return nan(Unum{ESS,FSS})

  #division by zero is ALWAYS a NaN in unums.
  is_zero(b) && return nan(Unum{ESS,FSS})
  #multiplication by zero is always zero, except 0/0 which is covered above.
  is_zero(a) && return zero(Unum{ESS,FSS})

  #division by inf will almost always be zero.
  if is_inf(b)
    #unless the numerator is also infinite
    is_inf(a) && return nan(Unum{ESS,FSS})
    return zero(Unum{ESS,FSS})
  end

  div_sign::Uint16 = ((a.flags & UNUM_SIGN_MASK) $ (b.flags & UNUM_SIGN_MASK))
  #division from inf is always inf, with a possible sign change
  if is_inf(a)
    return inf(Unum{ESS,FSS}, div_sign)
  end

  #dividing by smaller than small subnormal will yield the entire number line.
  if is_sss(b)
    innerbound = nrd(a, small_exact(Unum{ESS,FSS}, b.flags & UNUM_SIGN_MASK))
    (sss_sign != 0) && return ubound_unsafe(neg_mmr(Unum{ESS,FSS}), innerbound)
    return ubound_resolve(ubound_unsafe(innerbound, pos_mmr(Unum{ESS,FSS})))
  end

  #should have a similar process for mmr.
  if is_mmr(b)
    outerbound = nrd(b, big_exact(Unum{ESS,FSS}, b.flags & UNUM_SIGN_MASK))
    (div_sign != 0) && return ubound_unsafe(outerbound, neg_ssn(Unum{ESS,FSS}))
    return ubound_resolve(ubound_unsafe(pos_ssn(Unum{ESS,FSS}), outerbound))
  end

  #dividing from a smaller than small subnormal
  if is_sss(a)
    outerbound = nrd(small_exact(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK), b)
    (div_sign != 0) && return ubound_unsafe(outerbound, neg_ssn(Unum{ESS,FSS}))
    return ubound_resolve(ubound_unsafe(pos_ssn(Unum{ESS,FSS}), outerbound))
  end

  #and a similar process for mmr
  if is_mmr(a)
    innerbound = nrd(big_exact(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK), a)
    (sss_sign != 0) && return ubound_unsafe(neg_mmr(Unum{ESS,FSS}), innerbound)
    return ubound_resolve(ubound_unsafe(innerbound, pos_mmr(Unum{ESS,FSS})))
  end

  is_unit(b) && return unum_unsafe(a, a.flags $ b.flags)

  if (is_ulp(a) || is_ulp(b))
    __div_ulp(a, b)
  else
    #test for power of two.

    __div_exact(a, b)
  end
end

function __div_ulp{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
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
function __smult(a::SuperInt, b::SuperInt)
  (fraction, _) = Unums.__chunk_mult(a, b)
  carry = one(Uint64)

  #only perform the respective adds if the *opposing* thing is not subnormal.
  ((carry, fraction) = Unums.__carried_add(carry, fraction, b))

  #carry may be as high as three!  So we must shift as necessary.
  (fraction, shift, is_ubit) = Unums.__shift_after_add(carry, fraction, _)
  lsh(fraction, 1)
end


#helper function all ones.  decides if fraction has enough ones.
function allones(fss)
  (fss < 6) && return ((1 << (1 << fss)) - 1) << (64 - (1 << fss))
  (fss == 6) && return f64
  [f64 for i = 1:__frac_cells(fss)]
end

function __div_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  div_length::Uint16 = length(a.fraction) + ((FSS >= 6) ? 1 : 0)
  #figure out the sign.
  sign::Uint16 = (a.flags & UNUM_SIGN_MASK) $ (b.flags & UNUM_SIGN_MASK)

  #calculate the exponent.
  exp_f::Int64 = decode_exp(a) - decode_exp(b) + (issubnormal(a) ? 1 : 0) - (issubnormal(b) ? 1 : 0)

  #first bring the numerator into coherence.
  numerator::SuperInt = (FSS >= 6) ? [z64, a.fraction] : a.fraction

  #save the old numerator.
  if (issubnormal(a))
    shift::Uint64 = clz(numerator) + 1
    numerator = lsh(numerator, shift)
    exp_f -= shift
  end
  _numerator = __copy_superint(numerator)
  carry::Uint64 = 1

  #next bring the denominator into coherence.
  denominator::SuperInt = (FSS >= 6) ? [z64, b.fraction] : b.fraction
  if issubnormal(b)
    shift = clz(denominator)
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
  (exp_f > max_exponent(ESS)) && return (sign != 0) ? neg_mmr(Unum{ESS,FSS}) : neg_mmr(Unum{ESS,FSS})
  (exp_f < min_exponent(ESS) - max_fsize(FSS) - 2) && return (sign != 0) ? neg_sss(Unum{ESS,FSS}) : neg_sss(Unum{ESS,FSS})

  #figure out the mask we need.
  if (FSS <= 5)
    division_mask = fillbits(-(max_fsize(FSS) + 4), o16)
  else
    division_mask = [0xF000_0000_0000_0000, [f64 for idx=1:__frac_cells(FSS)]]
  end

  #println("0:",superbits(numerator))
  #println("0:",superbits(denominator))

  #iteratively improve x.
  for (idx = 1:32)  #we will almost certainly not get to 32 iterations.
    (_, factor) = __carried_diff(o64, ((FSS >= 6) ? zeros(Uint64, div_length) : z64), denominator)
    (carry, numerator) = __sfma(carry, numerator, factor)
    (_, denominator) = __sfma(z64, denominator, factor)

    #println("$idx:",superbits(numerator))
    #println("$idx:",superbits(denominator))

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

  #based on the correct exponent, decide if we need to output a generic.
  (exp_f > max_exponent(ESS)) && return (sign != 0) ? neg_mmr(Unum{ESS,FSS}) : neg_mmr(Unum{ESS,FSS})
  (exp_f < min_exponent(ESS) - max_fsize(FSS)) && return (sign != 0) ? neg_sss(Unum{ESS,FSS}) : neg_sss(Unum{ESS,FSS})

  numerator &= division_mask
  is_ulp::Uint16 = UNUM_UBIT_MASK
  fsize::Uint16 = max_fsize(FSS)

  frac_delta::SuperInt = (FSS < 6) ? (t64 >> max_fsize(FSS)) : [z64, o64, [z64 for idx=1:(__frac_cells(FSS) - 1)]]

  frac_mask::SuperInt = (FSS < 6) ? (fillbits(int64(-(max_fsize(FSS) + 1)), o16)) : [z64, [f64 for idx=1:__frac_cells(FSS)]]
  #check our math to assign ULPs

  reseq = __smult((numerator & frac_mask), _denominator)
  (_, np1) = __carried_add(z64, numerator & frac_mask, frac_delta)
  resph = __smult(np1, _denominator)

  if _numerator < reseq
    println("low")
    (carry, numerator) = __carried_diff(carry, numerator, frac_delta)
  elseif _numerator == reseq
    println("hi mom")
    #decide if this is an exact result.
  elseif _numerator == resph
    println("hi dad")
  elseif _numerator > resph
    println("high")
    (carry, numerator) = __carried_add(carry, numerator, frac_delta)
  end

  (carry < 1) && (numerator = rsh(numerator, 1))
  (carry > 1) && (numerator = lsh(numerator, 1))

  (exp_f < min_exponent(ESS)) && ((exp_f, numerator) = fixsn(ESS, FSS, exp_f, numerator))

  if (FSS < 6)
    fraction = numerator & frac_mask
  elseif (FSS == 6)
    fraction = numerator[2]
  else
    fraction = numerator[2:__frac_cells(FSS)]
  end

  (esize, exponent) = encode_exp(exp_f)

  Unum{ESS,FSS}(fsize, esize, sign | is_ulp, fraction, exponent)
end
