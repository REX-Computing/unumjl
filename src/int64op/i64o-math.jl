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

#=

@gen_code function __prev_val!{FSS}(a::ArrayNum{FSS})
  l = __cell_length(FSS)
  @code quote
    borrow::Bool = true
  end
  for (idx = l:-1:1)
    @code quote
      a.a[$l] -= borrow * o64
      borrow &= (a.a[$l] == f64)
    end
  end
  @code :(a)
end

doc"""
`__chunk_mult_small(::UInt64, ::UInt64)` performs a left-aligned multiplication
on two 64-bit integers, discarding the rightmost 32 bits of the starting value.
this is useful for multiplication of unums with FSS < 6.  The result will be
left-shifted, and all bits will be passed on and *not* masked out - the remaining
bits at the bottom of the number should be used to analyze for whether or not
the result is an ulp.
"""
function __chunk_mult_small(a::UInt64, b::UInt64)
  (a >> 32) * (b >> 32)
end

doc"""
`__chunk_mult(::UInt64, ::UInt64)` performs a left-aligned multiplication on two
64-bit integers by breaking them down into 32-bit integers and doing standard
'two-digit' multiplication on these.  The right-most digits of the result are
discarded.  The ordered pair (result, trash) is returned, where trash contains
trailing digits that might be useful for a fused-multiply-add.
"""
#                AH       AL
#             *  BH       BL
#             ---------------
#                     (AL BL)
#                  (AH BL)
#                  (AL BH)
#               (AH BH)
#             ---------------
#               RESULT TRASH
#
function __chunk_mult(a::UInt64, b::UInt64)
  ah = a >> 32
  bh = b >> 32
  al = a & 0x0000_0000_FFFF_FFFF
  bl = b & 0x0000_0000_FFFF_FFFF

  #this formula recapitulates the diagram shown above
  result = ((al * bl >> 32) + (ah * bl) + (al * bh)) >> 32 + (ah * bh)
  trash = (al * bl) + ((ah * bl) << 32) + ((al * bh) << 32)

  (result, trash)
end

# chunk_mult handles simply the chunked multiply of two superints
@gen_code function __chunk_mult!{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS}, c::ArrayNum{FSS})
end

=#
