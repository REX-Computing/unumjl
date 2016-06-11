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
  (is_nan(a) || is_nan(b)) && return nan(T)
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
  is_inf(a) && return inf(T, @signof a)
  is_mmr(a) && return mmr(T, @signof a)
  #there is a corner case that b winds up being infinity (and a does not; same
  #with mmr.)
  is_inf(b) && return inf(T, @signof a)
  is_mmr(b) && return mmr(T, @signof a)

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

  #check to make sure we haven't done the inf hack, where the result exactly
  #equals inf.
  is_inf(result) && return inf(T)

  return result
end

doc"""
  Unums.add_bit_and_set_ulp!(::Unum, ulpsize1, ulpsize2) takes two ulps values.
  The first ulp value will be added into the unum.  The second ulp value will
  be converted into an fsize.
"""
@universal function add_bit_and_set_ulp!(a::Unum, big_ulp::UInt16, little_ulp::UInt16)
  carried = frac_add_bit!(a, big_ulp)
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
  base_value = sum_exact(a, b)

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
    return B(base_value, augmented_value)
  else
    ulp_shift = is_ulp(a) * _shift_a + is_ulp(b) * _shift_b
    base_value.fsize = min(ulp_shift, max_fsize(FSS))
    make_ulp!(base_value)
    #just in case this "hacks" to mmr.
    is_nan(base_value) && return mmr(U)
    return base_value
  end
end












################################################################################
## THERE IS SOME REDICULOUS LOGIC BEYOND THIS POINT WHICH MAY BE USED LATER.


#=
doc"""
  `add!(::Unum{ESS,FSS}, ::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes two unums and
  adds them, storing the result in the third, g-layer

  `add!(::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes two unums and adds them, storing
  the result and overwriting the second, g-layer

  In both cases, a reference to the result gnum is returned.
"""
function add!{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  put_unum!(b, c)
  set_g_flags!(a)
  add!(a, c)
end

function add!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  #override
  clear_ignore_sides!(b)
  __addition_override_check!(a, b)

  if should_calculate(b, LOWER_UNUM)
    if ((a.flags & UNUM_SIGN_MASK) == (b.lower.flags & UNUM_SIGN_MASK))
      __arithmetic_addition!(a, b, LOWER_UNUM)
    else
      __arithmetic_subtraction!(a, b, LOWER_UNUM)
    end
  end

  if should_calculate(b, UPPER_UNUM)
    if ((a.flags & UNUM_SIGN_MASK) == (b.upper.flags & UNUM_SIGN_MASK))
      __arithmetic_addition!(a, b, UPPER_UNUM)
    else
      __arithmetic_subtraction!(a, b, UPPER_UNUM)
    end
  end
  b
end

#a function which checks for special values that will override actually performing
#calculations.
function __addition_override_check!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  ############################################
  # deal with NaNs.
  #if our addend is nan, then set the addend to nan.
  is_nan(a) && (@scratch_this_operation!(b))
  is_nan(b) && (ignore_both_sides!(b); return)

  ############################################
  # deal with infinities.
  if (is_inf(a))
    #check to see if lower infinity is the opposite infinity.
    is_inf(b, LOWER_UNUM) && should_calculate(b, LOWER_UNUM) && ((a.flags & UNUM_SIGN_MASK) != (b.lower.flags & UNUM_SIGN_MASK)) && @scratch_this_operation!(b)
    is_inf(b, UPPER_UNUM) && should_calculate(b, UPPER_UNUM) && ((a.flags & UNUM_SIGN_MASK) != (b.upper.flags & UNUM_SIGN_MASK)) && @scratch_this_operation!(b)
    #since we know it's a finite, real value, we can set one or both sides of our gnum to infinity as needed.
    should_calculate(b, LOWER_UNUM) && (inf!(b, a.flags & UNUM_SIGN_MASK, LOWER_UNUM); ignore_side!(b, LOWER_UNUM))
    should_calculate(b, UPPER_UNUM) && (inf!(b, a.flags & UNUM_SIGN_MASK, UPPER_UNUM); ignore_side!(b, UPPER_UNUM))
  end

  #since a is known to be finite real, we don't need a complicated check.
  is_inf(b, LOWER_UNUM) && should_calculate(b, LOWER_UNUM) && (ignore_side!(b, LOWER_UNUM))
  is_inf(b, UPPER_UNUM) && should_calculate(b, UPPER_UNUM) && (ignore_side!(b, UPPER_UNUM))

  ############################################
  #deal with mmr collapsing.
  if (is_mmr(a))
    if should_calculate(b, LOWER_UNUM)
      #check to see if we're onesided.
      if is_onesided(b)
        if (a.flags & UNUM_SIGN_MASK == b.lower.flags & UNUM_SIGN_MASK)
          #just keep it as MMR because there is no change (a can't be infinite)
          mmr!(b, a.flags & UNUM_SIGN_MASK, LOWER_UNUM)
          ignore_side!(b, LOWER_UNUM)
        elseif (is_zero(b, LOWER_UNUM))
          mmr!(b, a.flags & UNUM_SIGN_MASK, LOWER_UNUM)
          ignore_side!(b, LOWER_UNUM)
        elseif (is_mmr(b, LOWER_UNUM))
          #mmr - mmr == (-mmr, mmr)
          mmr!(b, UNUM_SIGN_MASK, LOWER_UNUM)
          mmr!(b, z16, UPPER_UNUM)
          set_twosided!(b)
          ignore_both_sides!(b)
        elseif (is_negative(a))
          #take the negative mmr case.
          #set the buffer to be the big_exact value.
          big_exact!(b.buffer, UNUM_SIGN_MASK)
          #set the righthandside value of b to the lower value.
          #NB:  Consider allowing "cross calculations" where this copying step
          # doesn't have to happen
          copy_unum!(b.lower, b.upper)
          __exact_arithmetic_subtraction!(b.buffer, b, UPPER_UNUM)
          make_ulp!(b.upper)
          #reset the lower bound to be mmr.
          mmr!(b, UNUM_SIGN_MASK, LOWER_UNUM)
          set_twosided!(b)
          ignore_both_sides!(b)
        else
          #take the positive mmr case.
          #set the buffer to be positive big_exact
          big_exact!(b.buffer, z16)
          __exact_arithmetic_subtraction!(b.buffer, b, LOWER_UNUM)
          make_ulp!(b.lower)
          #reset the upper bound to be mmr.
          mmr!(b, z16, UPPER_UNUM)
          set_twosided!(b)
          ignore_both_sides!(b)
        end
      else
        #we have a two-sided unum and we're looking at the lower unum...
        #if a is neg_mmr, then this will be bashed and be turned into neg_mmr.
        if is_negative(a)
          mmr!(b, UNUM_SIGN_MASK, LOWER_UNUM)
          ignore_side!(b, LOWER_UNUM)
        elseif is_positive(b.lower) || is_zero(b, LOWER_UNUM)
          #sweep the entire thing as positive_mmr.
          mmr!(b, z16, LOWER_UNUM)
          set_onesided!(b)
          ignore_side!(b, LOWER_UNUM)
        else
          #set the buffer to be big_exact.
          big_exact!(b.buffer, z16)
          __exact_arithmetic_subtraction(b.buffer, b.lower)
          make_ulp!(b.lower)
          mmr!(b, z16, UPPER_UNUM)
          ignore_both_sides!(b, LOWER_UNUM)
        end
      end
    end
    if (should_calculate(b, UPPER_UNUM))
      if is_positive(a)
        #we're looking at a two-sided unum at the upper unum.
        mmr!(b, UNUM_SIGN_MASK, UPPER_UNUM)
        ignore_side!(b, UPPER_UNUM)
      elseif is_negative(b.upper) || is_zero(b, UPPER_UNUM)
        #sweep the whole thing as negative_mmr.
        mmr!(b, UNUM_SIGN_MASK, LOWER_UNUM)
        set_onesided!(b)
        ignore_side!(b, LOWER_UNUM)
      else
        #set the buffer to be big_exact.
        big_exact!(b.buffer, UNUM_SIGN_MASK)
        __exact_arithmetic_subtraction(b.buffer, b.upper)
        make_ulp!(b.upper)
        mmr!(b, UNUM_SIGN_MASK, LOWER_UNUM)
        ignore_both_sides!(b, LOWER_UNUM)
      end
    end
  end

  if (should_calculate(b, LOWER_UNUM) && is_mmr(b, LOWER_UNUM))
    if is_onesided(b)
      if (a.flags & UNUM_SIGN_MASK == b.lower.flags & UNUM_SIGN_MASK) || is_zero(a)
        nothing
      elseif (is_positive(a))  #a is positive and our mmr is negative.
        big_exact!(b.buffer, UNUM_SIGN_MASK)
        copy_unum!(a, b.upper)
        __exact_arithmetic_subtraction!(b.buffer, b, UPPER_UNUM)
        make_ulp!(b.upper)
        mmr!(b, UNUM_SIGN_MASK, LOWER_UNUM)
        set_twosided!(b)
        ignore_both_sides!(b)
      else
        big_exact!(b.buffer)
        copy_unum!(a, b.lower)
        __exact_arithmetic_subtraction!(b.buffer, b, LOWER_UNUM)
        make_ulp!(b.lower)
        mmr!(b, z16, UPPER_UNUM)
        set_twosided!(b)
        ignore_both_sides!(b)
      end
    elseif is_positive(b, LOWER_UNUM)
      #positive mmr on the lower side. (upper side must be inf.)
      big_exact!(b.buffer, z16)
      copy_unum!(a, b.lower)
      __exact_arithmetic_subtraction!(b.buffer, b, LOWER_UNUM)
      make_ulp!(b.lower)
      set_twosided!(b)
    end
      #negative mmr on the lower side...  Ignore it.
    ignore_side!(b, LOWER_UNUM)
  end

  if (should_calculate(b, UPPER_UNUM) && is_mmr(b, UPPER_UNUM))
    if (a.flags & UNUM_SIGN_MASK == b.upper.flags & UNUM_SIGN_MASK) || iszero(a)
      nothing
    elseif is_positive(a) #then negative_mmr on the upper side (lower side must be neg_inf.)
      big_exact!(b.buffer, UNUM_SIGN_MASK)
      copy_unum!(a, b.upper)
      __exact_arithmetic_subtraction!(b.buffer, b, UPPER_UNUM)
      make_ulp!(b.upper)
      set_twosided!(b)
    end
    #positive_mmr on the upper side... ignore it.
    ignore_side!(b, UPPER_UNUM)
  end

  ############################################
  # deal with zeros.
  #if our addend is zero, then we just leave both sides alone.
  is_zero(a) && (ignore_both_sides!(b); return)
  is_zero(b, LOWER_UNUM) && should_calculate(b, LOWER_UNUM) && (put_unum!(a, b, LOWER_UNUM); ignore_side!(b, LOWER_UNUM))
  is_zero(b, UPPER_UNUM) && should_calculate(b, UPPER_UNUM) && (put_unum!(a, b, UPPER_UNUM); ignore_side!(b, UPPER_UNUM))
end

#trampoline for using the arithmetic addition algorithm on numbers which are
#guaranteed to have identical parity.  Otherwise subtraction is necessary.
@generated function __arithmetic_addition!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  quote
    if is_ulp(a)
      if is_exact(b.$side)
        #we're going to swap operation order.  Is there maybe a better way to do this?
        copy_unum!(b.$side, b.buffer)
        copy_unum!(a, b.$side)
        __exact_arithmetic_addition!(b.buffer, b, Val{side})
      else
        __inexact_arithmetic_addition!(a, b, Val{side})
      end
    else
      __exact_arithmetic_addition!(a, b, Val{side})
    end
  end
end

@generated function __inexact_arithmetic_addition!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  if (side == :lower)
    quote
      promoted::Bool
      if is_positive(a)
        #the lower value is going to be
        make_exact!(b.lower)
        __exact_arithmetic_addition!(a, b, LOWER_UNUM)
        make_ulp!(b.lower)
        clear_gflags!(b.lower)
        is_mmr(b.lower) && mmr!(b, b.lower.flags, LOWER_UNUM)
        #a positive, b positive.
        if is_onesided(b) & !(is_mmr(b, LOWER_UNUM))
          copy_unum!(b.lower, b.upper)
          is_strange_subnormal(b.upper) && __resolve_subnormal!(b.upper)
          is_strange_subnormal(a) && __resolve_subnormal!(a)
          promoted = !is_mmr(b, LOWER_UNUM) && __add_ubit_frac!(b.upper)
          promoted && ((b.upper.esize, b.upper.exponent) = encode_exp(decode_exp(b.upper) + 1))
          match_fsize!(a, b.upper)

          clear_gflags!(b.upper)
          (__is_nan_or_inf(b.upper) || is_mmr(b.upper)) && mmr!(b, b.upper.flags, UPPER_UNUM)

          ignore_side!(b, UPPER_UNUM)
          set_twosided!(b)
        end
      else
        #the lower bound is created like the upper bound above.
        make_exact!(b.lower)
        __exact_arithmetic_addition!(a, b, LOWER_UNUM)
        make_ulp!(b.lower)
        clear_gflags!(b.lower)
        is_mmr(b.lower) && mmr!(b, b.lower.flags, LOWER_UNUM)

        #before we make any changes to lower, let's check to see if we also
        #need to create an upper variable.
        if (is_onesided(b) & !is_mmr(b, LOWER_UNUM))
          copy_unum!(b.lower, b.upper)
          ignore_side!(b, UPPER_UNUM)
          set_twosided!(b)
        end

        is_strange_subnormal(b.lower) && __resolve_subnormal!(b.lower)
        is_strange_subnormal(a) && __resolve_subnormal!(a)
        promoted = !is_mmr(b, LOWER_UNUM) && __add_ubit_frac!(b.lower)
        promoted && ((b.lower.esize, b.lower.exponent) = encode_exp(decode_exp(b.lower) + 1))
        match_fsize!(a, b.lower)
        (__is_nan_or_inf(b.lower) || is_mmr(b.lower)) && mmr!(b, b.lower.flags, LOWER_UNUM)
        ignore_side!(b, UPPER_UNUM)
      end
    end
  elseif (side == :upper)
    :(nan!(b))
  end
end
=#
