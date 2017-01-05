slice(x::Utype) = slice(x.val)

function slice{ESS,FSS}(x::Unum{ESS,FSS})
  #first, slice must operate strictly on ulps
  is_ulp(x) || throw(ArgumentError("slice doesn't operate on exact values!"))
  x.fsize = max_fsize(FSS) && throw(ArgumentError("slice doesn't operate on terminal ulps"))

  inner_slice = copy(x)
  inner_slice.fsize += 1
  if is_positive(inner_slice)
    upper_slice = upper_ulp(lub(inner_slice))
    Utype[inner_slice, upper_slice]
  else
    lower_slice = lower_ulp(glb(inner_slice))
    Utype[lower_slice, inner_slice]
  end
end

function outer_exp_ulp{ESS,FSS}(::Type{UnumSmall{ESS,FSS}}, exponent_value::Int64, sign::UInt16)
  unum(UnumSmall{ESS,FSS}, exponent_value, t64, sign | UNUM_UBIT_MASK)
end
function outer_exp_ulp{ESS,FSS}(::Type{UnumLarge{ESS,FSS}}, exponent_value::Int64, sign::UInt16)
  unum(UnumLarge{ESS,FSS}, exponent_value, top(ArrayNum{FSS}), sign | UNUM_UBIT_MASK)
end
function inner_exp_ulp{ESS,FSS}(::Type{UnumSmall{ESS,FSS}}, exponent_value::Int64, sign::UInt16)
  unum(UnumSmall{ESS,FSS}, exponent_value, z64, sign | UNUM_UBIT_MASK)
end
function inner_exp_ulp{ESS,FSS}(::Type{UnumLarge{ESS,FSS}}, exponent_value::Int64, sign::UInt16)
  unum(UnumLarge{ESS,FSS}, exponent_value, zero(ArrayNum{FSS}), sign | UNUM_UBIT_MASK)
end

@universal function bounding_ulp(v1::Unum, v2::Unum)
  new_fsize = common_fsize(v1.fraction, v2.fraction)
  result = copy(v1)
  frac_trim!(result, new_fsize)
  result.flags |= UNUM_UBIT_MASK
  result
end

@universal function exp_bound(::Type{Ubound}, exponent_value::Int64, sign::UInt16)
  if sign == z16
    B(outer_exp_ulp(U),inner_exp_ulp(U))
  else
    B(inner_exp_ulp(U),outer_exp_ulp(U))
  end
end

is_top_half(x::Unum) = (x.fraction[1] & t64) != 0

function slice{ESS,FSS}(x::Ubound{ESS,FSS})
  #first strip exact values from the slice.
  #NB: consider changing this to encapsulation.
  lower_value = is_exact(x.lower) ? upper_ulp(x.lower) : x.lower
  upper_value = is_exact(x.upper) ? lower_ulp(x.upper) : x.upper

  lower_exp = decode_exp(lower_value)
  upper_exp = decode_exp(upper_value)

  #check to see if the two slices are on opposite sides of zero.
  if (is_positive(lower_value) != is_positive(upper_value))
    #figure out the exponents on both and expand to the bigger one.
    new_exponent = max(lower_exp, upper_exp)
    lower_slice = Ubound(outer_exp_ulp(U, new_exponent, UNUM_SIGN_MASK), neg_sss(U))
    upper_slice = Ubound(pos_sss(U), outer_exp_ulp(U, new_exponent, z16))
    return Utype[lower_slice, upper_slice]
  end

  #if they are not in the same exponent range.
  if (lower_exp != upper_exp)
    if (is_positive(lower_value))
      lower_slice = Ubound(pos_sss(U), outer_exp_ulp(U, upper_exp - 1, z16))
      upper_slice = exp_bound(B, upper_exp, z16)
    else
      lower_slice = exp_bound(B, lower_exp, UNUM_SIGN_MASK)
      upper_slice = Ubound(pos_sss(U), outer_exp_ulp(U, upper_exp - 1, UNUM_SIGN_MASK))
    end
    return Utype[lower_slice, upper_slice]
  end

  #if they are in the same exponent range but on different halves (not reducible to a ulp)
  if is_top_half(lower_value) != is_top_half(upper_value)
    if is_positive(lower_value)
      return Utype[inner_exp_ulp(U, lower_exp, z16), outer_exp_ulp(U, upper_exp, z16)]
    else
      return Utype[outer_exp_ulp(U, lower_exp, UNUM_SIGN_MASK), inner_exp_ulp(U, upper_exp, UNUM_SIGN_MASK)]
    end
  end

  #they are reducible to a ulp.
  slice(bounding_ulp(lower_value, upper_value))
end
