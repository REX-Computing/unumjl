#unum-addition.jl
#Performs addition with unums.  Requires two unums to have the same
#environment signature.  Also included here is subtraction.

#instead of making unary plus "do nothing at all", we will have it "firewall"
#the variable by creating a 'safe copy' of it.
+(x::Unum) = unum(x)
#unary minus uses the shorthand pseudoconstructor, where all the values are the
#same but the flags may be altered.
-(x::Unum) = unum(x, x.flags $ UNUM_SIGN_MASK)

#binary add - let's do things this way.
function +(a::Unum, b::Unum)
  #some basic gating checks before we do any crazy operations.
  #one, is either one zero?
  if (iszero(a))
    return b
  end
  if (iszero(b))
    return a
  end
  #do a nan check
  if (isnan(a) || isnan(b))
    return nan(typeof(a))
  end
  #do infinite checks
  if (ispinf(a))
    if (isninf(b))
      return nan(typeof(a))
    else
      return pinf(typeof(a))
    end
  elseif (isninf(a))
    if (ispinf(b))
      return nan(typeof(a))
    else
      return ninf(typeof(a))
    end
  end
  if (ispinf(b))
    return pinf(typeof(a))
  elseif (isninf(b))
    return ninf(typeof(a))
  end

  __add_ordered(magsort(a,b)...)
end

#subtraction - merely flip the bit first and then roll with it.
function -(a::Unum, b::Unum)
  #check equality and return zero if equal.
  a + -b
end

#a function that calculates the maximum scratchpad size...
#this is the maximum exponential difference plus the maximal floating point
#difference.

#performs a carried add on an unsigned integer array.
function __carried_add(carry, v1, v2)
  res = v1 .+ v2
  #check to see if we need a carry.
  if last(res) < last(v1)
    carry += 1
  end
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

#returns a (SuperInt, int, bool) triplet:  (value, shift, falloff)
function __shift_after_add(carry, value)
  shift = msb(carry)
  falloff = (value & mask(shift) != 0)
  value = value >> shift
  value |= carry << (64 - shift)
  (value, shift, falloff)
end

#an addition operation where a and b are ordered such that mag(a) > mag(b)
function __add_ordered{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp, _bexp)
  a_ulp = a.flags & UBIT_MASK != 0
  b_ulp = b.flags & UBIT_MASK != 0
  a_neg = isnegative(a)
  b_neg = isnegative(b)

  if (b_neg != a_neg)
    __sub_ordered(a, b, _aexp, _bexp)
  elseif (a_ulp || b_ulp)

    #do a check to see if either one of our guys is almostinfinite.
    #note that we don't need to countercheck if the other is infinite,
    #because that check is done earlier.

    isalmostinf(a) && return a

    exact_a = Unum{ESS,FSS}(a.fsize, a.esize, a.flags & (~UBIT_MASK), a.fraction, a.exponent)
    exact_b = Unum{ESS,FSS}(b.fsize, b.esize, b.flags & (~UBIT_MASK), b.fraction, b.exponent)

    #find the min and max additions to be performed.
    max_a = (a_ulp) ? nextunum(a) : exact_a
    max_b = (b_ulp) ? nextunum(b) : exact_b

    _maexp = decode_exp(a)
    _mbexp = decode_exp(b)

    #find the high and low bounds.
    far_result = max_a + max_b
    near_result = exact_a + exact_b

    if a_neg
      ubound_resolve(open_ubound(far_result, near_result))
    else
      ubound_resolve(open_ubound(near_result, far_result))
    end
  else
    __do_addition(a, b, _aexp, _bexp)
  end
end

function __do_addition{ESS, FSS}(a::Unum{ESS,FSS}, b::Unum{ESS, FSS}, _aexp, _bexp)

  #check for deviations due to subnormality.
  a_dev = issubnormal(a) ? 1 : 0
  b_dev = issubnormal(b) ? 1 : 0

  #calculate the bit offset.
  bit_offset = (_aexp + a_dev) - (_bexp + b_dev)
  #generate the scratchpad by moving b.
  scratchpad = b.fraction >> bit_offset

  #don't forget b's phantom bit (1-b_dev) so it's zero if we are subnormal
  scratchpad |= (bit_offset == 0) ? 0 : (1 - b_dev) << (64 - bit_offset)

  #perform a carried add.  Start it off with a's phantom bit (1- a_dev), and
  #b's phantom bit if they are overlapping.
  carry = (1 - a_dev) + ((bit_offset == 0) ? (1 - b_dev) : 0)

  (carry, scratchpad) = __carried_add(carry, a.fraction, scratchpad)

  flags = a.flags & SIGN_MASK

  #handle the carry bit (which may be up to three? or more).
  if (carry == 1)
    #esize is unchanged.  May have to alter fsize.
    fsize = (lsb(scratchpad) == 0) ? uint16(0) : uint16(63 - lsb(scratchpad))
    exponent = a.exponent + a_dev #promote it if we happened to have been subnormal.
    #trim based on the total amount of bits that are okay.

    esize = a.esize
  else
    (scratchpad, shift, checkme) = __shift_after_add(carry, scratchpad)

    #check for overflows.
    if (a.exponent + shift) >= 2^ESS
      return almostinf(a)
    end

    fsize = uint16(scratchpad == 0 ? 0 : 63 - lsb(scratchpad))
    (esize, exponent) = encode_exp(_aexp + shift)
  end

  #check for the quieter way of getting an overflow.
  if (fsize == 2^FSS - 1) && (esize == 2^ESS - 1) && (scratchpad == fillbits(-(2 ^ FSS))) && (exponent == (2^ESS))
    return almostinf(a)
  end

  Unum{ESS,FSS}(fsize, esize, flags, scratchpad, exponent)
end

function __sub_ordered{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp, _bexp)
  #an ordered subtraction.  a has a higher magnitude than b.  The final direction
  #of the result will be in the direction of the sign of a.

  a_ulp = a.flags & UBIT_MASK != 0
  b_ulp = b.flags & UBIT_MASK != 0
  a_neg = isnegative(a)
  b_neg = isnegative(b)

  if (a_ulp || b_ulp)

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
  else
    __do_subtraction(a, b, _aexp, _bexp)
  end
end

#a subtraction operation where a and b are ordered such that mag(a) > mag(b)
function __do_subtraction{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp, _bexp)

  if (a == -b)
    return zero(Unum{ESS,FSS})
  end
  if (iszero(b))
    return unum(a)
  end
  if (iszero(a))
    return -b
  end
  #check to see if

  #check for deviations due to subnormality.
  a_dev = issubnormal(a) ? 1 : 0
  b_dev = issubnormal(b) ? 1 : 0

  bit_offset = (_aexp + a_dev) - (_bexp + b_dev)

  scratchpad = b.fraction >> bit_offset

  #push the phantom bit from b (1-b_dev), unless it matches the size of a
  scratchpad |= (bit_offset == 0) ? 0 : (1 - b_dev) << (64 - bit_offset)

  scratchpad = uint64(a.fraction - scratchpad)  #we know it's larger so things will be ok.

  #calculate the lsb and msb of the scratchpad.
  (rlsb, rmsb) = lsbmsb(scratchpad)
  shift = z16

  #if we started out with a_dev being subnormal, we don't care.
  if ((bit_offset == 0) && (b_dev == 0) && (a_dev == 0)) || (scratchpad > a.fraction)
    #then we've obliterated the phantom leading one, through direct subtraction
    #or through a reverse carry operation
    shift = uint16(64-rmsb)
  else
    rmsb = 64
  end

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

#an add_ordered procedure for when you don't just have j.ust a single uint64
function __add_ordered_poly{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
end

#an add_ordered procedure for when you don't just have just a single uint64
function __sub_ordered_poly{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
end
