#int64o-math.jl
doc"""
  `Unums.i64add!(carry, a::ArrayNum, b::ArrayNum)`
  adds the array b into the array a, and increments the carry value if there's
  been a carry event.
"""
@gen_code function i64add!{FSS}(carry::UInt64, b::ArrayNum{FSS}, a::ArrayNum{FSS})
  #this algorithm follows exactly from the elementary school addition algorithm.
  #keep a "carry" variable around and go from least significant to most significant
  #bits.
  l = __cell_length(FSS)
  #initialize the carry variable.
  @code quote
    carryevent::Bool = false  #tracks if a carry event occurred in the last cells
    overflow::Bool = false    #tracks if the addition of the two cells causes overflow.
  end

  for (idx = l:-1:1)
    @code quote
      @inbounds begin
        (b.a[$idx] += a.a[$idx])     #perform the addition
        overflow = b.a[$idx] < a.a[$idx]
        b.a[$idx] += carryevent * o64
        carryevent = overflow | ((carryevent) & (b.a[$idx] == z64))
      end
    end
  end
  #add in the carry from the most significant segment to the entire carry.
  @code :(carry + carryevent * o64)
end
doc"""
  `Unums.i64add(carry, a::ArrayNum, b::ArrayNum)`
  adds the array b into the array a, and increments the carry value if there's
  been a carry event.
"""
function i64add(carry::UInt64, a::UInt64, b::UInt64)
  result::UInt64 = a + b
  augment::UInt64 = (result < a) * o64
  (carry + augment, result)
end

doc"""
  Unums.add_ubit(value, bit) adds the (zero-indexed) bit to the value.  Returns
  (result, carried)
"""
function add_ubit(value::UInt64, bit::UInt16)
  result_value = value + (t64 >> bit)
  (result_value, result_value < value)
end
@gen_code function add_ubit!{FSS}(value::ArrayNum{FSS}, bit::UInt16)
  @code quote
    cell_index = div(bit, 0x0040) + o16
    added_cell = t64 >> (bit % 0x0040)
    carried = false
  end

  for (idx = __cell_length(FSS):-1:1)
    @code quote
      @inbounds begin
        oldvalue = value.a[$idx]
        value.a[$idx] += ($idx == cell_index) * added_cell + carried * o64
        carried = (value.a[$idx] < oldvalue)
      end
    end
  end
  @code :(carried)
end

@universal function frac_add_ubit!(u::Unum, bit::UInt16)
  if (FSS < 7)
    (u.fraction, carried) = add_ubit(u.fraction, bit)
  else
    carried = add_ubit!(u.fraction, bit)
  end
  return carried
end


function sub_ubit(value::UInt64, bit::UInt16)
  result_value = value - (t64 >> bit)
  (result_value, result_value > value)
end
@gen_code function sub_ubit!{FSS}(value::ArrayNum{FSS}, bit::UInt16)
  @code quote
    cell_index = div(bit, 0x0040) + o16
    subbed_cell = t64 >> (bit % 0x0040)
    borrowed = false
  end

  for (idx = __cell_length(FSS):-1:1)
    @code quote
      @inbounds begin
        oldvalue = value.a[$idx]
        value.a[$idx] -= ($idx == cell_index) * subbed_cell + borrowed * o64
        borrowed = (value.a[$idx] > oldvalue)
      end
    end
  end
  @code :(borrowed)
end
@universal function frac_sub_ubit!(u::Unum, bit::UInt16)
  if (FSS < 7)
    (u.fraction, borrowed) = sub_ubit(u.fraction, bit)
  else
    borrowed = sub_ubit!(u.fraction, bit)
  end
  return borrowed
end

doc"""
  `Unums.i64sub(carry, a, b)` performs the calculation that is the result of
  b - a (the reverse order is very important!)
"""
function i64sub(carry::UInt64, a::UInt64, b::UInt64)
  #first do a direct substitution.
  result = b - a
  #then check to see if we lost a bit.
  (carry - ((result > b) * o64), result)
end

doc"""
  `Unums.i64sub!(carry, subtrahend, minuend)` performs the calculation that is
  the result of minuend - subtrahend (the reverse passing order is very important!).
  The reason why the order is reversed is because the minend is likely
  to have to been bitshifted prior to subtraction and it's more sensible to do
  that the value that's going to be copied.
"""
@gen_code function i64sub!{FSS}(carry::UInt64, a::ArrayNum{FSS}, b::ArrayNum{FSS})
  @code quote
    borrowed::Bool = false
    underflowed::Bool = false
  end

  for (idx = __cell_length(FSS):-1:1)
    @code quote
      @inbounds begin
        #first do the subtraction of the two values.
        a.a[$idx] = b.a[$idx] - a.a[$idx]
        underflowed = a.a[$idx] > b.a[$idx]
        a.a[$idx] -= borrowed * o64
        borrowed = underflowed | ((a.a[$idx] == f64) & borrowed)
      end
    end
  end

  @code :(return carry - borrowed * o64)
end

doc"""
  `Unums.i64mul(a::UInt64, b::UInt64)` returns the 64-bit value that
  is the top 32 bits of both numbers.
"""
function i64mul(a::UInt64, b::UInt64)
  UInt64(UInt128(a) * UInt128(b) >> 64)
end

@generated function i64mul{FSS}(a::UInt64, b::UInt64, ::Type{Val{FSS}})
  if FSS < 6
    tmask = mask_top(FSS)
    bmask = mask_bot(FSS)
    quote
      carry = z64
      old_res = i64mul(a, b)
      new_res = old_res + a
      carry += (new_res < old_res) * o64
      old_res = new_res
      new_res = old_res + b
      carry += (new_res < old_res) * o64
      return (carry, (new_res & $tmask), (new_res & $bmask != 0) * UNUM_UBIT_MASK)
    end
  else
    quote
      carry = z64
      res = i64mul_extended(a, b)
      old_res = top_part(res)
      ubit = (bottom_part(res) != z64) * UNUM_UBIT_MASK
      new_res = old_res + a
      carry += (new_res < old_res) * o64
      old_res = new_res
      new_res = old_res + b
      carry += (new_res < old_res) * o64
      return (carry, new_res, ubit)
    end
  end
end

doc"""
  `Unums.i64mul_extended(a::UInt64, b::UInt64)` returns the 128-bit value
  that is the product of both 64-bit numbers.  This is useful for the FSS = 6 case,
  as well as for breaking apart vaules in the higher FSS case.
"""
function i64mul_extended(a::UInt64, b::UInt64)
  UInt128(a) * UInt128(b)
end

#these two functions get inlined by handling a quad load as the individual register.
top_part(n::UInt128) = UInt64((n & 0xFFFF_FFFF_FFFF_FFFF_0000_0000_0000_0000) >> 64)
bottom_part(n::UInt128) = UInt64(n & 0x0000_0000_0000_0000_FFFF_FFFF_FFFF_FFFF)

#=
how extended multiplication works.

1) chunk into 64-bit words (already done)
2) multiply as 128-bit numbers
3) stack 128-bit numbers

EG.  2-word x 2-word multiply

A1 A2
B1 B2
      [A2 B2] * CALCULATE TOP (IDX == 4 == N + 2)
   [A1 B2] * CALCULATE FULL, USE TOP (IDX == 5 == N + 1)
   [A2 B1] * CALCULATE FULL, USE TOP
[A1 B1]
[R1 R2]

4-word x 4-word multiply

[A1 A2 A3 A4]
[B1 B2 B3 B4]

                  [A4 B4]
               [A3 B4]
               [A4 B3]
            [A2 B4] * CALCULATE TOP (IDX == 6 == N+2)
            [A3 B3] * CALCULATE TOP
            [A4 B2] * CALCULATE TOP
         [A1 B4] * CALCULATE FULL, USE TOP (IDX == 5 == N + 2)
         [A2 B3] * CALCULATE FULL, USE TOP
         [A3 B2] * CALCULATE FULL, USE TOP
         [A4 B1] * CALCULATE FULL, USE TOP
      [A1 B3]
      [A2 B2]
      [A3 B1]
         [B4] * ADD ADDITIVE PART
         [A4] * ADD ADDITIVE PART
   [A1 B2]
   [A2 B1]
      [B3] * ADD ADDITIVE PART
      [A3] * ADD ADDITIVE PART
[A1 B1]
   [B2] * ADD ADDITIVE PART
   [A2] * ADD ADDITIVE PART
[B1] * ADD ADDITIVE PART
[A1] * ADD ADDITIVE PART
[R1 R2 R3 R4]
=#

doc"""
 `Unums.i64mul!(::ArrayNum, ::ArrayNum)` multiplies two arraynums of equal FSS.
 The result will be the most significant digits of the resulting multiplication.
 Algorithm used is the most basic triangular multiplication, omitting as many
 64-bit integer multiplications as is reasonable to achieve the result (~half)

 This function unrolls itself by being a generated function.
"""
@gen_code function i64mul!{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  l = __cell_length(FSS)
  #set up some internal function variables.
  @code quote
    prev_sum::UInt128 = zero(UInt128)
    accum_sum::UInt128 = zero(UInt128)
    carry::UInt64 = zero(UInt64)
  end

  #PHASE 1.  CALCULATE top only...  Note the A indices always start at 2
  idx_sum = l + 2
  for idx = 2:l
    jdx = idx_sum - idx #calculate the index for the b arraynum.
    @code :(@inbounds accum_sum += i64mul(a.a[$idx], b.a[$jdx]))
  end

  #PHASE 2.  CALCULATE FULL, USE TOP
  idx_sum = l + 1
  for idx = 1:l
    jdx = idx_sum - idx
    @code quote
      prev_sum = accum_sum  #cache the previous value
      @inbounds accum_sum += i64mul_extended(a.a[$idx], b.a[$jdx])
      carry += (prev_sum < accum_sum) * o64
    end
  end

  #PHASE 3.  CALCULATE FULL, USE ALL.
  for idx_sum = l:-1:2
    #at the beginning of this group, we need to shift everything over 64 bits,
    #then add in the carry value, then clear it.
    @code quote
      accum_sum >>= 64
      accum_sum += (UInt128(carry) << 64)
      carry = z64
    end
    for idx = 1:(idx_sum - 1)
      jdx = idx_sum - idx
      @code quote
        prev_sum = accum_sum  #cache the previous value
        @inbounds accum_sum += i64mul_extended(a.a[$idx], b.a[$jdx])
        carry += (prev_sum < accum_sum) * o64
      end
    end
    #PHASE 3.5 ADDITIVE PARTS
    @code quote
      prev_sum = accum_sum
      @inbounds accum_sum += a.a[$idx_sum]
      carry += (prev_sum < accum_sum) * o64
      prev_sum = accum_sum
      @inbounds accum_sum += b.a[$idx_sum]
      carry += (prev_sum < accum_sum) * o64
    end
    #at the end of each loop, be sure to copy over the lower 64 bits to our
    #destination array.  Magically, we won't need A[idx_sum] anymore, so this is a
    #good place to stash the result.
    @code :(@inbounds a.a[$idx_sum] = bottom_part(accum_sum))
  end

  #PHASE 4.  Transfer the last part of the accumulated sum to the first index in
  #in the arraynum.
  @code quote
    carry = o64
    old_top = new_top = top_part(accum_sum)
    @inbounds new_top += a.a[1]
    carry += (old_top < new_top) * o64
    old_top = new_top
    @inbounds new_top += b.a[1]
    carry += (old_top < new_top) * o64
    @inbounds a.a[1] = new_top
    return (carry, inbounds, UNUM_UBIT_MASK)
  end
end
