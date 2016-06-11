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
    #kick it to the unum_difference function which calculates numeric difference
    (a > b) ? unum_sum(a, b, _aexp, _bexp) : unum_sum(b, a, _bexp, _aexp)
  else
    #kick it to the unum_sum function which calculates numeric sum.
    (a > b) ? unum_diff(a, b, _aexp, _bexp) : additiveinverse!(unum_diff(b, a, _bexp, _aexp))
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
  is_inf(a) && return is_inf(b) ? nan(T) : inf(T, @signof a)
  is_mmr(a) && throw(ArgumentError("Not implemented yet"))
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

  #copy the b unum as the temporary result.
  result = copy(b)
  #set the sign to the sign of the dominant figure.
  coerce_sign!(result, a)

  if _shift == z16
    carry::UInt64 = z64
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
  #one possibility is that the outward_exact value of b is greater than the
  #base value of a.  We need to check that possibilty.
  if outward_exact(b) > a
    throw(ArgumentError("not supported yet"))
  end

  #first, do the inexact sum, to calculate the "base value" of the resulting sum.
  base_value = diff_exact(a, b)
end

################################################################################
## here lies code that will be kept for later.


#=
@generated function __arithmetic_subtraction!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  quote
    if is_ulp(a)
      if is_exact(b.$side)
        #we're going to swap operation order.  Is there maybe a better way to do this?
        copy_unum!(b.$side, b.buffer)
        copy_unum!(a, b.$side)
        __exact_arithmetic_subtraction!(b.buffer, b, Val{side})
      else
        __inexact_arithmetic_subtraction!(a, b, Val{side})
      end
    else
      __exact_arithmetic_subtraction!(a, b, Val{side})
    end
  end
end

@generated function __inexact_arithmetic_subtraction!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  if (side == :lower)
    quote
      copy_unum!(a, b.buffer)
      if (is_positive(a))
        is_onesided(b) && copy_unum!(b.lower, b.upper)
        #the upper_exact function mutates the buffer contents so we use the lower first.
        __exact_arithmetic_subtraction!(b.buffer, b, LOWER_UNUM)
        if (is_onesided(b))
          upper_exact!(b.buffer)
          __exact_arithmetic_subtraction!(b.buffer, b, UPPER_UNUM)

          ignore_side!(b, UPPER_UNUM)
          set_twosided!(b)
        end
      else
        #the lower_exact function mutates the buffer contents so we do the upper first.
        if (is_onesided(b))
          copy_unum!(b.lower, b.upper)
          __exact_arithmetic_subtraction!(b.buffer, b, UPPER_UNUM)

          ignore_side!(b, UPPER_UNUM)
          set_twosided!(b)
        end
        lower_exact!(b.buffer)
        __exact_arithmetic_subtraction!(b.buffer, b, LOWER_UNUM)
      end
    end
  else
    :(nan!(b))
  end
end

#performs an exact arithmetic subtraction algorithm.  The assumption here is
#that a and b have opposite signs and are to be summed as such.  The value in
#b will be exact, but the value in a may or may not have an ulp.
@gen_code function __exact_arithmetic_subtraction!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})#for subtraction, resolving strange subnormal numbers as a first step is critical.
  mesize::UInt16 = max_esize(ESS)

  @code quote
    is_strange_subnormal(a) && (resolve_subnormal!(a))
    is_strange_subnormal(b.$side) && (resolve_subnormal!(b.$side))

    was_ubit::Bool = is_ulp(b.$side)

    b_exp::Int64 = decode_exp(b.$side)
    b_dev::UInt64 = is_exp_zero(b.$side) * o64
    b_ctx::Int64 = b_exp + b_dev

    #set the exp and dev values.
    a_exp::Int64 = decode_exp(a)
    #set the deviations due to subnormality.
    a_dev::UInt64 = is_exp_zero(a) * o64
    #set the exponential contexts for both variables.
    a_ctx::Int64 = a_exp + a_dev

    #set up a placeholder for the minuend.
    shift::Int64
    vbit::UInt64
    minuend::Unum{ESS,FSS}
    scratchpad_exp::Int64
    @init_sflags()

    #is a bigger?  For subtraction, we must do more intricate testing.
    a_bigger = (a_exp > b_exp)
    if (a_exp == b_exp)
      a_bigger = a_bigger || ((a_dev == 0) && (b_dev != 0))
      a_bigger = a_bigger || (a_dev == b_dev) && ((a.fraction > b.$side.fraction))
    end

    if a_bigger
      minuend = a
      @preserve_sflags b begin
        copy_unum!(b.$side, b.scratchpad)
        b.scratchpad.flags = a.flags & UNUM_SIGN_MASK
      end
      #set the scratchpad exponents to the a settings.
      b.scratchpad.esize = a.esize
      b.scratchpad.exponent = a.exponent
      #calculate shift as the difference between a and b
      shift = a_ctx - b_ctx
      #set up the virtual bit.
      vbit = (o64 - a_dev) - ((shift == z64) * (o64 - b_dev))
      scratchpad_exp = a_exp
    else
      minuend = b.$side
      #move the unum value to the scratchpad.
      @preserve_sflags b begin
        put_unum!(a, b, SCRATCHPAD)
        b.scratchpad.flags = b.$side.flags & UNUM_SIGN_MASK
      end
      #set the scratchpad exponents to the b settings.
      b.scratchpad.esize = b.$side.esize
      b.scratchpad.exponent = b.$side.exponent
      #calculate the shift as the difference between a and b.
      shift = b_ctx - a_ctx
      #set up the carry bit.
      vbit = (o64 - b_dev) - ((shift == z64) * (o64 - a_dev))
      scratchpad_exp = b_exp
    end

    #rightshift the scratchpad.
    (shift != 0) && __rightshift_frac_with_underflow_check!(b.scratchpad, shift)

    #do the actual subtraction.
    vbit = __carried_diff_frac!(vbit, minuend, b.scratchpad)

    #we only need to adjust things if we're not subnormal.
    if (vbit == 0) && (b.scratchpad.exponent > 0)
      if (scratchpad_exp >= min_exponent(ESS))
        #shift, only if we're not transitioning into subnormal.
        b.scratchpad.exponent > 1 && __leftshift_frac!(b.scratchpad, 1)
        #Put in the guard bit.
        scratchpad_exp -= 1
      end

      if (scratchpad_exp >= min_exponent(ESS))
        (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
      else
        b.scratchpad.esize = $mesize
        b.scratchpad.exponent = z64
      end
    end

    ############################################################################
    #now, deal with ubits.
    if (was_ubit)
      if is_positive(b.scratchpad) == is_positive(b.$side)
        b.scratchpad.flags |= UNUM_UBIT_MASK
      else
        __inward_ulp!(b.scratchpad)
      end
    end

    copy_unum!(b.scratchpad, b.$side)
  end
end
=#
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
function -{ESS,FSS}(x::Gnum{ESS,FSS})
  additiveinverse!(Unum{ESS,FSS}(x))
end
