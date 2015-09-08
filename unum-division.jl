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
    (sss_sign != 0) && return Ubound(neg_mmr(Unum{ESS,FSS}), innerbound)
    return ubound_resolve(Ubound(innerbound, pos_mmr(Unum{ESS,FSS})))
  end

  #should have a similar process for mmr.
  if is_mmr(b)
    outerbound = nrd(b, big_exact(Unum{ESS,FSS}, b.flags & UNUM_SIGN_MASK))
    (div_sign != 0) && return Ubound(outerbound, neg_ssn(Unum{ESS,FSS}))
    return ubound_resolve(Ubound(pos_ssn(Unum{ESS,FSS}), outerbound))
  end

  #dividing from a smaller than small subnormal
  if is_sss(a)
    outerbound = nrd(small_exact(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK), b)
    (div_sign != 0) && return Ubound(outerbound, neg_ssn(Unum{ESS,FSS}))
    return ubound_resolve(Ubound(pos_ssn(Unum{ESS,FSS}), outerbound))
  end

  #and a similar process for mmr
  if is_mmr(a)
    innerbound = nrd(big_exact(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK), a)
    (sss_sign != 0) && return Ubound(neg_mmr(Unum{ESS,FSS}), innerbound)
    return ubound_resolve(Ubound(innerbound, pos_mmr(Unum{ESS,FSS})))
  end

  is_unit(b) && return unum_unsafe(a, a.flags $ b.flags)

  nrd(a, b)
end

function nrd{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #calculate the amount of accuracy needed roughly scales with fsizesize.
  iters = max(FSS, 3)
  aexp = decode_exp(a)
  bexp = decode_exp(b)
  divfactor = bexp + 1

  negative = (a.flags & SIGN_MASK) != (b.flags & SIGN_MASK)

  #reset the exponentials for both a and b, and strip the sign
  (esize, exponent) = encode_exp(aexp - divfactor)
  a.esize = esize
  a.exponent = exponent
  a.flags &= ~ SIGN_MASK
  (esize, exponent) = encode_exp(bexp - divfactor)
  b.esize = esize
  b.exponent = exponent
  b.flags &= ~ SIGN_MASK

  #consider implementing this as a lookup table.
  nr_1 = one(Unum{ESS,FSS})
  nr_2 = convert(Unum{ESS,FSS}, 48/17)
  nr_3 = convert(Unum{ESS,FSS}, 32/17)

  #generate the test term for b^-1
  x = nr_2 - nr_3 * b

  #iteratively improve x.
  for i = 1:iters
    x = x + (x * (nr_1 - (b * x)))
  end

  #return a * x
  negative ? -(a * x) : a * x
end
