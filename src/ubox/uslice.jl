uslice(x::Utype) = uslice(x.val)

function uslice{ESS,FSS}(x::Unum{ESS,FSS})
  #first, slice must operate strictly on ulps
  is_ulp(x) || throw(ArgumentError("slice doesn't operate on exact values!"))
  (x.fsize == max_fsize(FSS)) && throw(ArgumentError("slice doesn't operate on terminal ulps"))

  inner_slice = copy(x)
  new_fsize = inner_slice.fsize + o16
  inner_slice.fsize = new_fsize
  if is_positive(inner_slice)
    upper_slice = upper_ulp(lub(inner_slice))
    frac_trim!(upper_slice, new_fsize)
    upper_slice.fsize = new_fsize
    Utype[inner_slice, upper_slice]
  else
    lower_slice = lower_ulp(glb(inner_slice))
    frac_trim!(lower_slice, new_fsize)
    lower_slice.fsize = new_fsize
    Utype[lower_slice, inner_slice]
  end
end

@generated function outer_exp_ulp{U <: Unum}(::Type{U}, exponent_value::Int64, sign::UInt16)
  FSS = U.parameters[2]
  toptype = FSS < 7 ? UInt64 : ArrayNum{FSS}
  :( unum(U, exponent_value, top($toptype), sign | UNUM_UBIT_MASK) )
end
@generated function inner_exp_ulp{U <: Unum}(::Type{U}, exponent_value::Int64, sign::UInt16)
  FSS = U.parameters[2]
  toptype = FSS < 7 ? UInt64 : ArrayNum{FSS}
  :( unum(U, exponent_value, zero($toptype), sign | UNUM_UBIT_MASK) )
end

@universal function bounding_ulp(v1::Unum, v2::Unum)
  new_fsize = common_fsize(v1.fraction, v2.fraction)
  result = copy(v1)
  frac_trim!(result, new_fsize)
  result.fsize = new_fsize
  result.flags |= UNUM_UBIT_MASK
  result
end

@generated function exp_bound{B <: Ubound}(::Type{B}, exponent_value::Int64, sign::UInt16)
  U = Unum{B.parameters[1], B.parameters[2]}
  quote
    if sign == z16
      B(inner_exp_ulp($U, exponent_value, sign), outer_exp_ulp($U, exponent_value, sign))
    else
      B(outer_exp_ulp($U, exponent_value, sign), inner_exp_ulp($U, exponent_value, sign))
    end
  end
end

is_top_half(x::Unum) = (x.fraction[1] & t64) != 0

function uslice{ESS,FSS}(x::Ubound{ESS,FSS})
  U = Unum{ESS,FSS}
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
      return Utype[inner_exp_ulp(U, lower_exp, z16), outer_exp_ulp(U, lower_exp, z16)]
    else
      return Utype[outer_exp_ulp(U, lower_exp, UNUM_SIGN_MASK), inner_exp_ulp(U, lower_exp, UNUM_SIGN_MASK)]
    end
  end

  #they are reducible to a ulp.
  uslice(bounding_ulp(lower_value, upper_value))
end

function uslice{ESS,FSS}(v::Vector{Utype{ESS,FSS}}, idx::Int)
  (lower_slice, upper_slice) = uslice(v[idx])
  v1 = deepcopy(v)
  v2 = deepcopy(v)
  v1[idx] = lower_slice
  v2[idx] = upper_slice
  hcat(v1, v2)
end

function uslice{ESS,FSS}(m::Matrix{Utype{ESS,FSS}}, idx::Int)
  slicematrix = Matrix{Utype{ESS,FSS}}(size(m, 1),2 * size(m, 2))
  for jdx = 1:size(m,2)
    slicematrix[:, jdx * 2 + (-1:0)] = uslice(m[:,jdx], idx)
  end
  slicematrix
end

export uslice
