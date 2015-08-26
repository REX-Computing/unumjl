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
  v1_adj = [zeros(Uint64, length(v2) - length(v1)), v1]
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
  if (isulp(a) || isulp(b))
    __diff_ulp(a, b, _aexp, _bexp)
  else
    __diff_exact(a, b, _aexp, _bexp)
  end
end

function __diff_ulp(a, b, _aexp, _bexp)
  if (a_ulp)
    max_a = nextunum(a)
    exact_a = unum(a, a.flags & (~UBIT_MASK))
    _maexp = decode_exp(max_a)
  else
    max_a = exact_a = unum(a)
    _maexp = _aexp
  end
  if (b_ulp)
    max_b = nextunum(b)
    exact_b = unum(b, b.flags & (~UBIT_MASK))
    _mbexp = decode_exp(max_b)
  else
    max_b = exact_b = unum(b)
    _mbexp = _bexp
  end

  #do a check to see if a is almost infinite.
  if (isalmostinf(a))
    #a ubound ending in infinity can't result in an ulp unless the lower subtracted
    #value is zero, which is already tested for.
    isalmostinf(b) && return open_ubound(almostninf(Unum{ESS,FSS}), almostpinf(Unum{ESS,FSS}))

    if (a_neg)
      #exploit the fact that __exact_subtraction ignores ubits
      return open_ubound(a, __do_subtraction(a, max_b, _aexp, _mbexp))
    else
      return open_ubound(__do_subtraction(a, max_b, _aexp, _mbexp), a)
    end
  end

  far_res = __do_subtraction(max_a, exact_b, _maexp, _bexp)

  #it's possible that exact_a is less than max_b
  if ((exact_a.exponent > max_b.exponent) || ((exact_a.exponent == max_b.exponent) && (exact_a.fraction > max_b.fraction)))
    near_res = __do_subtraction(exact_a, max_b, _aexp, _mbexp)
  else
    near_res = __do_subtraction(max_b, exact_a, _mbexp, _aexp)
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
  #need to keep exceeds the cell size.  NB: this only occurs when the major value
  #is subnormal.  Still, we need to allocate for this possibility.
  scratchpad_cells = (a_dev != 0) ? (max_fsize + 1 + bit_offset) >> 6 + 1 : length(a.fraction)

  #check to make sure we're not falling off the end here, but in this case return
  #the previous exact as an ulp; make sure fraction is thrown all the way to the
  #right.
  #(bit_offset > max_fsize(FSS) + 1 - b_dev) &&
  #return Unum{ESS,FSS}(max_fsize(FSS), a.esize, a.flags | UNUM_UBIT_MASK, a.fraction, a.exponent)

  #populate the scratchpad with the rightshifted b values.  Make sure to pad b.
  #fraction to the "full necessary length", before shifting over.
  scratchpad = rsh([zeros(Uint64, scratchpad_cells - b.fraction.length), b.fraction])
  #figure out the carry value.  It should be zero if a subnormal or if a and b's
  #phantom bits will obliterate each other.
  carry = (a_dev != 0) || ((_bexp == _aexp) && (b_dev == 0)) ? 0 : 1

  #push the phantom bit from b.  Use the __bit_from_top method.
  (bit_offset != 0) && (b_dev != 1) && (scratchpad |= __bit_from_top(bit_offset, l))

  #perform the carried difference on the two fractions.
  (carry, scratchpad) = __carried_diff(carry, a.fraction, scratchpad)

  #calculate the appropriate fraction size.
  fsize = max_fsize(FSS) - ctz(scratchpad)

  #if carry is still a one, then we are ok and can use the values as they are...
  #alternatively, if we started as subnormal then leave things be.
  ((carry == 1) || (a_dev != 0)) && return Unum{ESS,FSS}(a.fsize, a.esize, a.flags, scratchpad, a.exponent)

  #if it's a zero, we may have to shift the whole thing over.
  shift = clz(scratchpad)

  flags = a.flags & SIGN_MASK
  #establish whether or not we will have to move things around a bit.
  #calculate how many fractions we have left.
  fsize = ((scratchpad == 0) ? z16 : uint16(rmsb - rlsb))

  #check to see if we are below the size of the exponent, if so
  #put a hard break on the unit's ability to push past the subnormal numbers
  if (a.exponent <= shift)
    #make sure our shift doesn't go past a.exponent, then set the parameters to
    #be subnormal.
    shift = a.exponent - 1
    #match it, but remember the subnormals have an incremented exponent.
    esize = z16
    exponent = z64
  else
    #check to see if we're verging on denormal
    if (_aexp - shift < 2^ESS)
      esize = z16
      exponent = z64
    else
      (esize, exponent) = encode_exp(_aexp - shift)
    end
  end
  fraction = scratchpad << shift
  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end
