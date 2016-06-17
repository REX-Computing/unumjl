#unum-subtraction.jl
#Performs subtraction with unums.  Requires two unums to have the same
#environment signature.

doc"""
  `Unums.frac_sub!(carry, subtrahend::Unum, minuend, guardbit::UInt64)`
  subtracts fraction from the fraction value of unum.
"""
function frac_sub!{ESS,FSS}(carry::UInt64, subtrahend::UnumSmall{ESS,FSS}, minuend::UInt64)
  (carry, subtrahend.fraction) = i64sub(carry, subtrahend.fraction, minuend)
  return carry
end
function frac_sub!{ESS,FSS}(carry::UInt64, subtrahend::UnumLarge{ESS,FSS}, minuend::ArrayNum{FSS})
  i64sub!(carry, subtrahend, minuend)
end


doc"""
  `Unums.sub(::Unum, ::Unum)` outputs a Unum OR Ubound corresponding to the difference
  of two unums.  This is bound to the (-) operation if options[:usegnum] is not
  set.  Note that in the case of degenerate unums, sub may change the bit values
  of the individual unums, but the values will not be altered.
"""
@universal function sub(a::Unum, b::Unum)
  #some basic checks out of the gate.
  (is_nan(a) || is_nan(b)) && return nan(T)
  is_zero(a) && return additiveinverse!(copy(b))
  is_zero(b) && return copy(a)

  #resolve degenerate conditions in both A and B before calculating the exponents.
  resolve_degenerates!(a)
  resolve_degenerates!(b)

  #go ahead and decode the a and b exponents, these will be used, a lot.
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)

  #check to see if the signs on a and b are mismatched.
  if ((a.flags $ b.flags) & UNUM_SIGN_MASK) != z16
    (_aexp >= _bexp) ? unum_sum(a, b, _aexp, _bexp) : unum_sum(b, a, _bexp, _aexp)
  else
    is_inward(b, a) ? unum_diff(a, b, _aexp, _bexp) : unum_diff(b, a, _bexp, _aexp)
  end
end

#import the Base add operation and bind it to the add and add! functions
import Base.-
@bind_operation(-, sub)

doc"""
  `Unums.unum_diff(::Unum, ::Unum, _aexp, _bexp)` outputs a Unum OR Ubound
  corresponding to the difference of two unums.  This function as a prerequisite
  must have the exponent on a exceed the exponent on b.
"""
@universal function unum_diff(a::Unum, b::Unum, _aexp::Int64, _bexp::Int64)
  #basic secondary checks which eject early results.
  is_inf(a) && return is_inf(b) ? nan(U) : inf(U, @signof a)
  is_mmr(a) && return mmr_sub(a, b)
  #there is a corner case that b winds up being infinity (and a does not; same
  #with mmr.)

  if (is_exact(a) && is_exact(b))
    diff_exact(a, b, _aexp, _bexp)
  else
    diff_inexact(a, b, _aexp, _bexp)
  end
end

@universal function diff_exact(a::Unum, b::Unum, _aexp::Int64, _bexp::Int64)
  #track once whether or not a and b are subnormal
  _a_subnormal = is_exp_zero(a)
  _b_subnormal = is_exp_zero(b)

  #modify the exponent such that they are.
  _aexp += _a_subnormal * 1
  _bexp += _b_subnormal * 1

  #calculate the shift between _aexp and _bexp.
  _shift = to16(_aexp -_bexp)

  if _shift > max_fsize(FSS)
    #then go down one previous exact unum and decrement.
    return inward_ulp!(copy(a))
  end

  #copy the b unum as the temporary result, nuke its ubit just to be sure
  #(we might be calling this function from diff_inexact)
  result = make_exact!(copy(b))
  #set the sign to the sign of the dominant figure.
  coerce_sign!(result, a)

  if _shift == z16
    carry::UInt64 = ((!_a_subnormal) & _b_subnormal) * o64
    guardbit::Bool = false
  else
    carry = (!_a_subnormal) * o64
    guardbit = get_bit(result.fraction, (max_fsize(FSS) + o16) - _shift)
    rsh_and_set_ubit!(result, _shift, true)
    (_b_subnormal) || frac_set_bit!(result, _shift)
  end

  #subtract fractionals parts together, and reset the carry.
  carry = frac_sub!(carry, result, a.fraction)

  if (carry == z64)
    #nb we only need to check the top bit.
    is_frac_zero(result) && return zero!(result, (guardbit != z64) * UNUM_UBIT_MASK)

    if (_aexp != min_exponent(ESS))
      frac_lsh!(result, o16)
      (result.esize, result.exponent) = encode_exp(_aexp - 1)
    end
  else
    #check to see if we need to the guard bit to set ubit.
    (guardbit != z64) && make_ulp!(result)
    #set the exponent
    (result.esize, result.exponent) = encode_exp(_aexp)
  end

  return result
end

@universal function diff_inexact(a::Unum, b::Unum, _aexp::Int64, _bexp::Int64)
  #do a second is_inward check.  If this is_inward check fails, then the result
  #can have an opposite sign, because it's an ulp that goes wierdly.
  is_inward(b, a) || throw(ArgumentError("currently unsupported"))
  base_value = diff_exact(a, b, _aexp, _bexp)
  if is_exact(b)
    #then we do the simplest subtraction.
    return base_value
  elseif is_exact(a)
    #check to see if the subtraction will cross the exponential barrier
    if is_not_zero(base_value.fraction) && inward_ubit_crosses_zero(base_value.fraction, b.fsize)
      inner_value = subtract_ubit!(copy(base_value), b.fsize)
      outer_value = inward_ulp!(base_value)

      #use b instead of "resolve_as_utype" because they can't be contiguous unums.
      return is_positive(a) ? B(inner_value, outer_value) : B(outer_value, inner_value)
    end
    return subtract_ubit!(base_value, b.fsize)
  else
    #just do the subtraction, then output the expected result.
    inner_value = subtract_ubit!(copy(base_value), b.fsize)         #set me here.
    is_positive(a) ? resolve_as_utype!(inner_value, base_value) : resolve_as_utype!(base_value, inner_value)
  end
end

@universal function mmr_sub(a::Unum, b::Unum)
  is_mmr(b) && return B(neg_mmr(U), pos_mmr(U)) #all real numbers
  #calculate inner_value by doing an exact subtraction of b from big_exact.
  #ensure that it's an ulp.
  diff_bound = is_ulp(b) ? outward_exact(b) : b
  inner_value = diff_exact(a, diff_bound, max_exponent(ESS), decode_exp(diff_bound))

  #check for the dominant sign.  If a was positive make it (inner_value -> mmr)
  #if a was negative, make it (-mmr -> inner_value )
  if ((@signof a) == z16)
    B(inner_value, pos_mmr(U))
  else
    B(neg_mmr(U), inner_value)
  end
end

@universal function subtract_ubit!(x::Unum, s::UInt16)
  borrowed = frac_sub_ubit!(x, s)
  if borrowed
    exponent = decode_exp(x)
    if exponent <= min_exponent(ESS)
      x.exponent = z64
    else
      (x.esize, x.exponent) = encode_exp(exponent - 1)
      frac_rsh!(x, 1)
    end
  end
  return x
end

import Base.-
#binary subtraction creates a temoporary g-layer number to be destroyed immediately.
function -{ESS,FSS}(x::Unum{ESS,FSS}, y::Unum{ESS,FSS})
  temp = zero(Gnum{ESS,FSS})
  sub!(x, y, temp)
  #return the result as the appropriate data type.
  emit_data(temp)
end
#unary subtraction creates a new unum and flips it.
function -{ESS,FSS}(x::Unum{ESS,FSS})
  additiveinverse!(copy(x))
end
function -{ESS,FSS}(x::Gnum{ESS,FSS})
  additiveinverse!(copy(x))
end
