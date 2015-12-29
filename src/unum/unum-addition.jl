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

@generated function __exact_arithmetic_addition!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  mesize::UInt16 = max_esize(ESS)
  mfsize::UInt16 = max_fsize(FSS)
  (FSS < 7) && (mfrac::UInt64 = mask_top(FSS))
  mexp::UInt64 = max_exponent(ESS)

  quote
    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b.$side)

    a_dev::UInt64 = is_exp_zero(a) * o64
    b_dev::UInt64 = is_exp_zero(b.$side) * o64

    #derive the "contexts" for each, which is a combination of the exponent and
    #deviation.
    a_ctx::Int64 = a_exp + a_dev
    b_ctx::Int64 = b_exp + b_dev

    #set up a placeholder for the addend.
    addend::Unum{ESS,FSS}
    shift::Int64
    carry::UInt64
    scratchpad_exp::Int64
    scratchpad_dev::UInt64
    @init_sflags()
    #check to see which context is bigger.
    if (a_ctx > b_ctx) || ((a_ctx == b_ctx) && (b_dev != z64))
      #set the placeholder to the value a.
      addend = a
      @preserve_sflags b copy_unum!(b.$side, b.scratchpad)
      #calculate shift as the difference between a and b
      shift = a_ctx - b_ctx
      #set up the carry bit.
      carry = (o64 - a_dev) + ((shift == z64) * (o64 - b_dev))
      scratchpad_exp = a_exp
      scratchpad_dev = a_dev
    else
      #set the placeholder to the value b.
      addend = b.$side
      #move the unum value to the scratchpad.
      @preserve_sflags b put_unum!(a, b, SCRATCHPAD)
      #calculate the shift as the difference between a and b.
      shift = b_ctx - a_ctx
      #set up the carry bit.
      carry = (o64 - b_dev) + ((shift == z64) * (o64 - a_dev))
      scratchpad_exp = b_exp
      scratchpad_dev = b_dev
    end

    #rightshift the scratchpad, then set the invisible bit that may have moved.
    __rightshift_frac_with_underflow_check!(b.scratchpad, shift)
    (shift != 0) && (b_dev == 0) && (set_frac_bit!(b.scratchpad, shift))

    #perform the carried add.
    carry = __carried_add_frac!(carry, addend, b.scratchpad)

    #set esize and exponent parts.
    b.scratchpad.esize = addend.esize
    b.scratchpad.exponent = addend.exponent

    if (scratchpad_dev == z64)
      #for non-subnormal things do the following:
      if (carry > 1)
        scratchpad_exp += 1
        if scratchpad_exp > $mexp
          @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)
        else
          #shift things over by one since we went up in size.
          __rightshift_frac_with_underflow_check!(b.scratchpad, 1)
          #carry from the carry over into the fraction.
          (carry == 3) && set_frac_top!(b.scratchpad)
          #re-encode the exponent.
          (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
        end
      end
    else
      #for subnormal values, we have to augment the exponent slightly differently.
      if (carry > 0)
        b.scratchpad.exponent = o64
      end
    end

    #set the fsize.
    b.scratchpad.fsize = $mfsize - min(((b.scratchpad.fsize & UNUM_UBIT_MASK != 0) ? 0 : ctz(b.scratchpad.fraction)), $mfsize)

    #another way to get overflow is: by adding just enough bits to exactly
    #make the binary value for inf or nan.  This should, instead, yield mmr.
    #nb:  the is_inf call here is the UNUM is_inf, which checks across all the
    #bits, not the gnum is_inf, which only looks at the flag in the flags holder.
    __is_nan_or_inf(b.scratchpad) && @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)
    is_mmr(b.scratchpad) && @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)

    copy_unum_with_gflags!(b.scratchpad, b.$side)
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

#=
#instead of making unary plus "do nothing at all", we will have it "firewall"
#the variable by creating a copy of it.  Use the "unsafe" constructor to save
#on checking since we know the source unum is valid.
+(x::Unum) = unum_unsafe(x)
#unary minus uses the shorthand pseudoconstructor, where all the values are the
#same but the flags may be altered.
-(x::Unum) = unum_unsafe(x, x.flags $ UNUM_SIGN_MASK)

#binary add performs a series of checks to find faster solutions followed by
#passing to either the 'addition' or 'subtraction' algorithms.  Two separate
#algorithms are necessary because of the zero-symmetrical nature of the unum
#floating point spec.
function +{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #some basic gating checks before we do any crazy operations.
  #one, is either one zero?
  is_zero(a) && return b
  is_zero(b) && return a
  #do a nan check
  (isnan(a) || isnan(b)) && return nan(Unum{ESS,FSS})

  #infinities plus anything is NaN if opposite infinity. (checking for operand a)
  if (isinf(a))
    (isinf(b)) && (a.flags & UNUM_SIGN_MASK != b.flags & UNUM_SIGN_MASK) && return nan(Unum{ESS,FSS})
    return inf(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK)
  end

  #infinities b (infinity a is ruled out) plus anything is b
  (isinf(b)) && return inf(Unum{ESS,FSS}, b.flags & UNUM_SIGN_MASK)


  #sort a and b and then add them using the gateway operation.
  __add_ordered(magsort(a,b)...)
end

#subtraction - merely flip the bit first and then roll with it.
function -(a::Unum, b::Unum)
  #check equality and return zero if equal.  It may not be the fastest to
  #create a new object before subtracting, but for now we won't optimize this.
  a + -b
end

##########################TODO:  Implement integers by converting upwards first.

const __MASK_TABLE = [0x8000_0000_0000_0000, 0xC000_0000_0000_0000, 0xF000_0000_0000_0000, 0xFF00_0000_0000_0000, 0xFFFF_0000_0000_0000, 0xFFFF_FFFF_0000_0000]

#performs a carried add on an unsigned integer array.
function __carried_add(carry::UInt64, v1::VarInt, v2::VarInt)
  #first perform a direct sum on the integer arrays
  res = v1 + v2
  #check to see if we need a carry.  Note last() can operate on scalar values
  (last(res) < last(v1)) && (carry += 1)
  #iterate downward from the most significant word
  for idx = length(v1):-1:2
    #if it looks like it's lower than it should be, then make it okay.
    if res[idx - 1] < v1[idx - 1]
      #we don't need to worry about carries because at most we can be
      #FFF...FFF + FFF...FFF = 1FFF...FFFE
      res[idx] += 1
    end
  end
  (carry, res)
end

#returns a (VarInt, int, bool) triplet:  (value, shift, falloff)
function __shift_after_add(carry::UInt64, value::VarInt, is_ubit::UInt16)
  #cache the length of value
  l::UInt16 = length(value)
  #calculate how far we have to shift.
  shift = 64 - leading_zeros(carry) - 1
  #did we lose values off the end of the number?
  (is_ubit == 0) && (is_ubit = (value & fillbits(shift, l)) != superzero(l))
  #shift the value over
  value = rsh(value, shift)
  #copy the carry over.
  if (l > 1)
    value[l] |= carry << (64 - shift)
  else
    value |= carry << (64 - shift)
  end
  (value, shift, is_ubit)
end

################################################################################
## GATEWAY OPERATION

#an addition operation where a and b are ordered such that mag(a) > mag(b)
function __add_ordered{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp::Int64, _bexp::Int64)
  a_neg = is_negative(a)
  b_neg = is_negative(b)

  if (b_neg != a_neg)
    __diff_ordered(a, b, _aexp, _bexp)
  else
    __sum_ordered(a, b, _aexp, _bexp)
  end
end

################################################################################
## SUM ALGORITHM

function __sum_ordered{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp::Int64, _bexp::Int64)
  #add two values, where a has a greater magnitude than b.  Both operands have
  #matching signs, either positive or negative.  At this stage, they may both
  #be ULPs.
  if (is_ulp(a) || is_ulp(b))
    __sum_ulp(a, b, _aexp, _bexp)
  else
    __sum_exact(a, b, _aexp, _bexp)
  end
end

function __sum_ulp{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp::Int64, _bexp::Int64)
  #a and b are ordered by magnitude and have the same sign.

  #thus, if a is mmr, it can only result in mmr.
  is_mmr(a) && return mmr(Unum{ESS,FSS})

  #assign "exact" and "bound" a's
  (exact_a, bound_a) = is_ulp(a) ? (unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK), __outward_exact(a)) : (a, a)
  (exact_b, bound_b) = is_ulp(b) ? (unum_unsafe(b, b.flags & ~UNUM_UBIT_MASK), __outward_exact(b)) : (b, b)

  #recalculate these values if necessary.
  _baexp::Int64 = is_ulp(a) ? decode_exp(bound_a) : _aexp
  _bbexp::Int64 = is_ulp(b) ? decode_exp(bound_b) : _bexp

  #find the high and low bounds.  Pass this to a subsidiary function
  far_result  = __sum_exact(bound_a, bound_b, _baexp, _bbexp)
  near_result = __sum_exact(exact_a, exact_b, _aexp, _bexp)

  if (is_negative(a))
    ubound_resolve(open_ubound(far_result, near_result))
  else
    ubound_resolve(open_ubound(near_result, far_result))
  end
end

function __sum_exact{ESS, FSS}(a::Unum{ESS,FSS}, b::Unum{ESS, FSS}, _aexp::Int64, _bexp::Int64)


  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end
=#
