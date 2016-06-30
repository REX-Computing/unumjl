###############################################################################
#subtraction


@universal function sub(a::Ubound, b::Unum)
  lb = a.lower - b
  hb = a.upper - b

  (typeof(lb) == B) && (lb = lb.lower)
  (typeof(hb) == B) && (hb = hb.upper)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal function sub(a::Unum, b::Ubound)
  lb = a - b.upper
  hb = a - b.lower

  (typeof(lb) == B) && (lb = lb.lower)
  (typeof(hb) == B) && (hb = hb.upper)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal function sub(a::Ubound, b::Ubound)
  lb = a.lower - b.upper
  hb = a.upper - b.lower

  (typeof(lb) == B) && (lb = lb.lower)
  (typeof(hb) == B) && (hb = hb.upper)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal function additiveinverse!(a::Ubound)
  hb = -a.lower
  a.lower = -a.upper
  a.upper = hb
  return a
end

#unary subtraction creates a new unum and flips it.
@universal function -(x::Ubound)
  additiveinverse!(copy(x))
end
