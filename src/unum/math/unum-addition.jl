#unum-addition.jl
#Performs addition with unums.  Requires two unums to have the same
#environment signature.

doc"""
  `Unums.frac_add!(carry, ::Unum, fraction)`
  adds fraction into the the fraction value of unum.
"""
function frac_add!{ESS,FSS}(carry::UInt64, a::UnumSmall{ESS,FSS}, addin::UInt64)
  (carry, a.fraction) = i64add(carry, a.fraction, addin)
  return carry
end
function frac_add!{ESS,FSS}(carry::UInt64, a::UnumLarge{ESS,FSS}, addin::ArrayNum{FSS})
  i64add!(carry, a.fraction, addin)
end

doc"""
  `Unums.add(::Unum, ::Unum)` outputs a Unum OR Ubound corresponding to the sum
  of two unums.  This is bound to the (+) operation if options[:usegnum] is not
  set.  Note that in the case of degenerate unums, add may change the bit values
  of the individual unums, but the values will not be altered.
"""
@universal function add(a::Unum, b::Unum)
  #some basic checks out of the gate.
  (is_nan(a) || is_nan(b)) && return nan(U)
  is_zero(a) && return copy(b)
  is_zero(b) && return copy(a)

  #resolve degenerate conditions in both A and B before calculating the exponents.
  resolve_degenerates!(a)
  resolve_degenerates!(b)

  #go ahead and decode the a and b exponents, these will be used, a lot.
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)

  #check to see if the signs on a and b are mismatched.
  if ((a.flags $ b.flags) & UNUM_SIGN_MASK) != z16
    #kick it to the unum_difference function which calculates numeric difference
    is_inward(b, a) ? unum_diff(a, b, _aexp, _bexp) : unum_diff(b, a, _bexp, _aexp)
  else
    #kick it to the unum_sum function which calculates numeric sum.
    (_aexp > _bexp) ? unum_sum(a, b, _aexp, _bexp) : unum_sum(b, a, _bexp, _aexp)
  end
end

#import the Base add operation and bind it to the add and add! functions
import Base.+
@bind_operation(+, add)

doc"""
  `Unums.unum_sum(::Unum, ::Unum, _aexp, _bexp)` outputs a Unum OR Ubound
  corresponding to the sum of two unums.  This function as prerequisites
  must have the exponent on a exceed the exponent on b.
"""
@universal function unum_sum(a::Unum, b::Unum, _aexp::Int64, _bexp::Int64)
  #basic secondary checks which eject early results.
  is_inf(a) && return inf(U, @signof a)
  is_inf(b) && return inf(U, @signof a)

  (_aexp + _bexp > max_exponent(ESS)) && return mmr(U, @signof a)

  if (is_exact(a) && is_exact(b))
    sum_exact(a, b, _aexp, _bexp)
  else
    sum_inexact(a, b, _aexp, _bexp)
  end
end

@universal function sum_exact(a::Unum, b::Unum, _aexp::Int64, _bexp::Int64)
  #first, decide if we need to deviate either a or b on account of their being
  #subnormal numbers.
  _a_subnormal = is_exp_zero(a)
  _b_subnormal = is_exp_zero(b)

  #modify the exponent values on a and b to accomodate subnormality.
  _aexp += _a_subnormal * 1
  _bexp += _b_subnormal * 1

  shift = to16(_aexp - _bexp) #this is the a exponent minus the b exponent.
  #if the two numbers are very divergent in magnitude, only need to flip the ulp.
  if (shift > (max_fsize(FSS) + o16))
    res = make_ulp!(copy(a))
    res.fsize = max_fsize(FSS)
    return res
  end

  #copy the b unum as the temporary result.
  result = copy(b)
  coerce_sign!(result, a)

  #check to see if "shift" is zero.
  if (shift == 0x0000)
    #initialize carry to be one, if we're not subnormal
    carry = (!_a_subnormal) * o64
  else
    carry = z64
    rsh_and_set_ubit!(result, shift)
    (_b_subnormal) || frac_set_bit!(result, shift)
  end

  #increment the carry if the left unum is not subnormal.
  carry += (!_a_subnormal) * o64

  #add the two fractionals parts together, and set the carry.
  carry = frac_add!(carry, result, a.fraction)

  #resolve the possibility that the carry contains more than one bit.
  resolve_carry!(carry, result, _aexp)

  #if we wound up still subnormal, then re-subnormalize the exponent. (exp - 1)
  result.exponent &= f64 * (carry != 0)

  #check to see if we're getting too big.
  (result.exponent > max_biased_exponent(ESS)) && return mmr(U, @signof a)
  #check to make sure we haven't done the inf hack, where the result exactly
  #equals inf.
  is_inf(result) && return mmr(U, @signof a)

  is_exact(result) && exact_trim!(result)
  trim_and_set_ubit!(result)

  return result
end


@universal function sum_inexact(a::Unum, b::Unum, _aexp::Int64, _bexp::Int64)
  #first, do the exact sum, to calculate the "base value" of the resulting sum.

  b = copy(b)
  coerce_sign!(b, a)

  if is_inf_ulp(a)
    base_value = sum_exact(a, b, _aexp, _bexp)

    make_ulp!(base_value)
    is_inf_ulp(base_value) && return base_value
    return is_positive(a) ? resolve_as_utype!(base_value, mmr(U, @signof(a))) : resolve_as_utype!(mmr(U, @signof(a)), base_value)
  end

  glba = glb(a)
  glbb = glb(b)
  luba = lub(a)
  lubb = lub(b)

  if is_zero(glbb)
    glbs = glba
  elseif is_zero(glba)
    glbs = glbb
  elseif is_inf(glba)
    glbs = glba
  elseif is_inf(glbb)
    glbs = glbb
  else
    glbs = is_inward(glbb, glba) ?
      sum_exact(glba, glbb, decode_exp(glba), decode_exp(glbb)) :
      sum_exact(glbb, glba, decode_exp(glbb), decode_exp(glba))
  end

  if is_zero(lubb)
    lubs = luba
  elseif is_zero(luba)
    lubs = lubb
  elseif is_inf(luba)
    lubs = luba
  elseif is_inf(lubb)
    lubs = lubb
  else
    lubs = is_inward(lubb, luba) ?
      sum_exact(luba, lubb, decode_exp(luba), decode_exp(lubb)) :
      sum_exact(lubb, luba, decode_exp(lubb), decode_exp(luba))
  end

  lower_sum = is_exact(glbs) ? (is_zero(glbs) ? pos_sss(U) : upper_ulp(glbs)) : glbs
  upper_sum = is_exact(lubs) ? (is_zero(lubs) ? neg_sss(U) : lower_ulp(lubs)) : lubs

  #describe(lower_sum)
  #describe(upper_sum)

  return resolve_as_utype!(lower_sum, upper_sum)
end
