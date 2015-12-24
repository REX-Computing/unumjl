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





###############################################################################
## multistage carried difference engine for uint64s.

function __carried_diff(carry::UInt64, v1::VarInt, v2::VarInt, trail::UInt64 = z64)
  #run a difference engine across an array of 64-bit integers
  l = length(v1)
  #"carry" will usually be one, but there are other possibilities (e.g. zero)
  if (l == 1)
    fraction = v1 - v2 - ((trail != 0) ? 1 : 0)
    #decrement the carry bit if it looks like we've pulled from it.
    (fraction >= v1) && (v2 != 0) && (carry -= 1)
  else
    fraction = __copy_superint(v1)
    fraction[1] -= trail
    for (idx = 1:(l - 1))
      fraction[idx] -= v2[idx]
      ((fraction[idx] >= v1[idx]) && (v2[idx] != 0)) && (fraction[idx + 1] -= 1)
    end
    #for the last fraction, we pull from carry.
    fraction[l] -= v2[l]
    ((fraction[l] >= v1[l]) && (v2[l] != 0)) && (carry -= 1)
  end
  (carry, fraction)
end

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
function __diff_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp::Int64, _bexp::Int64)

  l::UInt16 = length(a.fraction)
  # a series of easy cases.
  (a == -b) && return zero(Unum{ESS,FSS})

  (is_zero(b)) && return unum_unsafe(a)
  (is_zero(a)) && return -b

  #reassign a to a resolved subnormal value.
  is_strange_subnormal(a) && (a = __resolve_subnormal(a))
  is_strange_subnormal(b) && (b = __resolve_subnormal(b))

  #check for deviations due to subnormality.
  a_dev::Int16, carry::UInt64 = is_exp_zero(a) ? (o16, z64) : (z16, o64)
  #set the carry.
  b_dev::Int16 = is_exp_zero(b) ? o16 : z16

  #calculate the bit offset
  bit_offset = UInt16((_aexp + a_dev) - (_bexp + b_dev))

  if (bit_offset > max_fsize(FSS))
    #return the previous unum, but with the ubit flag thrown up.
    return unum_unsafe(__inward_exact(a), a.flags & UNUM_SIGN_MASK)
  end

  if (bit_offset == 0)
    #this is the easy case where we don't have to do much.
    #note three cases:
    # a -normal, b -normal       - carry = 0
    # a -normal, b -subnormal    - carry = 1 (keeps old value)
    # a -subnormal, b -subnormal - carry = 0 (keeps old value)
    is_exp_zero(b) || (carry = 0) #only bash the value if b is normal.
    #do the direct subtraction.
    #This could trigger a carry in the a-normal, b-subnormal case.

    fraction = a.fraction - b.fraction
    #check this.
    (fraction > a.fraction) && (carry = 0)
    #a special case is that we've got a ton of leading zeros.
    if (carry == 0)
      #count how much we have to shift by....  Limit this so that we don't cross
      #over to subnormal-land.  Note that this result is never going to be a ulp.
      (esize, exponent, fraction) = __shift_many_zeros(fraction, _aexp, ESS)
      fsize = __minimum_data_width(fraction)
      return Unum{ESS,FSS}(fsize, esize, a.flags, fraction, exponent)
    end
    scratchpad = fraction
  else
    #set up a scratchpad.  This will contain the 'correct' value of b in the frac
    #framework of a.  First shift all of the bits from b.
    scratchpad = rsh(b.fraction, bit_offset)

    #then throw in virtual bit that corresponds to the leading digit, but only
    #if b is normal.
    is_exp_zero(b) || (scratchpad |= __bit_from_top(bit_offset, l))
  end

  #if we started with a subnormal a (which should be maximally subnormal), we are
  #done. note that we don't have to throw a ubit flag on because a subtraction
  #yielding smallsubnormal should have been impossible.
  (is_exp_zero(a)) && return Unum{ESS,FSS}(__minimum_data_width(fraction), max_esize(ESS), a.flags & UNUM_SIGN_MASK, a.fraction - scratchpad, z64)


  #set up some common variables as defaults.
  esize::UInt16 = a.esize
  exponent::UInt64 = a.exponent
  #here the code bifurcates.  for FSS < 6, life is much simpler, we can just
  #use the space within the 64-bit fraction.
  #PART ONE.  CALCULATE (carry, fraction, trail)
  frac_mask = __frac_mask(FSS)
  if (FSS < 6)
    #calculate chop-off...  Include an extra bit because that's our lagging bit.
    #do the subtraction.
    fraction = a.fraction - scratchpad
    #check to see if we have to carry, don't forget to left shift.
    (fraction > a.fraction) && (carry = 0; fraction << 1)
    #set the ubit, for sure if we have material past the trailing bit.
    is_ubit::UInt16 = ((~frac_mask & fraction) != 0) ? UNUM_UBIT_MASK : z16
    #assign the trailing variable
    trail::UInt64 = (is_ubit != 0) ? 1 : 0
    #mask out all but the top of the fraction.
    fraction = fraction & (frac_mask)
  else
    #check to see if we dropped digits off the end.
    is_ubit = (bit_offset > 0 && allzeros(fillbits(bit_offset, l) & b.fraction)) ? 0 : UNUM_UBIT_MASK
    #first figure out if there was a trailing bit.
    trail = (is_ubit != 0) ? o64 : z64
    (carry, fraction) = __carried_diff(carry, a.fraction, scratchpad, trail)
  end

  #PART TWO.  DEAL WITH THE CONSEQUENCES OF (carry, fraction, lag)
  #check if we have to shift one unit to the right.
  if (carry == 0) && (_aexp > min_exponent(ESS))
    #shift.
    if (bit_offset == 1)
      (esize, exponent, fraction) = __shift_many_zeros(fraction, _aexp, ESS, trail)
    else
      fraction = lsh(fraction, 1)
      #shift the exponent, too.
      (esize, exponent) = encode_exp(_aexp - 1)
      #fill in the last bit of the fraction.
      (trail != 0) && (fraction = __set_lsb(fraction, FSS))
    end
    fraction = fraction & frac_mask
  else
    #no shift.  If we have a trailing bit, ignore it and set the result to have UBIT flag.
    (trail != 0) && (is_ubit |= UNUM_UBIT_MASK)
    fsize::UInt16 = (is_ubit != 0) ? max_fsize(FSS) : __minimum_data_width(fraction)
    ((fraction & __bit_from_top(1 << FSS + 1, 1)) != 0) && return Unum{ESS,FSS}(fsize, a.esize, a.flags | is_ubit, fraction & frac_mask, a.exponent)
    fraction = fraction & frac_mask
  end

  #recalculate fsize.
  fsize = (is_ubit != 0) ? max_fsize(FSS) : __minimum_data_width(fraction)
  Unum{ESS,FSS}(fsize, esize, a.flags | is_ubit, fraction, exponent)
end
<<<<<<< HEAD

import Base.-
function -{ESS,FSS}(x::Unum{ESS,FSS}, y::Unum{ESS,FSS})
  temp = zero(Gnum{ESS,FSS})
  sub!(x, y, temp)
  #return the result as the appropriate data type.
  emit_data(temp)
end
=======
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
