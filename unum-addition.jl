#unum-addition.jl
#Performs addition with unums.  Requires two unums to have the same
#environment signature.  Also included here is subtraction.

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
function +(a::Unum, b::Unum)
  #some basic gating checks before we do any crazy operations.
  #one, is either one zero?
  iszero(a) && return b
  iszero(b) && return a
  #do a nan check
  (isnan(a) || isnan(b)) && return nan(typeof(a))

  #infinities plus anything is NaN if opposite infinity. (checking for operand a)
  if (ispinf(a))
    (isninf(b)) && return nan(typeof(a))
    return pinf(typeof(a))
  elseif (isninf(a))
    (ispinf(b)) && return nan(typeof(a))
    return ninf(typeof(a))
  end

  #infinities b (infinity a is ruled out) plus anything is b3
  (ispinf(b)) && return pinf(typeof(a))
  (isninf(b)) && return ninf(typeof(a))

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

#performs a carried add on an unsigned integer array.
function __carried_add(carry::Uint64, v1::SuperInt, v2::SuperInt)
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

#returns a (SuperInt, int, bool) triplet:  (value, shift, falloff)
function __shift_after_add(carry::Uint64, value::SuperInt)
  #check if we have to do nothing.
  (carry == 0) && return (value, 0, false)
  #cache the length of value
  l = length(value)
  #calculate how far we have to shift.
  shift = msb(carry)
  #did we lose values off the end of the number?
  falloff = (value & fillbits(shift, l)) != superzero(l)
  #shift the value over
  value = rsh(value, shift)
  #copy the carry over.
  if (l > 1)
    value[l] |= carry << (64 - shift)
  else
    value |= carry << (64-shift)
  end
  (value, shift, falloff)
end

################################################################################
## GATEWAY OPERATION

#an addition operation where a and b are ordered such that mag(a) > mag(b)
function __add_ordered{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, _aexp, _bexp)
  a_neg = isnegative(a)
  b_neg = isnegative(b)

  if (b_neg != a_neg)
    __diff_ordered(a, b, _aexp, _bexp)
  else
    __sum_ordered(a, b, _aexp, _bexp)
  end
end

################################################################################
## SUM ALGORITHM

function __sum_ordered(a, b, _aexp, _bexp)
  #add two values, where a has a greater magnitude than b.  Both operands have
  #matching signs, either positive or negative.  At this stage, they may both
  #be ULPs.
  if (isulp(a) || isulp(b))
    __sum_ulp(a, b, _aexp, _bexp)
  else
    __sum_exact(a, b, _aexp, _bexp)
  end
end

function __sum_ulp(a, b, _aexp, _bexp)
  #this code is assuredly wrong.
  isalmostinf(a) && return a

  exact_a = Unum{ESS,FSS}(a.fsize, a.esize, a.flags & (~UBIT_MASK), a.fraction, a.exponent)
  exact_b = Unum{ESS,FSS}(b.fsize, b.esize, b.flags & (~UBIT_MASK), b.fraction, b.exponent)

  #find the min and max additions to be performed.
  max_a = (a_ulp) ? nextunum(a) : exact_a
  max_b = (b_ulp) ? nextunum(b) : exact_b

  #we may have to re-decode these because these might have changed.
  _maexp = decode_exp(a)
  _mbexp = decode_exp(b)

  #find the high and low bounds.  Pass this to a subsidiary function (recursion!)
  far_result = max_a + max_b
  near_result = exact_a + exact_b

  if a_neg
    ubound_resolve(open_ubound(far_result, near_result))
  else
    ubound_resolve(open_ubound(near_result, far_result))
  end
end

function __sum_exact{ESS, FSS}(a::Unum{ESS,FSS}, b::Unum{ESS, FSS}, _aexp, _bexp)
  #calculate the exact sum between two unums.  You may pass this function a unum
  #with a ubit, but it will calculate the sum as if it didn't have the ubit there

  #check for deviations due to subnormality.
  a_dev = issubnormal(a) ? 1 : 0
  b_dev = issubnormal(b) ? 1 : 0

  #calculate the bit offset.
  bit_offset = (_aexp + a_dev) - (_bexp + b_dev)

  #check to see if the offset is too big, just copy A with the unum bit flipped on, but also
  #make sure that the fraction is thrown all the way to the right.
  (bit_offset > max_fsize(FSS) + 1 - b_dev) && return Unum{ESS,FSS}(max_fsize(FSS), a.esize, a.flags | UNUM_UBIT_MASK, a.fraction, a.exponent)

  #generate the scratchpad by moving b.
  scratchpad = b.fraction >> bit_offset

  #don't forget b's phantom bit (1-b_dev) so it's zero if we are subnormal
  scratchpad |= (bit_offset == 0) ? 0 : (1 - b_dev) << (64 - bit_offset)

  #perform a carried add.  Start it off with a's phantom bit (1- a_dev), and
  #b's phantom bit if they are overlapping.
  carry::Uint64 = (1 - a_dev) + ((bit_offset == 0) ? (1 - b_dev) : 0)

  (carry, scratchpad) = __carried_add(carry, a.fraction, scratchpad)
  flags = a.flags & UNUM_SIGN_MASK

  #handle the carry bit (which may be up to three? or more).
  if (carry == 0)
    fsize = (scratchpad == 0) ? z16 : uint16(63 - lsb(scratchpad))
    exponent = a.exponent
    esize = a.esize
  elseif (carry == 1)
    #esize is unchanged.  May have to alter fsize.
    fsize = (scratchpad == 0) ? z16 : uint16(63 - lsb(scratchpad))
    exponent = a.exponent + a_dev #promote it if we happened to have been subnormal.
    #trim based on the total amount of bits that are okay.

    esize = a.esize
  else
    (scratchpad, shift, checkme) = __shift_after_add(carry, scratchpad)

    flags 

    #check for overflows.
    (a.exponent + shift) >= 2^ESS && return almostinf(a)

    fsize = uint16(scratchpad == 0 ? 0 : 63 - lsb(scratchpad))
    (esize, exponent) = encode_exp(_aexp + shift)
  end

  #check for the quieter way of getting an overflow.
  if (fsize == 2^FSS - 1) && (esize == 2^ESS - 1) && (scratchpad == fillbits(-(2 ^ FSS))) && (exponent == (2^ESS))
    return almostinf(a)
  end

  Unum{ESS,FSS}(fsize, esize, flags, scratchpad, exponent)
end

################################################################################
## DIFFERENCE ALGORITHM

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
