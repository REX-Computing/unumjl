#unum-oddsandends.jl
#mathematical odds and ends

################################################################################

doc"""
  `Unums.frac_val(::UInt64)`
  `Unums.frac_val(::ArrayNum)`
  returns the integral value for a number used as a fraction.
"""
frac_val(x::UInt64) = x
function frac_val{FSS}(v::ArrayNum{FSS})
  sum = big(0)
  for i = 1:length(v.a)
    sum <<= 64
    sum += v.a[i]
  end
  sum
end

doc"""`Unums.calculate(x::Unum)` returns a bigfloat equivalent of the unum.  NB:
currently doesn't work so well for FSS > 9"""
@universal function calculate(x::Unum)
  sign = (x.flags & UNUM_SIGN_MASK != 0) ? -1 : 1
  #the sub`normal case
  if (x.exponent == 0)
    big(2.0)^(decode_exp(x) + 1) * sign * (frac_val(x.fraction)) / big(2.0)^(64 * __ulength(x.fraction))
  else #the normalcase
    big(2.0)^(decode_exp(x)) * sign * (1 + frac_val(x.fraction) / big(2.0)^(64 * __ulength(x.fraction)))
  end
end
export calculate

__ulength(::UInt64) = 1
__ulength{FSS}(::ArrayNum{FSS}) = __cell_length(FSS)

################################################################################

doc"""
  `additiveinverse!` creates the additive inverse value of a unum, by flipping
  the sign.  This can be better than the `-` operator because it doesn't copy
  the unum.  A reference to the unum is returned.
"""
@universal additiveinverse!(x::Unum) = (x.flags $= UNUM_SIGN_MASK; return x)
export additiveinverse!

doc"""
  `coerce_sign!(a::Unum, b)` maps the sign bit from b onto a.  b can either be a
  UInt16 or a Unum.
"""
@universal coerce_sign!(a::Unum, b::Unum) = coerce_sign!(a, b.flags)
@universal coerce_sign!(a::Unum, sgn::UInt16) = (a.flags = (a.flags & ~UNUM_SIGN_MASK) | sgn; return a)

doc"""
  `abs!(::Unum)` forces the value of the unum to be positive.  Returns the
  unum for chaining purposes.
"""
@universal abs!(x::Unum) = ((x.flags &= ~UNUM_SIGN_MASK); return x)
export abs!

@universal function Base.copy!(dest::Unum, src::Unum)
  dest.fsize = src.fsize
  dest.esize = src.esize
  dest.flags = src.flags & UNUM_FLAG_MASK
  dest.exponent = src.exponent

  (FSS < 7) ? (dest.fraction = src.fraction) : (copy!(dest.fraction, src.fraction))

  return dest  #for chaining purposes
end

doc"""
  `Unums.normalize!(::Unum)` takes a unum that is purportedly subnormal form and
  normalizes it.  This entails shifting just past the top bit.  this function
  returns the number of places shifted.

  This function should not be run on a fraction that is all zero, nor on a
  function which is not subnormal.
"""
@universal function normalize!(x::Unum)
  leftshift = clz(x.fraction) + o16
  frac_lsh!(x, leftshift)
  x.fsize -= leftshift
  return leftshift
end

doc"""
  `Unums.resolve_degenerates!(::Unum)` checks for degeneracy in unum values,
  and resolves to "canonical" form - which means all nonzero subnormals are
  converted to normal form if possible, and exact zeros are the smallest zero.
  fsize is maximally trimmed for exact values.
"""
@universal function resolve_degenerates!(x::Unum)
  (x.exponent != 0) && return x   #kick out if our exponent is not zero.
  (x.esize == max_esize(ESS)) && return x #kick out if we're not a strange subnormal.
  if is_all_zero(x.fraction)
    is_exact(x) && return zero(typeof(x))
    return x #if we're actually zero or a zero+ulp subnormal we can't shift.
  end

  true_exponent = decode_exp(x)
  #now, count leading zeros, be prepared to shift left.
  leftshift = normalize!(x)
  true_exponent -= leftshift - o16
  (x.esize, x.exponent) = encode_exp(true_exponent)
  exact_trim!(x)

  return x
end

################################################################################
## variadic macros that trigger exactitude checking.

if options[:devmode]
  macro ensure_exact(x)
    esc(options[:devmode] ? :(is_exact($x) || throw(ArgumentError("passed parameter must be exact"))) : :())
  end
else
  macro ensure_exact(x); :(); end
end

if options[:devmode]
  macro ensure_ulp(x)
    esc(options[:devmode] ? :(is_ulp($x) || throw(ArgumentError("passed parameter must be an ulp"))) : :())
  end
else
  macro ensure_ulp(x); :(); end
end

################################################################################
## sophisticated exactitude functions.

doc"""
  `Unums.outer_ulp!(::Unum)` returns the smallest-width ulp immediately above the
  current (exact) unum.
"""
@universal function outer_ulp!(x::Unum)
  @ensure_exact(x)

  resolve_degenerates!(x)

  x.fsize = max_fsize(FSS)
  make_ulp!(x)
end
@universal outer_ulp(x::Unum) = outer_ulp!(copy(x))

doc"""
  `Unums.inner_ulp!(::Unum)` returns the smallest-width ulp immediately below the
  current unum.
"""
@universal function inner_ulp!(x::Unum)
  @ensure_exact(x)
  resolve_degenerates!(x)
  make_ulp!(x)

  borrowed = frac_sub_ubit!(x, max_fsize(FSS))

  #if we borrowed, then fraction must have been zero.
  if borrowed
    #there is no ulp inward of x.  Consider replacing this with "Throw an error"
    (x.exponent == 0) && return nan!(x)
    _xexp = decode_exp(x)
    (_xexp == min_exponent(ESS)) && (x.exponent = 0; return x)
    (x.esize, x.exponent) = encode_exp(_xexp - 1)
  end
  x.fsize = max_fsize(FSS)

  return x
end
@universal inner_ulp(x::Unum) = inner_ulp!(copy(x))

doc"""
"""
@universal function outer_exact!(x::Unum)
  @ensure_ulp(x)
  resolve_degenerates!(x)
  carry = frac_add_ubit!(x, x.fsize)
  if carry
    if (is_subnormal(x))
      (x.exponent = o64)
    else
      exp = decode_exp(x) + 1
      if exp > max_exponent(ESS)
        inf!(x, @signof(x))
      else
        (x.esize, x.exponent) = encode_exp(exp)
      end
    end
  end
  exact_trim!(make_exact!(x))
end
@universal outer_exact(x::Unum) = outer_exact!(copy(x))

@universal function inner_exact!(x::Unum)
  @ensure_ulp(x)
  make_exact!(x)
end
@universal inner_exact(x::Unum) = inner_exact!(copy(x))

#real number/dedekind cut formulas.
@universal function lub(x::Unum)
  is_exact(x) && return x
  is_positive(x) && return outer_exact(x)
  return inner_exact(x)
end
@universal function glb(x::Unum)
  is_exact(x) && return x
  is_positive(x) && return inner_exact(x)
  return outer_exact(x)
end

################################################################################
## recast as upper and lower versions.

@universal upper_exact!(x::Unum) = is_positive(x) ? outer_exact!(x) : inner_exact!(x)
@universal lower_exact!(x::Unum) = is_positive(x) ? inner_exact!(x) : outer_exact!(x)
@universal upper_ulp!(x::Unum) = is_positive(x) ? outer_ulp!(x) : inner_ulp!(x)
@universal lower_ulp!(x::Unum) = is_positive(x) ? inner_ulp!(x) : outer_ulp!(x)

@universal upper_exact(x::Unum) = upper_exact!(copy(x))
@universal lower_exact(x::Unum) = lower_exact!(copy(x))
@universal upper_ulp(x::Unum) = upper_ulp!(copy(x))
@universal lower_ulp(x::Unum) = lower_ulp!(copy(x))

################################################################################

@universal function next_unum!(x::Unum)
  @ensure_exact(x)
  resolve_degenerates!(x)
  carried = frac_add_ubit!(x, max_fsize(FSS))
  if carried
    exponent = decode_exp(x)
    (exponent > max_exponent(ESS)) && return inf(x)
    (x.esize, x.exponent) = encode_exp(exponent + 1)
  end
  exact_trim!(x)
  return x
end

frac_ctz{ESS,FSS}(x::UnumSmall{ESS,FSS}) = ctz(x.fraction >> (64 - 1 << FSS))
frac_ctz{ESS,FSS}(x::UnumLarge{ESS,FSS}) = ctz(x.fraction)

frac_cto{ESS,FSS}(x::UnumSmall{ESS,FSS}) = cto(x.fraction >> (64 - 1 << FSS))
frac_cto{ESS,FSS}(x::UnumLarge{ESS,FSS}) = cto(x.fraction)

@universal next_unum(x::Unum) = next_unum!(copy(x))
################################################################################
## dumb exactitude functions.

doc"""`Unums.make_exact(::Unum)` forces the ubit of a unum to be 0."""
@universal make_exact!(x::Unum) = (x.flags &= ~UNUM_UBIT_MASK; x)
@universal make_exact(x::Unum) = make_exact!(copy(x))

doc"""`Unums.make_ulp(::Unum)` forces the ubit of a unum to be 1."""
@universal make_ulp!(x::Unum) = (x.flags |= UNUM_UBIT_MASK; x)
@universal make_ulp(x::Unum) = make_exact!(copy(x))

################################################################################
## carry resolution

doc"""
  `Unums.resolve_carry!(carry::UInt64, ::Unum, exponent::Int64)` resolves a
  carry (invisible bit) value that may exceed one after calculation events.
  You should pass this function an exponent value that will be returned,
  appropriately modified.
"""
@universal function resolve_carry!(carry::UInt64, x::Unum, exponent::Int64)
  leftzeroes = clz(carry)
  if (leftzeroes < 0x003F) #less than 63 zeroes
    shift = 0x003F - leftzeroes
    rsh_and_set_ubit!(x, shift)
    #now copy the bits over from the carried segment.
    frac_copy_top!(x, (((o64 << shift) - o64) & carry) << (leftzeroes + o16))
    exponent += shift
  end
  (exponent > max_exponent(ESS)) && mmr!(x)  #set it to mmr, if the exponent is too large.
  (x.esize, x.exponent) = encode_exp(exponent)
end
