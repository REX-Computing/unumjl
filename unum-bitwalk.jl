#unum-bitwalk.jl

#implements a "bitwalking" functional.  Said functional takes a ulp that isn't
#at maximal fraction length and then breaks it into two ulps that has one extra
#bit of length.  Then it executes the binary function for the ulps and the exacts
#if desired.  Returns an array with the unums that evaluate to true.

function bitwalk{ESS,FSS}(bf, u::Unum{ESS,FSS}, exacts = false, bound_exacts = false)
  is_exact(u) && return [u]
  u.fsize == max_fsize(FSS) && throw(ArgumentError("argument cannot be at max fsize"))
  u_neg = is_negative(u)
  #make sure outer_exact is overridden by the exact parameter.
  bound_exacts = exacts && bound_exacts
  #generate the result array.
  res = Utype[]
  #create a subsidiary function that pushes onto the results array based on the
  #sign of u.

  exact_inner = Unum{ESS,FSS}(uint16(u.fsize + 1), u.esize, u.flags & UNUM_SIGN_MASK, u.fraction, u.exponent)
  bound_exacts && bf(exact_inner) && (res = vcat(res, exact_inner))

  #generate the inner ulp:  This is just flipping the ubit mask on the inner value.
  ulp_inner = unum_unsafe(exact_inner, exact_inner.flags | UNUM_UBIT_MASK)
  bf(ulp_inner) && (res = vcat(res, ulp_inner))

  #calculate the exact middle.
  new_fraction = u.fraction | __bit_from_top(u.fsize + 2, __frac_cells(FSS))
  exact_middle = Unum{ESS,FSS}(uint16(u.fsize + 1), u.esize, u.flags & UNUM_SIGN_MASK, new_fraction, u.exponent)
  exacts && bf(exact_middle) && (res = vcat(res, exact_middle))

  #generate the outer ulp:  This is just flipping the ubit mask on the middle value
  ulp_outer = unum_unsafe(exact_middle, exact_middle.flags | UNUM_UBIT_MASK)
  bf(ulp_outer) && (res = vcat(res, ulp_outer))

  if bound_exacts
    exact_outer = __outward_exact(ulp_outer)
    bf(exact_outer) && (res = vcat(res, exact_outer))
  end

  res
end

export bitwalk
