#unum-bitwalk.jl

#implements a "bitwalking" functional.  Said functional takes a ulp that isn't
#at maximal fraction length and then breaks it into two ulps that has one extra
#bit of length.  Then it returns the function value for the middle exact values
#as well as each ulp.  Optionally, it returns the outside exact ulps as well.

function bitwalk{ESS,FSS}(f, u::Unum{ESS,FSS}, exacts = false, bound_exacts = false)
  is_exact(u) && throw(ArgumentError("argument must be an ulp."))
  u.fsize == max_fsize(FSS) && throw(ArgumentError("argument cannot be at max fsize"))
  u_neg = is_negative(u)
  #make sure outer_exact is overridden by the exact parameter.
  bound_exacts = exacts && bound_exacts
  #generate the result array.
  res = Utype[]
  #create a subsidiary function that pushes onto the results array based on the
  #sign of u.
  function directional_push(_u::Utype)
    res = u_neg ? vcat(_u, res) : vcat(res, _u)
  end

  exact_inner = Unum{ESS,FSS}(uint16(u.fsize + 1), u.esize, u.flags & UNUM_SIGN_MASK, u.fraction, u.exponent)
  bound_exacts && (res = vcat(res, f(exact_inner))) #don't need a directional push
  #generate the inner ulp:  This is just flipping the ubit mask on the inner value.
  ulp_inner = unum_unsafe(exact_inner, exact_inner.flags | UNUM_UBIT_MASK)
  directional_push(f(ulp_inner))
  #calculate the exact middle.
  new_fraction = u.fraction | __bit_from_top(u.fsize + 2, __frac_cells(FSS))
  exact_middle = Unum{ESS,FSS}(uint16(u.fsize + 1), u.esize, u.flags & UNUM_SIGN_MASK, new_fraction, u.exponent)
  exacts && directional_push(f(exact_middle))

  #generate the outer ulp:  This is just flipping the ubit mask on the middle value
  ulp_outer = unum_unsafe(exact_middle, exact_middle.flags | UNUM_UBIT_MASK)
  directional_push(f(ulp_outer))

  if bound_exacts
    exact_outer = __outward_exact(ulp_outer)
    directional_push(f(exact_outer))
  end

  res
end

export bitwalk
