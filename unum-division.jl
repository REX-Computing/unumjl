#unum-division.jl - currently uses the newton-raphson method, but will also
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

  __div_exact(a, b)
end

function __div_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #calculate the amount of accuracy needed roughly scales with fsizesize.
  iters = max(FSS-2, 3)
  aexp = decode_exp(a)
  bexp = decode_exp(b)
  divfactor = bexp + 2

  negative = (a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK)

  #reset the exponentials for both a and b, and strip the sign
  (esize, exponent) = encode_exp(aexp - divfactor)
  a = Unum{ESS,FSS}(a.fsize, esize, a.flags $ ~UNUM_SIGN_MASK, a.fraction, exponent)

  (esize, exponent) = encode_exp(bexp - divfactor)
  b = Unum{ESS,FSS}(b.fsize, esize, b.flags $ ~UNUM_SIGN_MASK, b.fraction, exponent)

  #consider implementing this as a lookup table.
  nr_1 = one(Unum{ESS,FSS})
  nr_2 = convert(Unum{ESS,FSS}, 48/17)
  nr_3 = convert(Unum{ESS,FSS}, 32/17)

  #generate the test term for b^-1
  t1 = __mult_exact(nr_3, b)
  x = __diff_exact(magsort(nr_2, t1)...)

  #iteratively improve x.
  for i = 1:iters

    t3 = __mult_exact(b, x)
    t4 = -__diff_exact(magsort(nr_1, t3)...)
    t5 = __mult_exact(x, t4)
    x = __sum_exact(magsort(x, t5)...)
  end

  #return a * x
  negative ? -(__mult_exact(a, x)) : __mult_exact(a, x)
end
