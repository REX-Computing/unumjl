
################################################################################
## addition

@universal function add(a::Ubound, b::Unum)
  lb = a.lower + b
  hb = a.upper + b

  (typeof(lb) == B) && (lb = lb.lower)
  (typeof(hb) == B) && (hb = hb.upper)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end

@universal add(a::Unum, b::Ubound) = add(b, a)

@universal function add(a::Ubound, b::Ubound)
  lb = a.lower + b.lower
  hb = a.upper + b.upper

  (typeof(lb) == B) && (lb = lb.lower)
  (typeof(hb) == B) && (hb = hb.upper)

  (is_ulp(lb) && is_ulp(hb)) ? resolve_as_utype!(lb, hb) : B(lb, hb)
end
