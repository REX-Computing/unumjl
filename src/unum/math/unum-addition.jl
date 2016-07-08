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

  is_mmr(a) && return mmr(U, @signof a)
  is_mmr(b) && return mmr(U, @signof a)

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
  if (shift > (max_fsize(FSS) + 1))
    res = make_ulp!(copy(a))
    res.fsize = max_fsize(FSS)
    return res
  end

  #copy the b unum as the temporary result.
  result = copy(b)

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

doc"""
  Unums.add_bit_and_set_ulp!(::Unum, ulpsize1, ulpsize2) takes two ulps values.
  The first ulp value will be added into the unum.  The second ulp value will
  be converted into an fsize.
"""
@universal function add_bit_and_set_ulp!(a::Unum, big_ulp::UInt16, little_ulp::UInt16)
  carried = frac_add_ubit!(a, big_ulp)
  if (carried)
    #rightshift by one.
    frac_rsh!(a, o16)
    #increment little_ulp
    little_ulp += 1
    #re-encode exponent
    exponent = decode_exp(a) + 1
    (exponent > max_exponent(ESS)) && return mmr!(a)
    (a.esize, a.exponent) = encode_exp(exponent)
  end
  a.fsize = min(little_ulp, max_fsize(FSS))
  is_nan(a) && return mmr!(a)
  return a
end

@universal function sum_inexact(a::Unum, b::Unum, _aexp::Int64, _bexp::Int64)
  #first, do the exact sum, to calculate the "base value" of the resulting sum.
  base_value = sum_exact(a, b, _aexp, _bexp)

  _rexp = decode_exp(base_value)
  _shift_a = to16(_rexp - _aexp) + a.fsize
  _shift_b = to16(_rexp - _bexp) + b.fsize

  if (is_ulp(a) && is_ulp(b))
    #figure out which one has a bigger ulp delta.
    #case one:  shift_a and shift_b are both greater than max_fsize (rare!)
    if (_shift_a > max_fsize(FSS)) && (_shift_b > max_fsize(FSS))
      base_value.fsize = max_fsize(FSS)
      return make_ulp!(base_value)
    end

    #the bigger ulp data gets added in
    augmented_value = add_bit_and_set_ulp!(copy(base_value), max(_shift_a, _shift_b), min(_shift_a, _shift_b))

    #create a ubound (of the correct type) with the base_value and augmented_value.
    return is_positive(a) ? B(base_value, augmented_value) : B(augmented_value, base_value)
  else
    ulp_shift = is_ulp(a) * _shift_a + is_ulp(b) * _shift_b
    base_value.fsize = min(ulp_shift, max_fsize(FSS))
    make_ulp!(base_value)
    #just in case this "hacks" to mmr.
    is_nan(base_value) && return mmr(U)
    return base_value
  end
end
