#unit-subtraction.jl
#implements addition primitives where the vectors of the two values point in
#opposing directions.  This is organized into a separate file for convenience
#purposes (these primitives can be very large.)

doc"""
  `sub!(::Unum{ESS,FSS}, ::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes two unums and
  subtracts them, storing the result in the third, g-layer

  `sub!(::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes two unums and subtracts them, storing
  the result and overwriting the second, g-layer

  In both cases, a reference to the result gnum is returned.
"""
function sub!{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  put_unum!(b, c)
  sub!(a, c)
end

function sub!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  #override
  __subtraction_override_check!(a, b)

  if should_calculate(b, LOWER_UNUM)
    if ((a.flags & UNUM_SIGN_MASK) == (b.lower.flags & UNUM_SIGN_MASK))
      __arithmetic_subtraction!(a, b, LOWER_UNUM)
    else
      __arithmetic_addition!(a, b, LOWER_UNUM)
    end
  end

  if should_calculate(b, UPPER_UNUM)
    if ((a.flags & UNUM_SIGN_MASK) == (b.upper.flags & UNUM_SIGN_MASK))
      __arithmetic_subtraction!(a, b, UPPER_UNUM)
    else
      __arithmetic_addition!(a, b, UPPER_UNUM)
    end
  end

  clear_ignore_sides!(b)
  b
end

#a function which checks for special values that will override actually performing
#calculations.
function __subtraction_override_check!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  ############################################
  # deal with NaNs.
  #if our addend is nan, then set the addend to nan.
  is_nan(a) && (@scratch_this_operation!(b))
  is_nan(b) && (ignore_both_sides!(b); return)
  ############################################
  # deal with zeros.
  #if our addend is zero, then we just invert both sides alone.
  if is_zero(a)
    additive_inverse!(b.lower)
    additive_inverse!(b.upper)
    ignore_both_sides!(b)
  end
  #if either side is zero, then copy the addend in to the Gnum.
  is_zero(b, LOWER_UNUM) && should_calculate(b, LOWER_UNUM) && (put_unum!(a, b, LOWER_UNUM); set_ignore_side!(b, LOWER_UNUM))
  is_zero(b, UPPER_UNUM) && should_calculate(b, UPPER_UNUM) && (put_unum!(a, b, UPPER_UNUM); set_ignore_side!(b, UPPER_UNUM))
  ############################################
  # deal with infinities.
  if (is_inf(a))
    #check to see if lower infinity is the same infinity.
    is_inf(b, LOWER_UNUM) && should_calculate(b, LOWER_UNUM) && ((a.flags & UNUM_SIGN_MASK) == (b.lower.flags & UNUM_SIGN_MASK)) && @scratch_this_operation!(b)
    is_inf(b, UPPER_UNUM) && should_calculate(b, UPPER_UNUM) && ((a.flags & UNUM_SIGN_MASK) == (b.upper.flags & UNUM_SIGN_MASK)) && @scratch_this_operation!(b)
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
    if (should_calculate(b, LOWER_UNUM) && (a.flags & UNUM_SIGN_MASK != b.lower_flags & UNUM_SIGN_MASK))
      mmr!(b, a.flags & UNUM_SIGN_MASK, LOWER_UNUM)
      set_ignore_side!(b, LOWER_UNUM)
    end
    if (should_calculate(b, UPPER_UNUM) && (a.flags & UNUM_SIGN_MASK != b.upper_flags & UNUM_SIGN_MASK))
      mmr!(b, a.flags & UNUM_SIGN_MASK, UPPER_UNUM)
      set_ignore_side!(b, UPPER_UNUM)
    end
  end
  if (should_calculate(b, LOWER_UNUM) && is_mmr(b, LOWER_UNUM) && (a.flags & UNUM_SIGN_MASK != b.lower_flags & UNUM_SIGN_MASK))
    set_ignore_side!(b, LOWER_UNUM)
  end
  if (should_calculate(b, UPPER_UNUM) && is_mmr(b, UPPER_UNUM) && (a.flags & UNUM_SIGN_MASK != b.upper_flags & UNUM_SIGN_MASK))
    set_ignore_side!(b, UPPER_UNUM)
  end
end


@generated function __arithmetic_subtraction!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  quote
    if is_ulp(a)
      nan!(b)
    else
      __exact_arithmetic_subtraction!(a, b, Val{side})
    end
  end
end

@generated function __exact_arithmetic_subtraction!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  mesize::UInt16 = max_esize(ESS)
  mfsize::UInt16 = max_fsize(FSS)
  (FSS < 7) && (mfrac::UInt64 = mask_top(FSS))
  mexp::UInt64 = max_exponent(ESS)

  quote
    #for subtraction, resolving strange subnormal numbers as a first step is critical.
    is_strange_subnormal(a) && (resolve_subnormal!(a))
    is_strange_subnormal(b.$side) && (resolve_subnormal!(b.$side))

    #set the exp and dev values.
    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b.$side)
    #set the deviations due to subnormality.
    a_dev::UInt64 = is_exp_zero(a) ? z64 : o64
    b_dev::UInt64 = is_exp_zero(b.$side) ? z64 : o64
    #set the exponential contexts for both variables.
    a_ctx::Int64 = a_exp + a_dev
    b_ctx::Int64 = b_exp + b_dev

    #set up a placeholder for the minuend.
    shift::Int64
    vbit::UInt64
    minuend::Unum{ESS,FSS}
    scratchpad_exp::Int64
    scratchpad_dev::UInt64
    @init_sflags()

    #is a bigger?
    a_bigger = (a_exp > b_exp)
    if (a_exp == b_exp)
      a_bigger = a_bigger || ((a_dev == 0) && (b_dev != 0))
      a_bigger = a_bigger || (a_dev == b_dev) && (a.fraction > b.$side.fraction)
    end

    if a_bigger
      #set the placeholder to the value a.
      minuend = a
      @preserve_sflags b copy_unum!(b.$side, b.scratchpad)
      #calculate shift as the difference between a and b
      shift = a_ctx - b_ctx
      #set up the virtual bit.
      vbit = (o64 - a_dev) + ((shift == z64) ? (o64 - b_dev) : z64)
      scratchpad_exp = a_exp
      scratchpad_dev = a_dev
    else
      #set the placeholder to the value b.
      minuend = b.$side
      #move the unum value to the scratchpad.
      @preserve_sflags b put_unum!(a, b, SCRATCHPAD)
      #calculate the shift as the difference between a and b.
      shift = b_ctx - a_ctx
      #set up the carry bit.
      vbit = (o64 - b_dev) + ((shift == z64) ? (o64 - a_dev) : z64)
      scratchpad_exp = b_exp
      scratchpad_dev = b_dev
    end

    if (shift == 0)
      #b is greater than a.  So, if a is normal, bash the value of vbit.
      vbit &= ~a_dev
    else
      #rightshift the scratchpad.
      __rightshift_frac_with_underflow_check!(b.scratchpad, shift)
    end

    #do the actual subtraction.
    vbit = __carried_diff_frac!(vbit, minuend, b.scratchpad)

    if vbit == 0
      if (scratchpad_exp >= min_exponent(ESS))
        #shift
        __leftshift_frac!(b.scratchpad, 1)
        #Put in the guard bit.

        scratchpad_exp -= 1
      end

      if (scratchpad_exp >= min_exponent(ESS))
        (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
      else
        b.scratchpad.esize = $mesize
        b.scratchpad.exponent = z64
      end
    else
      b.scratchpad.esize = minuend.esize
      b.scratchpad.exponent = minuend.exponent
    end

    copy_unum_with_gflags!(b.scratchpad, b.$side)
  end
end

#=
###############################################################################
## multistage carried difference engine for uint64s.


################################################################################
## DIFFERENCE ALGORITHM

function __diff_ordered{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp::Int64, _bexp::Int64)
  #add two values, where a has a greater magnitude than b.  Both operands have
  #matching signs, either positive or negative.  At this stage, they may both
  #be ULPs.
  if (is_ulp(a) || is_ulp(b))
    __diff_ulp(a, b, _aexp, _bexp)
  else
    __diff_exact(a, b, _aexp, _bexp)
  end
end

function __diff_ulp{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp::Int64, _bexp::Int64)
  #a and b are ordered by magnitude and have opposing signs.

  #assign "exact" and "bound" a's
  (exact_a, bound_a) = is_ulp(a) ? (unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK), __outward_exact(a)) : (a, a)
  (exact_b, bound_b) = is_ulp(b) ? (unum_unsafe(b, b.flags & ~UNUM_UBIT_MASK), __outward_exact(b)) : (b, b)
  #recalculate these values if necessary.
  _baexp::Int64 = is_ulp(a) ? decode_exp(bound_a) : _aexp
  _bbexp::Int64 = is_ulp(b) ? decode_exp(bound_b) : _bexp

  if (_aexp - _bbexp > max_fsize(FSS))
    if is_ulp(a)
      is_negative(a) && return ubound_resolve(ubound_unsafe(a, inward_ulp(exact_a)))
      return ubound_resolve(ubound_unsafe(inward_ulp(exact_a), a))
    end
    return inward_ulp(a)
  end

  #do a check to see if a is almost infinite.
  if (is_mmr(a))
    #a ubound ending in infinity can't result in an ulp unless the lower subtracted
    #value is zero, which is already tested for.
    is_mmr(b) && return open_ubound(neg_mmr(Unum{ESS,FSS}), pos_mmr(Unum{ESS,FSS}))

    if (is_negative(a))
      #exploit the fact that __exact_subtraction ignores ubits.
      return open_ubound(a, __diff_exact(a, bound_b, _aexp, _bbexp))
    else
      return open_ubound(__diff_exact(a, bound_b, _aexp, _bbexp), a)
    end
  end

  far_result = __diff_exact(magsort(bound_a, exact_b)...)
  near_result = __diff_exact(magsort(exact_a, bound_b)...)

  if is_negative(a)
    ubound_resolve(open_ubound(far_result, near_result))
  else
    ubound_resolve(open_ubound(near_result, far_result))
  end
end

#attempts to shift the fraction as far as allowed.  Returns appropriate esize
#and exponent, and the new fraction.
function __shift_many_zeros(fraction, _aexp, ESS, lastbit::UInt64 = z64)
  maxshift::Int64 = _aexp - min_exponent(ESS)
  tryshift::Int64 = leading_zeros(fraction) + 1
  leftshift::Int64 = tryshift > maxshift ? maxshift : tryshift
  fraction = lsh(fraction, leftshift)

  #tack on that last bit, if necessary.
  (lastbit != 0) && (fraction |= lsh(superone(length(fraction)),(leftshift - 1)))

  (esize, exponent) = tryshift > maxshift ? (max_esize(ESS), z64) : encode_exp(_aexp - leftshift)

  (esize, exponent, fraction)
end

#a subtraction operation where a and b are ordered such that mag(a) > mag(b)
=#

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
  additiveinverse!(Unum{ESS,FSS}(x))
end
