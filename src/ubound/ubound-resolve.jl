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

  #check to make sure the signs are the same.
  (@signof(lower) == @signof(upper)) || return B(lower, upper)

  #check to make sure the exponents are the same.
  (decode_exp(lower) == decode_exp(upper)) || return B(lower, upper)

  is_sss(lower) && is_sss(upper) && return sss(U, @signof(lower))
  is_mmr(lower) && is_mmr(upper) && return mmr(U, @signof(lower))

  (lower.fraction == upper.fraction) && return lower

  #discriminate between negative and positive numbers, which have their bounds
  #differently.
  if is_positive(lower)
    #firstly, the inner ubound is privileged and must be longer than the upper.
    fsize = contract_outer_fsize(upper.fraction, upper.fsize)
    (fsize == contract_inner_fsize(lower.fraction, lower.fsize)) || return B(lower, upper)
  else
    fsize = contract_outer_fsize(upper.fraction, upper.fsize)
    (fsize == contract_inner_fsize(lower.fraction, lower.fsize)) || return B(lower, upper)
  end

  same_till_fsize(upper.fraction, lower.fraction, fsize) || return B(lower, upper)
  lower.fsize = fsize
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
