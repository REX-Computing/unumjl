#unum-addition.jl
#Performs addition with unums.  Requires two unums to have the same
#environment signature.


doc"""
  `add!(::Unum{ESS,FSS}, ::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes two unums and
  adds them, storing the result in the third, g-layer

  `add!(::Unum{ESS,FSS}, ::Gnum{ESS,FSS})` takes two unums and adds them, storing
  the result and overwriting the second, g-layer

  In both cases, a reference to the result unum is returned.
"""
@generated function add!{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  #implementation of the three-argument add.

  quote
    #three argument check.
    override::Bool = __addition_check!(a, b, c)
    (override) && return

    #check to see if one or both Unums is indefinite.
    if ((a.flags & UNUM_UBIT_MASK) | (b.flags & UNUM_UBIT_MASK) != 0)
      inexact_add!(a, b, c)
    else
      exact_add!(a, b, c)
    end
  end
end

function __addition_check!{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  #zeros, and return the other value.
  is_zero(a) && (copy_gnum!(b, c); return true)
  is_zero(b) && (copy_gnum!(a, c); return true)
  #nans are really easy.
  is_nan(a) && (nan!(c); return true)
  is_nan(b) && (nan!(c); return true)

  #check for infinity.
  if (is_inf(a))
    (is_inf(b)) && (a.flags & UNUM_SIGN_MASK != b.flags & UNUM_SIGN_MASK) && (nan!(c); return true)
    inf!(c, a.flags & UNUM_SIGN_MASK)
    return true
  end
  #since infinity a is known, we don't need a complicated check.
  is_inf(b) && (inf!(c, b.flags & UNUM_SIGN_MASK); return true)

  (is_mmr(a)) && (a.flags & UNUM_SIGN_MASK == b.flags & UNUM_SIGN_MASK) && (mmr!(c, a.flags & UNUM_SIGN_MASK); return true)
  (is_mmr(b)) && (a.flags & UNUM_SIGN_MASK == b.flags & UNUM_SIGN_MASK) && (mmr!(c, b.flags & UNUM_SIGN_MASK); return true)
end
export add!

@gen_code function exact_add!(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  #calculate the exact sum between two unums.  You may pass this function a unum
  #with a ubit, but it will calculate the sum as if it didn't have the ubit there

  @code quote
    #retrieve the sign of the result.
    flags::UInt16 = a.flags & UNUM_SIGN_MASK

    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b)

    a_dev::Int64 = is_exp_zero(a) ? 1 : 0
    b_dev::Int64 = is_exp_zero(b) ? 1 : 0

    #derive the "contexts" for each, which is a combination of the exponent and
    #deviation.
    a_ctx::Int64 = a_exp + a_dev
    b_ctx::Int64 = b_exp + b_dev

    (b_ctx > a_ctx) && ((a, b, a_exp, b_exp, a_ctx, b_ctx) = (b, a, b_exp, a_exp, b_ctx, a_ctx))

    #zero out the gnum.
    zero!(c)

    #copy the contents of a into c.
    shift::UInt16 = c_ctx - b_ctx

    copy_frac!(b.fraction, c)

    flags = __rightshift_frac_with_underflow_check!(c, shift, flags, Val{:lower}))

    (shift != 0) && (b_dev == 0) && (set_frac_bit!(c, shift, Val{:lower}))

    #perform a carried add.  Start it off with a's phantom bit (1- a_dev), and
    #b's phantom bit if they are overlapping.
    carry::UInt64 = (1 - a_dev) + ((shift == 0) ? (1 - b_dev) : 0)

    carry = __carried_add_frac!(carry, a.fraction, c)

    #how much the exponent must be shifted.
    shift::UInt16 = (a_dev == 0) ? 0 : carry

    is_ubit = __shift_carry!(carry, c.lower_fraction, is_ubit)

    (fraction, fsize, is_ubit) = __frac_analyze(scratchpad, is_ubit, FSS)

  #if we started as subnormal, shift cannot be one, but we might have to addprocs
  #one to the exponent to account for the promotion from subnormal.  Otherwise,
  #exponent gets augmented as if it were a shift.
  _nexp = _aexp + shift

  #handle the carry bit (which may be up to three? or more).
  if (carry == 0)
    #don't use encode_exp because that might do strange things to subnormals.
    #just pass through esize, exponent from the a value.
    esize = a.esize
    exponent = a.exponent
  else
    #check for overflow, and return mmr if that happens.
    (_nexp > max_exponent(ESS)) && return mmr(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK)

    (esize, exponent) = encode_exp(_nexp)
  end

  #another way to get overflow is: by adding just enough bits to exactly
  #make the binary value for infinity.  This should, instead, yield mmr.
  (esize == max_esize(ESS)) && (fsize == max_fsize(FSS)) && (exponent == mask(1 << ESS)) && (fraction == fillbits(-(fsize + 1), l)) && return mmr(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK)

  flags |= is_ubit
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
