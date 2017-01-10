#unum-multiplication.jl
#does multiplication for unums.

doc"""
  `Unums.frac_mul!(carry, ::Unum, fraction)`
  multiplies fraction into the the fraction value of unum.
"""
function frac_mul!{ESS,FSS}(a::UnumSmall{ESS,FSS}, multiplier::UInt64)
  (carry, a.fraction, ubit) = i64mul(a.fraction, multiplier, Val{FSS})
  a.flags |= ubit
  return carry + o64
end

frac_mul!{ESS,FSS}(a::UnumLarge{ESS,FSS}, multiplier::ArrayNum{FSS}) = frac_mul!(a, multiplier, Val{__cell_length(FSS)}, Val{true})
function frac_mul!{ESS,FSS, cells, addin}(a::UnumLarge{ESS,FSS}, multiplier::ArrayNum{FSS}, ::Type{Val{cells}}, ::Type{Val{addin}})
  (carry, ubit) = i64mul!(a.fraction, multiplier, Val{cells}, Val{addin})
  a.flags |= ubit
  return carry + o64
end

doc"""
  `Unums.mul(::Unum, ::Unum)` outputs a Unum OR Ubound corresponding to the product
  of two unums.  This is bound to the (\*) operation if options[:usegnum] is not
  set.  Note that in the case of degenerate unums, mul may change the bit values
  of the individual unums, but the values will not be altered.
"""
@universal function mul(a::Unum, b::Unum)
  #some basic checks out of the gate.

  (is_nan(a) || is_nan(b)) && return nan(U)
  is_zero(a) && return is_inf(b) ? nan(U) : zero(b)
  is_zero(b) && return is_inf(a) ? nan(U) : zero(a)

  result_sign = (a.flags $ b.flags) & UNUM_SIGN_MASK

  is_unit(a) && return coerce_sign!(copy(b), result_sign)
  is_unit(b) && return coerce_sign!(copy(a), result_sign)

  is_inf(a) && return inf(U, result_sign)
  is_inf(b) && return inf(U, result_sign)

  #resolve degenerate conditions in both A and B before calculating the exponents.
  resolve_degenerates!(a)
  resolve_degenerates!(b)

  if (is_exact(a) && is_exact(b))
    mul_exact(a, b, result_sign)
  else
    mul_inexact(a, b, result_sign)
  end
end

@universal function mul_exact(a::Unum, b::Unum, result_sign::UInt16)
  #first, calculate the exponents.
  _asubnormal = is_subnormal(a)
  _bsubnormal = is_subnormal(b)

  _aexp = decode_exp(a)
  _bexp = decode_exp(b)

  #solve the exponent.
  exponent = _aexp + _bexp

  (exponent > max_exponent(ESS)) && return mmr(U, result_sign)
  (exponent < min_exponent(ESS,FSS) && return sss(U, result_sign))

  exponent += _asubnormal * 1 + _bsubnormal * 1

  #TODO: convert this into "supranormal form"

  #solve the fractional product.
  if _asubnormal
    result = copy(a)
    multiplicand = b
    is_ulp(b) && make_ulp!(result)

    exponent -= normalize!(result)

    #this code is only necessary when ESS == 0, because you can have subnormal 1's
    #which don't exponent-degrade.
    if (ESS == 0)
      if _bsubnormal
        multiplicand = copy(b)
        exponent -= normalize!(multiplicand)
      end
    end
  else
    result = copy(b)
    multiplicand = a
    is_ulp(a) && make_ulp!(result)

    if _bsubnormal
      #normalize b (regardless of exponent)
      exponent -= normalize!(result)
    end
  end

  #check for a really small exponent (again!)
  (exponent < min_exponent(ESS,FSS) && return sss(U, result_sign))

  carry = frac_mul!(result, multiplicand.fraction)

  if (FSS < 6)
    result.fraction &= mask_top(FSS)
  end

  exponent = resolve_carry!(carry, result, exponent)

  if (exponent < min_exponent(ESS))
    #in the case that we need to make this subnormal.
    right_shift = to16(min_exponent(ESS) - exponent)
    frac_rsh_underflow_check!(result, right_shift)
    frac_set_bit!(result, right_shift)
    result.esize = max_esize(ESS)
    result.exponent = z64
  elseif (exponent > max_exponent(ESS))
    #possible to exceed max_exponent via the additive portios fo the multiplication.
    return mmr(U)
  end

  is_exact(result) && exact_trim!(result)
  trim_and_set_ubit!(result)

  return coerce_sign!(result, result_sign)
end

@universal function mul_inexact(a::Unum, b::Unum, result_sign::UInt16)

  is_inf_ulp(a) && (return inf_ulp_mult(a, b, result_sign))
  is_inf_ulp(b) && (return inf_ulp_mult(b, a, result_sign))

  is_zero_ulp(a) && return zero_ulp_mult(a, b, result_sign)
  is_zero_ulp(b) && return zero_ulp_mult(b, a, result_sign)

  inner_result = mul_exact(a, b, result_sign)

  is_exact(inner_result) && outer_ulp!(inner_result)
  result_exponent = decode_exp(inner_result) + is_subnormal(inner_result) * 1

  outer_a = is_ulp(a) ? outer_exact(a) : a
  outer_b = is_ulp(b) ? outer_exact(b) : b

  outer_result = mul_exact(outer_a, outer_b, result_sign)
  is_exact(outer_result) && inner_ulp!(outer_result)

  #=
  if is_exact(a)
    outer_result = sum_exact(inner_result, a, result_exponent, result_exponent - b.fsize - 2)
  elseif is_exact(b)
    outer_result = sum_exact(inner_result, b, result_exponent, result_exponent - a.fsize - 2)
  else
    ############################################################################
    # consider the representation of an ulp:
    # (2^p) * F (+) 2^(p - fs)
    # where p is the power, F is the fraction, and fs is fsize + 1, and (+) is
    # the ulp-range generating operator.
    #
    # 2^(p1)(F1)(+)2^(p1 - fs1) * 2^(p2)(F2)(+)2^(p2 - fs2)
    # gives 2^(p1p2)(F1F2)(+)2^(p1p2)(2^(-fs1)(F2) + 2^(-fs2)(F1) + 2^(-fs1-fs2))
    #
    # note that 2^(p1p2)(F1F2) is the exact product.

    # look at the two numbers, a and b, and decide which one is more precise and
    # which one is fuzzy.  Assign these respectively to the _precise and _fuzzy
    # temporary variables.

    (_precise, _fuzzy) = (a.fsize < b.fsize) ? (b , a) : (a, b)

    #copy the precise one and make it the "outer_result, temporarily"
    outer_result = zero(U)
    coerce_sign!(outer_result, inner_result)
    #first set the bit corresponding to the double product.
    frac_set_bit!(outer_result, _fuzzy.fsize + o16)

    #next, add in the precise fraction.
    carry = frac_add!(o64, outer_result, _fuzzy.fraction)

    if (_precise.fsize == _fuzzy.fsize)
      carry = frac_add!(carry, outer_result, _precise.fraction)
    else #move over by the size
      shift = _precise.fsize - _fuzzy.fsize
      frac_rsh!(shift, outer_result)
      #do carry things.
      carry = frac_shift_with_carry!(carry, outer_result, shift) + o64
      carry = frac_add!(carry, outer_result, _precise.fraction)
    end
    #next calculate the exponent deviation.
    expected_exponent = decode_exp(a) + decode_exp(b)
    result_exponent = decode_exp(inner_result)
    dev = to16(result_exponent - expected_exponent)

    #shift the remainders to match
    carry = frac_shift_with_carry!(carry, outer_result, _fuzzy.fsize + o16 + dev)

    carry = frac_add!(carry + o16, outer_result, inner_result.fraction)

    resolve_carry!(carry, outer_result, result_exponent)

    trim_and_set_ubit!(outer_result)
    make_ulp!(outer_result)
  end
  =#

  #check to make sure we haven't done the inf hack, where the result exactly
  #equals inf.
  __is_nan_or_inf(outer_result) && mmr!(outer_result, result_sign)

  #println("inner_result:", inner_result)
  #println("outer_result:", outer_result)

  if is_ulp(inner_result) && is_ulp(outer_result)
    return (result_sign == z16) ? resolve_as_utype!(inner_result, outer_result) : resolve_as_utype!(outer_result, inner_result)
  else
    return (result_sign == z16) ? B(inner_result, outer_result) : B(outer_result, inner_result)
  end
end

@universal function allsignedreals(result_sign::UInt16, T::Type{Unum})
  (result_sign == 0) ? B(cheapest_zero_ulp(U, z16), cheapest_inf_ulp(U, z16)) : B(cheapest_inf_ulp(U, UNUM_SIGN_MASK), cheapest_zero_ulp(U, UNUM_SIGN_MASK))
end

@universal function inf_ulp_mult(inf_ulp::Unum, b::Unum, result_sign::UInt16)
  #it is possible to multiply by a number bigger than but very close to one.
  (decode_exp(b) > 0) && return mmr(U, result_sign) #mmr is lucky enough to have this cheat.

  is_zero_ulp(b) && return allsignedreals(result_sign, U)

  inner_result = mul_exact(inner_exact(inf_ulp), b, result_sign)
  is_exact(inner_result) && outward_ulp!(inner_result)
  is_inf_ulp(inner_result) && return inner_result

  return (result_sign == 0) ? resolve_as_utype!(inner_result, mmr(U, result_sign)) :
                              resolve_as_utype!(mmr(U, result_sign), inner_result)
end

@universal function zero_ulp_mult(zero_ulp::Unum, b::Unum, result_sign::UInt16)
  _ulp_exact = outer_exact(zero_ulp)
  _val_exact = is_exact(b) ? b : outer_exact(b)

  res_exp = decode_exp(_ulp_exact) + 1 * is_subnormal(_ulp_exact) + decode_exp(_val_exact) + 1 * is_subnormal(_val_exact)

  (res_exp < min_exponent(ESS, FSS)) && return sss(U, result_sign)
  #cannot be inf_ulp because that case is handled above.

  outer_value = mul_exact(_ulp_exact, _val_exact, result_sign)

  is_exact(outer_value) && inner_ulp!(outer_value)
  is_sss(outer_value) && return outer_value

  (result_sign == z16) ? resolve_as_utype!(sss(U, result_sign), outer_value) : resolve_as_utype!(outer_value, sss(U, result_sign))
end

#import the Base add operation and bind it to the add and add! functions
import Base.*
@bind_operation(*, mul)
