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
    __div_exact(a, b)
  end
end

function __div_ulp{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
end



#helper function all ones.  decides if fraction has enough ones.
function allones(fss)
  (fss < 6) && return ((1 << (1 << fss)) - 1) << (64 - (1 << fss))
  (fss == 6) && return f64
  [f64 for i = 1:__frac_cells(fss)]
end

function __div_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #calculate the amount of accuracy needed roughly scales with fsizesize.
  iters = max(FSS, 3)
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  #cache our allones values
  _allones = allones(FSS)

  negative = (a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK)

  #first bring the numerator into coherence.
  numerator::Uint64 =
  #next bring the denominator into coherence.
  denominator::Uint64 =

  #iteratively improve x.
  for i = 1:iters
    factor::SuperInt = denominator
    (carry, numerator, _) = sfma(carry, numerator, factor)
    (_, denominator, junk) = sfma(z64, denominator, factor)
    allzeros(~denominator & _allones) && break
  end

  #calculate the correct exponent

end
