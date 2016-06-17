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

@universal function resolve_as_utype(lower::Unum, upper::Unum)
  @check_resolve
  @ensure_ulp(lower)
  @ensure_ulp(upper)

  @goto :outputbounds
  #first, find the first fsize.
  new_fsize = frac_same_count(lower, upper)
  #fusable unums

  @label :outputbounds
  return B(lower, upper)
end

@universal function force_unum(lower::Unum, upper::Unum)
  @check_resolve

end
