#unit-subtraction.jl
#implements addition primitives where the vectors of the two values point in
#opposing directions.  This is organized into a separate file for convenience
#purposes (these primitives can be very large.)

###############################################################################
## multistage carried difference engine for uint64s.

function __carried_diff(carry::Uint64, v1::SuperInt, v2::SuperInt)
  #run a difference engine across an array of 64-bit integers
  #"carry" will usually be one, but there are other possibilities (e.g. zero)

  #be sure to pad v1 to the same length as v2, first.
  v1_adj = (length(v1) == 1) ? v1 : [zeros(Uint64, length(v2) - length(v1)), v1]
  #first perform a direct difference on the integer arrays.
  res = v1_adj - v2
  #iterate downward from the most significant cell.  Sneakily, this loop
  #does not execute if we have a singleton SuperInt
  for idx = 1:length(v1_adj) - 1
    #if it looks like it's higher than it should be....
    if res[idx] > v1_adj[idx]
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
  a_ulp = is_ulp(a)
  b_ulp = is_ulp(b)
  a_neg = is_negative(a)
  if (a_ulp)
    max_a = nextunum(a)
    exact_a = unum(a, a.flags & (~UNUM_UBIT_MASK))
    _maexp = decode_exp(max_a)
  else
    max_a = exact_a = unum(a)
    _maexp = _aexp
  end
  if (b_ulp)
    max_b = nextunum(b)
    exact_b = unum(b, b.flags & (~UNUM_UBIT_MASK))
    _mbexp = decode_exp(max_b)
  else
    max_b = exact_b = unum(b)
    _mbexp = _bexp
  end

  #do a check to see if a is almost infinite.
  if (is_mmr(a))
    #a ubound endinc in infinity can't result in an ulp unless the lower subtracted
    #value is zero, which is already tested for.
    is_mmr(b) && return open_ubound(neg_mmr(Unum{ESS,FSS}), pos_mmr(Unum{ESS,FSS}))

    if (a_neg)
      #exploit the fact that __exact_subtraction ignores ubits
      return open_ubound(a, __diff_exact(a, max_b, _aexp, _mbexp))
    else
      return open_ubound(__diff_exact(a, max_b, _aexp, _mbexp), a)
    end
  end

  far_res = __diff_exact(max_a, exact_b, _maexp, _bexp)

  #it's possible that exact_a is less than max_b
  if ((exact_a.exponent > max_b.exponent) || ((exact_a.exponent == max_b.exponent) && (exact_a.fraction > max_b.fraction)))
    near_res = __diff_exact(exact_a, max_b, _aexp, _mbexp)
  else
    near_res = __diff_exact(max_b, exact_a, _mbexp, _aexp)
    near_res.flags &= SIGN_MASK
    near_res.flags |= SIGN_MASK $ far_res.flags
    #now we have to do something here.
  end

  if a_neg
    ubound_resolve(open_ubound(far_res, near_res))
  else
    ubound_resolve(open_ubound(near_res, far_res))
  end
end

#a subtraction operation where a and b are ordered such that mag(a) > mag(b)
function __diff_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp, _bexp)
  l = length(a.fraction)

  # a series of easy cases.
  if (a == -b)
    return zero(Unum{ESS,FSS})
  end
  if (iszero(b))
    return unum(a)
  end
  if (iszero(a))
    return -b
  end

  #check for deviations due to subnormality.
  a_dev = issubnormal(a) ? o16 : z16
  b_dev = issubnormal(b) ? o16 : z16

  bit_offset = uint16((_aexp + a_dev) - (_bexp + b_dev))

  #subtraction is difficult.  There is a small possibility we'll have a subnormal
  #number with leading zeros, and a subtrahend where the number of digits we'll
  #need to keep exceeds the cell size.  There may be a more elegant solution to
  #be found later.
  scratchpad_cells = max(((l << 6) - ctz(b.fraction) + bit_offset) >> 6 + 1, l)

  #populate the scratchpad with the rightshifted b values.  Make sure to pad b.
  #fraction to the "full necessary length", before shifting over.
  scratchpad = [zeros(Uint64, scratchpad_cells - l), b.fraction]
  scratchpad = rsh(scratchpad, bit_offset)
  #figure out the carry value.  It should be zero if a subnormal or if a and b's
  #phantom bits will obliterate each other.
  carry::Uint64 = (a_dev != 0) || ((_bexp == _aexp) && (b_dev == 0)) ? 0 : 1

  #push the phantom bit from b.  Use the __bit_from_top method.
  (bit_offset != 0) && (b_dev != 1) && (scratchpad |= __bit_from_top(bit_offset, scratchpad_cells))

  #perform the carried difference on the two fractions.
  (carry, scratchpad) = __carried_diff(carry, a.fraction, scratchpad)

  flags = a.flags & UNUM_SIGN_MASK
  fsize::Uint16 = 0
  exponent::Uint64 = 0

  #two forks:  The first fork is if the carry bit persists.
  if (carry != 0)
    if (scratchpad_cells > 1)
      #analyze to see if there's content in the last bits.
      (scratchpad[1:scratchpad_cells - l] != zeros(Uint64, scratchpad_cells - l)) && (flags |= UNUM_UBIT_MASK)
      #first chop off only the last
      fraction = ((l == 1) ? last(scratchpad) : scratchpad[scratchpad_cells - l + 1:scratchpad_cells])
    else
      fraction = scratchpad
    end
    fsize = (flags & UNUM_UBIT_MASK != 0) ? max_fsize(FSS) : max(0, (l << 6 - ctz(fraction) - 1))
    esize = a.esize
    exponent = a.exponent
  else
    ##TODO:  Rethink this segment.  Is it not the case that the worst the shift can be is ONE?



    #we want to see if we can push it over as far as possible without hitting
    #the fraction size limit
    max_shift = _aexp - min_exponent(ESS)
    shift::Int16 = min(max_shift, clz(scratchpad) + 1)
    scratchpad = lsh(scratchpad, shift)

    #chop off the last parts of the scratchpad.
    if (scratchpad_cells > 1)
      (scratchpad[1:scratchpad_cells - l] != zeros(Uint64, scratchpad_cells - l)) && (flags |= UNUM_UBIT_MASK)
      fraction = (l == 1) ? last(scratchpad) : scratchpad[scratchpad_cells - l + 1:scratchpad_cells]
    else
      fraction = scratchpad
    end

    fsize = (flags & UNUM_UBIT_MASK != 0) ? max_fsize(FSS): max(0, (l << 6 - ctz(fraction) - 1))

    (esize, exponent) = encode_exp(_aexp - shift)
    (max_shift == shift) && (exponent = z16)
  end

  __frac_cells(FSS) == 1 && (fraction = last(fraction))
  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end
