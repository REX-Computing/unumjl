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
  put_unum!(b, c, LOWER_SIDE)
  set_onesided!(c)
  add!(a, c)
end
function add!{ESS,FSS}(a::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  if ((a.flags & UNUM_SIGN_MASK) $ (b.flags & UNUM_SIGN_MASK) == 0)
    __arithmetic_addition(a, c)
  else
    __arithmetic_subtraction(a, c)
  end
end

#trampoline for using the arithmetic addition algorithm on numbers which are
#guaranteed to have identical parity.  Otherwise subtraction is necessary.
function __arithmetic_addition(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  #override
  __addition_override_check!(a, b)

  #check to see if one or both Unums is indefinite.
  if ((a.flags & UNUM_UBIT_MASK) | (b.flags & UNUM_UBIT_MASK) != 0)
    inexact_add!(a, b, c)
  else
    exact_add!(a, b, c, Val{:lower})
    c.lower_flags |= GNUM_SBIT_MASK
  end
  clear_ignore_sides!(b)
  nothing
end


#a function which checks for special values that will override actually performing
#calculations.
function __addition_override_check!{ESS,FSS}(a::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  ############################################
  # deal with zeros.
  #if our addend is zero, then we just leave both sides alone.
  is_zero(a) && (ignore_both_sides!(b); return)
  #if either side is zero, then copy the addend in to the Gnum.
  is_zero(b, LOWER_SIDE) && (copy_gnum!(a, b); set_ignore_side!(b, LOWER_SIDE))
  is_zero(b, UPPER_SIDE) && is_twosided(b) && (copy_gnum!(a, b); set_ignore_side!(b, UPPER_SIDE))
  ############################################
  # deal with NaNs.
  #if our addend is nan, then set the addend to nan.
  is_nan(a) && (@scratch_this_operation!(b))
  is_nan(b) && (ignore_both_sides!(b); return)
  ############################################
  # deal with infinities.
  if (is_inf(a))
    #check to see if lower infinity is the opposite infinity.
    is_inf(b, LOWER_SIDE) && ((a.flags & UNUM_SIGN_MASK) != (b.lower_flags & UNUM_SIGN_MASK)) && @scratch_this_operation!(b)
    is_inf(b, UPPER_SIDE) && ((a.flags & UNUM_SIGN_MASK) != (b.upper_flags & UNUM_SIGN_MASK)) && @scratch_this_operation!(b)
    #since we know it's a finite, real value, we can set one or both sides of our gnum to infinity as needed.
    inf!(b, a.flags & UNUM_SIGN_MASK, LOWER_SIDE)
    set_ignore_side!(b, LOWER_SIDE)

    is_twosided(b) && (inf!(b, a.flags & UNUM_SIGN_MASK, UPPER_SIDE); set_ignore_side!(b, UPPER_SIDE))
  end
  #since a is known to be finite real, we don't need a complicated check.
  should_calculate(b, LOWER_SIDE) && is_inf(b, LOWER_SIDE) && (set_ignore_side!(b, LOWER_SIDE))
  should_calculate(b, UPPER_SIDE) && is_inf(b, UPPER_SIDE) && (set_ignore_side!(b, UPPER_SIDE))

  ############################################
  #deal with mmr collapsing.
  if (is_mmr(a))
    if (should_calculate(b, LOWER_SIDE) && (a.flags & UNUM_SIGN_MASK == b.lower_flags & UNUM_SIGN_MASK))
      mmr!(b, a.flags & UNUM_SIGN_MASK, LOWER_SIDE)
      set_ignore_side!(b, LOWER_SIDE)
    end
    if (should_calculate(b, UPPER_SIDE) && (a.flags & UNUM_SIGN_MASK == b.upper_flags & UNUM_SIGN_MASK))
      mmr!(b, a.flags & UNUM_SIGN_MASK, UPPER_SIDE)
      set_ignore_side!(b, UPPER_SIDE)
    end
  end
  if (should_calculate(b, LOWER_SIDE) && is_mmr(b, LOWER_SIDE) && (a.flags & UNUM_SIGN_MASK == b.lower_flags & UNUM_SIGN_MASK))
    set_ignore_side!(b, LOWER_SIDE)
  end
  if (should_calculate(b, UPPER_SIDE) && is_mmr(b, UPPER_SIDE) && (a.flags & UNUM_SIGN_MASK == b.upper_flags & UNUM_SIGN_MASK))
    set_ignore_side!(b, UPPER_SIDE)
  end
end

################################################################################
# exact_add!  - a function which takes a general addition algorithm and distributes
# it to both sides of the unum.

function exact_add!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  should_calculate(b, LOWER_SIDE) && exact_add_one_side!(b, LOWER_SIDE)
  should_calculate(b, UPPER_SIDE) && exact_add_one_ised!(b, UPPER_SIDE)
  b
end

################################################################################
#behold!  The actual addition algorithm
@gen_code function exact_add_one_side!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})

  mesize::UInt16 = max_esize(ESS)
  mfsize::UInt16 = max_fsize(FSS)
  (FSS < 7) && (mfrac::UInt64 = mask_top(FSS))
  mexp::UInt64 = max_exponent(ESS)

  @gnum_interpolate #set the fs es fl frc exp values to match the side!

  @code quote
    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b, Val{side})

    a_dev::Int64 = is_exp_zero(a) ? 1 : 0
    b_dev::Int64 = is_exp_zero(b, Val{side}) ? 1 : 0

    #derive the "contexts" for each, which is a combination of the exponent and
    #deviation.
    a_ctx::Int64 = a_exp + a_dev
    b_ctx::Int64 = b_exp + b_dev

    #check to see which context is bigger.
    if (a_ctx > b_ctx)
      #then move b to the scratchpad.
      move_to_scratchpad!(b, Val{side})
      #calculate shift as the difference between a and b
      shift::UInt16 = a_ctx - b_ctx

      #rightshift the scratchpad.
      __rightshift_frac_with_underflow_check!(b, shift, SCRATCHPAD)
      (shift != 0) && (b_dev == 0) && (set_frac_bit!(b, shift, SCRATCHPAD))

      #set up the carry bit.
      carry::UInt64 = (1 - a_dev) + ((shift == 0) ? (1 - b_dev) : 0)

      carry = __carried_add_frac!(carry, a.fraction, c, Val{side})

      #set the new exponent
      n_exp::Int = a_exp
    else
      #move a to the scratchpad.
      put_unum!(a, b, SCRATCHPAD)
      #calculate shift as the difference between b a nd a
      shift = b_ctx - a_ctx

      #rightshift the scratchpad.
      __rightshift_frac_with_underflow_check!(b, shift, SCRATCHPAD)
      (shift != 0) && (a_dev == 0) && (set_frac_bit!(b, shift, SCRATCHPAD))

      #set up the carry bit.
      carry = (1 - b_dev) + ((shift == 0) ? (1 - a_dev) : 0)

      carry = __carried_add_frac!(carry, a.fraction, c, Val{side})

      #set the new exponent
      n_exp::Int = b_exp
    end

    if (carry > 1)
      n_exp += 1
      __rightshift_frac_with_underflow_check!(c, 0x0001, Val{side})
      (carry == 3) && set_frac_top!(c, Val{side})
    end

    #set the fsize.
    c.$fs = $mfsize - min(((c.$fs & UNUM_UBIT_MASK != 0) ? 0 : ctz(c.$frc)), $mfsize)

    #set exponent stuff.
    #handle the carry bit (which may be up to three? or more).
    if (carry == 0)
      #don't use encode_exp because that might do strange things to subnormals.
      #just pass through esize, exponent from the a value.
      c.$es = a.esize
      c.$exp = a.exponent
    else
      #check for overflow, and return mmr if that happens.
      (n_exp > max_exponent(ESS)) && (mmr!(c, c.$fl, Val{side}); return)
      #we know it can't be subnormal, because we've added one to the exponent.
      (c.$es, c.$exp) = encode_exp(n_exp)
    end

    #another way to get overflow is: by adding just enough bits to exactly
    #make the binary value for infinity.  This should, instead, yield mmr.
  end

  if (FSS < 7)
    @code quote
      (c.$es == $mesize) && (c.$fs == $mfsize) && (c.$exp == $mexp) && (c.$fs == $mfrac) && (mmr!(c, c.$fl, Val{side}))
    end
  else
    @code quote
      (c.$es == $mesize) && (c.$fs == $mfsize) && (c.$exp == $mexp) && (is_all_ones(c.$fs)) && (mmr!(c, c.$fl, Val{side}))
    end
  end
end


import Base.+
function +{ESS,FSS}(x::Unum{ESS,FSS}, y::Unum{ESS,FSS})
  temp = zero(Gnum{ESS,FSS})
  res = zero(Unum{ESS,FSS})

  add!(x, y, temp)

  #return the result as the appropriate data type.
  emit_data(temp)
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
