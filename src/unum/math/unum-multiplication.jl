#unum-multiplication.jl
#does multiplication for unums.

doc"""
  `Unums.frac_mul!(carry, ::Unum, fraction)`
  multiplies fraction into the the fraction value of unum.
"""
function frac_mul!{ESS,FSS}(a::UnumSmall{ESS,FSS}, multiplier::UInt64)
  a.fraction = i64mul(a.fraction, multiplier)
end
function frac_mul!{ESS,FSS}(a::UnumLarge{ESS,FSS}, multiplier::ArrayNum{FSS})
  i64mul!(a.fraction, multiplier)
end

doc"""
  `Unums.mul(::Unum, ::Unum)` outputs a Unum OR Ubound corresponding to the product
  of two unums.  This is bound to the (\*) operation if options[:usegnum] is not
  set.  Note that in the case of degenerate unums, add may change the bit values
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

  #solve the fractional product.
  if _asubnormal
    result = copy(a)
    multiplicand = b

    #normalize a (regardless of exponent)
    leftshift = clz(result.fraction) + o16
    #next, shift the shadow fraction to the left appropriately.
    frac_lsh!(result, leftshift)
    exponent -= leftshift
  else
    result = copy(b)
    multiplicand = a

    if _bsubnormal
      #normalize b (regardless of exponent)
      leftshift = clz(result.fraction) + o16
      #next, shift the shadow fraction to the left appropriately.
      frac_lsh!(result, leftshift)
      exponent -= leftshift
    end
  end

  #check for a really small exponent (again!)
  (exponent < min_exponent(ESS,FSS) && return sss(U, result_sign))

  carry = frac_mul!(result, multiplicand.fraction)

  resolve_carry!(carry, result, exponent)

  if (exponent < min_exponent(ESS))
    #in the case that we need to make this subnormal.
    right_shift = exponent - min_exponent(ESS)
    rightshift_with_underflow_check!(result, right_shift)
  end

  return result
end

@universal function mul_inexact(a::Unum, b::Unum, result_sign::UInt16)
  is_mmr(a) && (return mmr_mult(b, result_sign))
  is_mmr(b) && (return mmr_mult(a, result_sign))
  is_sss(a) && (return sss_mult(b, result_sign))
  is_sss(b) && (return sss_mult(a, result_sign))

  return nan(U)
end

@universal function mmr_mult(a::Unum, result_sign::UInt16)
  if decode_exp(a) >= 0
    return mmr(U, result_sign)
  else
    return nan(U)
  end
end

@universal function sss_mult(a::Unum, result_sign::UInt16)
  if decode_exp(a) < 0
    return sss(U, result_sign)
  else
    temp1 = small_exact(U, result_sign)
    temp2 = is_exact(a) ? a : outward_exact(a)

    outer_value = mul_exact(temp1, temp2, result_sign)

    is_exact(outer_value) && inward_ulp!(outer_value)

    (result_sign == z16) ? resolve_as_utype!(sss(U, result_sign), outer_value) : resolve_as_utype!(outer_value, sss(U, result_sign))
  end
end

#import the Base add operation and bind it to the add and add! functions
import Base.*
@bind_operation(*, mul)
