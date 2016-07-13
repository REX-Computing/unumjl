
################################################################################
## addition

@universal function add(a::Ubound, b::Unum)
  lb = resolve_lower(a.lower + b)
  hb = resolve_upper(a.upper + b)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal add(a::Unum, b::Ubound) = add(b, a)

@universal function add(a::Ubound, b::Ubound)
  lb = resolve_lower(a.lower + b.lower)
  hb = resolve_upper(a.upper + b.upper)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end
