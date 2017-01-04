###############################################################################
#subtraction


@universal function sub(a::Ubound, b::Unum)
  lb = resolve_lower(a.lower - b)
  hb = resolve_upper(a.upper - b)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal function sub(a::Unum, b::Ubound)
  lb = resolve_lower(a - b.upper)
  hb = resolve_upper(a - b.lower)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal function sub(a::Ubound, b::Ubound)
  lb = resolve_lower(a.lower - b.upper)
  hb = resolve_upper(a.upper - b.lower)

  is_sss(lb) && is_sss(hb) && (@signof(lb) == @signof(hb)) && return sss(U, @signof(lb))
  is_mmr(lb) && is_mmr(hb) && (@signof(lb) == @signof(hb)) && return mmr(U, @signof(lb))

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal function additiveinverse!(a::Ubound)
  hb = additiveinverse!(a.lower)
  a.lower = additiveinverse!(a.upper)
  a.upper = hb
  return a
end

#unary subtraction creates a new unum and flips it.
@universal function -(x::Ubound)
  additiveinverse!(copy(x))
end
