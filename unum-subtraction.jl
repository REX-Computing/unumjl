#unit-subtraction.jl
#implements addition primitives where the vectors of the two values point in
#opposing directions.  This is organized into a separate file for convenience
#purposes (these primitives can be very large.)

###############################################################################
## multistage carried difference engine for uint64s.

function __carried_diff(carry::Uint64, v1::SuperInt, v2::SuperInt, lag_carry = z64)
  #run a difference engine across an array of 64-bit integers
  #"carry" will usually be one, but there are other possibilities (e.g. zero)

  #first perform a direct difference on the integer arrays.
  res = v1 - v2

  if (length(v1) == 1)
    res -= lag_carry
  else
    res[1] -= lag_carry
  end

  #iterate downward from the most significant cell.  Sneakily, this loop
  #does not execute if we have a singleton SuperInt
  for idx = 1:length(v1) - 1
    #if it looks like it's higher than it should be....
    if res[idx] > v1[idx]
      #we don't need to worry about carries because at most we can be
      #FFF...FFF + FFF...FFF = 1FFF...FFFE
      res[idx + 1] -= 1
    end
  end

  #check to see if we need a carry.  Note last() can operate on scalar values
  (last(res) > last(v1)) && (carry -= 1)
  (carry, res)
end

################################################################################
## DIFFERENCE ALGORITHM

function __diff_ordered(a, b, _aexp, _bexp)
  #add two values, where a has a greater magnitude than b.  Both operands have
  #matching signs, either positive or negative.  At this stage, they may both
  #be ULPs.
  if (is_ulp(a) || is_ulp(b))
    __diff_ulp(a, b, _aexp, _bexp)
  else
    __diff_exact(a, b, _aexp, _bexp)
  end
end

function __diff_ulp{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp, _bexp)
  #a and b are ordered by magnitude and have opposing signs.

  #assign "exact" and "bound" a's
  (exact_a, bound_a) = is_ulp(a) ? (unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK), __outward_exact(a)) : (a, a)
  (exact_b, bound_b) = is_ulp(b) ? (unum_unsafe(b, b.flags & ~UNUM_UBIT_MASK), __outward_exact(b)) : (b, b)
  #recalculate these values if necessary.
  _baexp = is_ulp(a) ? decode_exp(bound_a) : _aexp
  _bbexp = is_ulp(b) ? decode_exp(bound_b) : _bexp

  #println("exact_a: $(bits(exact_a)) bound_a: $(bits(bound_a))")
  #println("exact_b: $(bits(exact_b)) bound_b: $(bits(bound_b))")

  #do a check to see if a is almost infinite.
  if (is_mmr(a))
    #a ubound endinc in infinity can't result in an ulp unless the lower subtracted
    #value is zero, which is already tested for.
    is_mmr(b) && return open_ubound(neg_mmr(Unum{ESS,FSS}), pos_mmr(Unum{ESS,FSS}))

    if (is_negative(a))
      #exploit the fact that __exact_subtraction ignores ubits.
      return open_ubound(a, __diff_exact(a, bound_b, _aexp, _bbexp))
    else
      return open_ubound(__diff_exact(a, bound_b, _aexp, _bbexp), a)
    end
  end

  far_result = __diff_exact(bound_a, exact_b, _baexp, _bexp)
  near_result = __diff_exact(magsort(exact_a, bound_b)...)

  if is_negative(a)
    ubound_resolve(open_ubound(far_result, near_result))
  else
    ubound_resolve(open_ubound(near_result, far_result))
  end
end

#a subtraction operation where a and b are ordered such that mag(a) > mag(b)
function __diff_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp, _bexp)
  l::Uint16 = length(a.fraction)
  # a series of easy cases.
  (a == -b) && return zero(Unum{ESS,FSS})
  (iszero(b)) && return unum_unsafe(a)
  (iszero(a)) && return -b

  #reassign a to a resolved subnormal value.
  isexpzero(a) && (a.esize != max_esize(ESS)) && (a = __resolve_subnormal(a))

  #check for deviations due to subnormality.
  a_dev::Int16, carry::Uint64 = isexpzero(a) ? (o16, z64) : (z16, o64)
  b_dev::Int16 = isexpzero(b) ? o16 : z16

  #calculate the bit offset
  bit_offset = uint16((_aexp + a_dev) - (_bexp + b_dev))

  if (bit_offset > max_fsize(FSS))
    #return the previous unum, but with the ubit flag thrown up.
    return unum_unsafe(__inward_exact(a), a.flags & UNUM_UBIT_MASK)
  end

  #set up carry, lag bit, and flags.  Carry defaults to 1 (leading virtual bit)
  #lag_bit defaults to zero, since this is an exact number.
  lag_bit::Uint64 = 0
  flags::Uint16 = a.flags & UNUM_SIGN_MASK

  if (bit_offset == 0)
    #this is the easy case where we don't have to do much...
    isexpzero(b) || (carry = 0)

    (carry, fraction) = __carried_diff(carry, a.fraction, b.fraction)
  else
    #set up a scratchpad.  This will contain the 'correct' value of b in the frac
    #framework of a.  First shift all of the bits from b.
    scratchpad = b.fraction >> bit_offset

    #then throw in virtual bit that corresponds to the leading digit.
    !isexpzero(b) && (scratchpad |= __bit_from_top(bit_offset, l))

    #first, let's isolate the "chop" region of the subtrahend b - if this is 1 then
    #we have to carry from the main, and also set the ubit to be on.
    allzeros(b.fraction & fillbits(bit_offset, l)) || (flags |= UNUM_UBIT_MASK; lag_bit = 1)
    #next, we have to check the position under the lag bit, which only throws the lag bit
    #and not (necessarily) the ubit.
    (bitof(b.fraction, bit_offset) == 0) || (lag_bit = 1)
    #if we found a lag bit, be sure to subtract an extra one from the scratchpad.
    (carry, fraction) = __carried_diff(carry, a.fraction, scratchpad, lag_bit)
  end

  #if we started with a subnormal a (which should be maximally subnormal), we are
  #done. note that we don't have to throw a ubit flag on because a subtraction
  #yielding smallsubnormal should have been impossible.
  (isexpzero(a)) && return Unum{ESS,FSS}(__fsize_of_exact(fraction), max_esize(ESS), flags, fraction, z64)

  fsize::Uint16 = 0
  #process the remaining factors: carry, fraction, lag_bit
  if (carry == 0)
    #set shift to be as big as it can be.
    shift = clz(fraction) + 1
    #modify _aexp here.
    if shift > (_aexp - min_exponent(ESS))
      #just push it as far as we can push it.
      fraction = fraction << (_aexp - min_exponent(ESS))
      fsize = __fsize_of_exact(fraction)
      #return a subnormal fraction that appears the way it should.
      return Unum{ESS,FSS}(fsize, max_esize(ESS), flags, fraction, z64)
    end

    #regenerate the new fraction and fsize
    fraction = lsh(fraction, shift)
    fsize = __fsize_of_exact(fraction)
    #recalculate the exponent.
    _aexp -= shift
  else
    #the lag bit fell over, so declare inexact, if necessary, otherwise pass
    #everything
    (lag_bit == 0) || (flags |= UNUM_UBIT_MASK)
  end

  (esize, exponent) = encode_exp(_aexp)
  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end
