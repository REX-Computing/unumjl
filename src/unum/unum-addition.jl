#unum-addition.jl
#Performs addition with unums.  Requires two unums to have the same
#environment signature.

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

import Base.+
function +{ESS,FSS}(x::Unum{ESS,FSS}, y::Unum{ESS,FSS})
  temp = zero(Gnum{ESS,FSS})
  add!(x, y, temp)
  #return the result as the appropriate data type.
  emit_data(temp)
end
function +{ESS,FSS}(x::Unum{ESS,FSS})
  Unum{ESS,FSS}(x)
end
