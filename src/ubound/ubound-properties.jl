#real number/dedekind cut formulas.
@universal function lub(x::Ubound)
  is_exact(x.upper) && return x.upper
  is_positive(x.upper) && return outer_exact(x.upper)
  return inner_exact(x.upper)
end

@universal function glb(x::Ubound)
  is_exact(x.lower) && return x.lower
  is_positive(x.lower) && return inner_exact(x.lower)
  return outer_exact(x.lower)
end
