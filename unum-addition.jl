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

  (is_mmr(a)) && (a.flags & UNUM_SIGN_MASK == b.flags & UNUM_SIGN_MASK) && return mmr(Unum{ESS,FSS}, a.flags & UNUM_SIGN_MASK)
  (is_mmr(b)) && (a.flags & UNUM_SIGN_MASK == b.flags & UNUM_SIGN_MASK) && return mmr(Unum{ESS,FSS}, b.flags & UNUM_SIGN_MASK)

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
function __shift_after_add(carry::Uint64, value::SuperInt, is_ubit::Uint16)
  #cache the length of value
  l::Uint16 = length(value)
  #calculate how far we have to shift.
  shift = 64 - clz(carry) - 1
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
  #calculate the exact sum between two unums.  You may pass this function a unum
  #with a ubit, but it will calculate the sum as if it didn't have the ubit there
  l::Uint16 = length(a.fraction)
  #check for deviations due to subnormality.
  a_dev = is_exp_zero(a) ? 1 : 0
  b_dev = is_exp_zero(b) ? 1 : 0

  #calculate the bit offset.
  bit_offset = (_aexp + a_dev) - (_bexp + b_dev)

  #check to see if the offset is too big, just copy A with the unum bit flipped on, but also
  #make sure that the fraction is thrown all the way to the right.
  (bit_offset > max_fsize(FSS) + 1 - b_dev) && return Unum{ESS,FSS}(max_fsize(FSS), a.esize, a.flags | UNUM_UBIT_MASK, a.fraction, a.exponent)

  #generate the scratchpad by moving b.
  scratchpad = rsh(b.fraction, bit_offset)

  #check to see if there's bits that are falling off.
  is_ubit::Uint16 = allzeros(b.fraction & fillbits(bit_offset, l)) ? 0 : UNUM_UBIT_MASK

  #don't forget b's phantom bit (1-b_dev) so it's zero if we are subnormal
  (bit_offset != 0) && (b_dev != 1) && (scratchpad |= __bit_from_top(bit_offset, l))

  #perform a carried add.  Start it off with a's phantom bit (1- a_dev), and
  #b's phantom bit if they are overlapping.
  carry::Uint64 = (1 - a_dev) + ((bit_offset == 0) ? (1 - b_dev) : 0)

  (carry, scratchpad) = __carried_add(carry, a.fraction, scratchpad)
  flags = a.flags & UNUM_SIGN_MASK
  fsize::Uint16 = 0

  #how much the exponent must be shifted.
  shift::Uint16 = (a_dev == 0) ? 0 : carry

  if (carry > 1)
    (scratchpad, shift, is_ubit) = __shift_after_add(carry, scratchpad, is_ubit)
  end

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

  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end
