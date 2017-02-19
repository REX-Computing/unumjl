#ubounds-resolve.jl - contains functions which operate on two unum values that
#are meant to go into ubounds.

if options[:devmode]
  macro check_resolve()
    esc(quote
      options[:devmode] && (lower >= upper) && throw(ArgumentError("unum constructors must be well-ordered"))
    end)
  end
else
  macro check_resolve(); :(); end
end

@universal function set_zero_exp!(value::Unum, to_match::Unum)
  if (decode_exp(to_match) >= 0)
    value.esize = z16
    value.fsize = z16
  else
    test_exponent = decode_exp(to_match.esize - o16, z64)
    if (test_exponent - max_fsize(FSS)) > decode_exp(to_match)
      value.esize = to_match.esize
      value.fsize = to_match.fsize
    else
      value.esize = to_match.esize - o16
      value.fsize = test_exponent - decode_exp(to_match)
    end
  end
end

doc"""
  `Unums.resolve_as_utype!(::Unum, ::Unum)`
  checks to see if the two unums, which must both be ulps, can be resolved to a
  single unum.  If that is possible, it returns the new unum.  Otherwise, it
  returns a ubound with the same values.

  Importantly, this function must be allowed to take possession of the two
  numbers.
"""
@universal function resolve_as_utype!(lower::Unum, upper::Unum)
  @ensure_ulp(lower)
  @ensure_ulp(upper)

  (lower == upper) && return lower

  #check to make sure the signs are the same.
  (@signof(lower) == @signof(upper)) || return B(lower, upper)

  #check to see if they're both zero ulps
  if is_zero_ulp(lower) && is_zero_ulp(upper)
    _lexp = decode_exp(lower) - lower.fsize
    _uexp = decode_exp(upper) - upper.fsize
    (_lexp < _uexp) && return upper
    return lower
  end

  #if only one is a zero_ulp.
  if is_zero_ulp(lower) && (decode_exp(upper) < 0)
    #check to see if we can subsume.
    lubu = lub(upper)
    test_exponent = decode_exp(lubu.esize - o16, z64)
    if (lubu.fraction == z64)
      if (test_exponent - max_fsize(FSS) <= decode_exp(lubu))
        lower.esize = lubu.esize - o16
        lower.fsize = test_exponent - decode_exp(lubu)
        return lower
      end
    end
  end

  if is_zero_ulp(upper) && (decode_exp(lower) < 0)
    glbl = glb(lower)
    test_exponent = decode_exp(glbl.esize - o16, z64)
    if (glbl.fraction == z64) && (test_exponent - max_fsize(FSS) <= decode_exp(glbl))
      upper.esize = glbl.esize - o16
      upper.fsize = test_exponent - decode_exp(glbl)
      return upper
    end
  end

  #check to make sure the exponents are the same.
  (decode_exp(lower) == decode_exp(upper)) || return B(lower, upper)

  (lower.fraction == upper.fraction) && return lower

  #discriminate between negative and positive numbers, which have their bounds
  #differently.
  local cfsize::UInt16
  if is_positive(lower)
    #firstly, the inner ubound is privileged and must be longer than the upper.
    cfsize = contract_outer_fsize(upper.fraction, upper.fsize)
    cfsize = max(cfsize, contract_inner_fsize(lower.fraction, lower.fsize))
  else
    cfsize = contract_outer_fsize(lower.fraction, lower.fsize)
    cfsize = max(cfsize, contract_inner_fsize(upper.fraction, upper.fsize))
  end

  same_till_fsize(upper.fraction, lower.fraction, cfsize) || return B(lower, upper)

  #special case where we can't coalesce them into two unums.
  if cfsize == 0
    lower.fsize = 0
    upper.fsize = 0

    if is_negative(upper)
      frac_top!(lower)
    else
      frac_top!(upper)
    end

    return B(lower, upper)
  end
  lower.fsize = cfsize - o16
  frac_trim!(lower, lower.fsize)
  return lower
end

doc"""
  `Unums.resolve_lower(::Unum)`
  `Unums.resolve_lower(::Ubound)`
  Returns a Unum that represents the lower end of a Ubound, or just the Unum itself.
"""
@universal resolve_lower(value::Unum) = value
@universal resolve_lower(value::Ubound) = value.lower

doc"""
  `Unums.resolve_upper(::Unum)`
  `Unums.resolve_upper(::Ubound)`
  Returns a Unum that represents the upper end of a Ubound, or just the Unum itself.
"""
@universal resolve_upper(value::Unum) = value
@universal resolve_upper(value::Ubound) = value.upper
