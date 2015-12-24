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
  add!(a, c)
end

function add!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  #override
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

  clear_ignore_sides!(b)
  b
end


#a function which checks for special values that will override actually performing
#calculations.
function __addition_override_check!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  ############################################
  # deal with zeros.
  #if our addend is zero, then we just leave both sides alone.
  is_zero(a) && (ignore_both_sides!(b); return)
  #if either side is zero, then copy the addend in to the Gnum.
  is_zero(b, LOWER_UNUM) && should_calculate(b, LOWER_UNUM) && (put_unum!(a, b, LOWER_UNUM); set_ignore_side!(b, LOWER_UNUM))
  is_zero(b, UPPER_UNUM) && should_calculate(b, UPPER_UNUM) && (put_unum!(a, b, UPPER_UNUM); set_ignore_side!(b, UPPER_UNUM))
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
    should_calculate(b, LOWER_UNUM) && (inf!(b, a.flags & UNUM_SIGN_MASK, LOWER_UNUM); set_ignore_side!(b, LOWER_UNUM))
    should_calculate(b, UPPER_UNUM) && (inf!(b, a.flags & UNUM_SIGN_MASK, UPPER_UNUM); set_ignore_side!(b, UPPER_UNUM))
  end

  #since a is known to be finite real, we don't need a complicated check.
  is_inf(b, LOWER_UNUM) && should_calculate(b, LOWER_UNUM) && (set_ignore_side!(b, LOWER_UNUM))
  is_inf(b, UPPER_UNUM) && should_calculate(b, UPPER_UNUM) && (set_ignore_side!(b, UPPER_UNUM))

  ############################################
  #deal with mmr collapsing.
  if (is_mmr(a))
    if (should_calculate(b, LOWER_UNUM) && (a.flags & UNUM_SIGN_MASK == b.lower_flags & UNUM_SIGN_MASK))
      mmr!(b, a.flags & UNUM_SIGN_MASK, LOWER_UNUM)
      set_ignore_side!(b, LOWER_UNUM)
    end
    if (should_calculate(b, UPPER_UNUM) && (a.flags & UNUM_SIGN_MASK == b.upper_flags & UNUM_SIGN_MASK))
      mmr!(b, a.flags & UNUM_SIGN_MASK, UPPER_UNUM)
      set_ignore_side!(b, UPPER_UNUM)
    end
  end
  if (should_calculate(b, LOWER_UNUM) && is_mmr(b, LOWER_UNUM) && (a.flags & UNUM_SIGN_MASK == b.lower_flags & UNUM_SIGN_MASK))
    set_ignore_side!(b, LOWER_UNUM)
  end
  if (should_calculate(b, UPPER_UNUM) && is_mmr(b, UPPER_UNUM) && (a.flags & UNUM_SIGN_MASK == b.upper_flags & UNUM_SIGN_MASK))
    set_ignore_side!(b, UPPER_UNUM)
  end
end

#trampoline for using the arithmetic addition algorithm on numbers which are
#guaranteed to have identical parity.  Otherwise subtraction is necessary.
@generated function __arithmetic_addition!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})

  mesize::UInt16 = max_esize(ESS)
  mfsize::UInt16 = max_fsize(FSS)
  (FSS < 7) && (mfrac::UInt64 = mask_top(FSS))
  mexp::UInt64 = max_exponent(ESS)

  quote
    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b.$side)

    a_dev::UInt64 = is_exp_zero(a) ? o64 : z64
    b_dev::UInt64 = is_exp_zero(b.$side) ? o64 : z64

    #derive the "contexts" for each, which is a combination of the exponent and
    #deviation.
    a_ctx::Int64 = a_exp + a_dev
    b_ctx::Int64 = b_exp + b_dev

    #set up a placeholder for the addend.
    addend::Unum{ESS,FSS}
    shift::Int64
    carry::UInt64
    scratchpad_exp::Int64
    #check to see which context is bigger.
    if (a_ctx > b_ctx)
      #set the placeholder to the value a.
      addend = a
      #then move b to the scratchpad.
      copy_unum!(b.$side, b.scratchpad)
      #calculate shift as the difference between a and b
      shift = a_ctx - b_ctx
      #set up the carry bit.
      carry = (o64 - a_dev) + ((shift == z64) ? (o64 - b_dev) : z64)
      scratchpad_exp = a_exp
    else
      #set the placeholder to the value b.
      addend = b.$side
      #move the unum value to the scratchpad.
      put_unum!(a, b, SCRATCHPAD)
      #calculate the shift as the difference between a and b.
      shift = b_ctx - a_ctx
      #set up the carry bit.
      carry = (o64 - b_dev) + ((shift == z64) ? (o64 - a_dev) : z64)
      scratchpad_exp = b_exp
    end

    #rightshift the scratchpad, then set the invisible bit that may have moved.
    __rightshift_frac_with_underflow_check!(b.scratchpad, shift)
    (shift != 0) && (b_dev == 0) && (set_frac_bit!(b.scratchpad, shift))

    #perform the carried add.
    carry = __carried_add_frac!(carry, addend, b.scratchpad)

    if (carry > 1)
      scratchpad_exp += 1
      __rightshift_frac_with_underflow_check!(b.scratchpad, 1)
      (carry == 3) && set_frac_top!(b.scratchpad)
    end

    #set the fsize.
    b.scratchpad.fsize = $mfsize - min(((b.scratchpad.fsize & UNUM_UBIT_MASK != 0) ? 0 : ctz(b.scratchpad.fraction)), $mfsize)

    #set exponent stuff.
    #handle the carry bit (which may be up to three? or more). If carry is zero,
    #no need to touch the exponent already loaded into the scratchpad.
    if (carry != 0)
      #check for overflow, and return mmr if that happens.
      if (scratchpad_exp > max_exponent(ESS))
        mmr!(b, SCRATCHPAD)
      else
        #we know it can't be subnormal, because we've added one to the exponent.
        (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
      end
    end

    #another way to get overflow is: by adding just enough bits to exactly
    #make the binary value for infinity.  This should, instead, yield mmr.
    #nb:  the is_inf call is the UNUM is_inf, which checks bitwise, not the
    #gnum is_inf, which only looks at the flag in the flags holder.
    is_inf(b.scratchpad) && mmr!(b, SCRATCHPAD)

    copy_unum!(b.scratchpad, b.$side)
  end
end

import Base.+
function +{ESS,FSS}(x::Unum{ESS,FSS}, y::Unum{ESS,FSS})
  temp = zero(Gnum{ESS,FSS})
  add!(x, y, temp)
  #return the result as the appropriate data type.
  emit_data(temp)
end
