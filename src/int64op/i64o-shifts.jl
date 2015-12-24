#i64o-shifts.jl

#bitshifting operations on superints
#iterative leftshift and rightshift operations on Array SuperInts

lsh(a::UInt64, b::Int64) = a << b
lsh(a::UInt64, b::UInt16) = a << b
lsh!{FSS}(a::ArrayNum{FSS}, b::UInt16) = lsh!(a, Int64(b))
#destructive version which clobbers the existing verion
@gen_code function lsh!{FSS}(a::ArrayNum{FSS}, b::Int64)
  l = __cell_length(FSS)
  @code quote
    #kick it back to right shift if it's negative
    (b < 0) && (rsh!(a, -b); return)

    #calculate how many cells apart our two ints shall be.
    celldiff::Int64 = b >> 6
    #calculate how much we have to shift
    shift::Int64 = b & 0x0000_0000_0000_003F
    shift == 0 && @goto cellmove          #skip it, if it's more efficient.
    c_shift::Int64 = 64 - shift
  end

  #go ahead and shift all blocks.
  for idx = 1:l-1
    @code :(@inbounds a.a[$idx] = (a.a[$idx] << shift) | a.a[$idx + 1] >> c_shift)
  end

  @code quote
    #finish the last block.
    @inbounds a.a[$l] = a.a[$l] << shift
    #cut in here if we skipped the cell movement.
    @label cellmove
    #move the cells
    (celldiff == 0) && return
    splitdex::Int64 = $l - celldiff
  end

  for idx = 1:l
    @code :(@inbounds a.a[$idx] = ($idx <= splitdex) ? a.a[$idx + celldiff] : 0)
  end
end

rsh(a::UInt64, b::Int64) = a >> b
rsh(a::UInt64, b::UInt16) = a >> b
rsh!(a::UInt64, b::UInt16) = rsh!(a, Int64(b))
@gen_code function rsh!{FSS}(a::ArrayNum{FSS}, b::Int64)
  l = __cell_length(FSS)
  @code quote
    #kick it back to right shift if it's negative
    (b < 0) && (rsh!(a, -b); return)

    #calculate how many cells apart our two ints shall be.
    celldiff::Int64 = b >> 6
    #calculate how much we have to shift
    shift::Int64 = b & 0x0000_0000_0000_003F
    shift == 0 && @goto cellmove                #consider this may be skippable.
    c_shift::Int64 = 64 - shift
  end

  #go ahead and shift all blocks.
  for idx = l:-1:2
    @code :(@inbounds a.a[$idx] = (a.a[$idx] >> shift) | a.a[$idx - 1] << c_shift)
  end

  @code quote
    #finish the last block.
    @inbounds a.a[1] = a.a[1] >> shift
    #cut in here if we skipped the cell movement.
    @label cellmove
    #move the cells
    (celldiff == 0) && return
    splitdex::Int64 = celldiff
  end

  for idx = l:-1:1
    @code :(@inbounds a.a[$idx] = ($idx > splitdex) ? a.a[$idx - celldiff] : 0)
  end
end

################################################################################
## a common operation is to rightshift with an underflow check.  Note that this
## doesn't check at the FSS boundaries, and only checks for underflows at the
## ends of integers or integer arrays.

function __rightshift_with_underflow_check(f::UInt64, s::Int64, flags::UInt16)
  #first generate the mask.
  mask::UInt64 = (o64 << s) - o64
  ((f & mask) != z64) && (flags |= UNUM_UBIT_MASK)
  f >>= s
  (f,  flags)
end

function __rightshift_with_underflow_check!{FSS}(f::ArrayNum{FSS}, s::Int64, flags::UInt16)
  #generate the mask holder.
  mask = zero(ArrayNum{FSS})
  #actually generate the mask.
  (s > max_fsize(FSS)) && (s == max_fsize(FSS))
  mask_bot!(mask, UInt16(max_fsize(FSS) - s))  #double check that this is correct.
  #compare the mask with the target.
  fill_mask!(mask, f)
  is_not_zero(mask) && (flags |= UNUM_UBIT_MASK)
  #right shift.
  rsh!(f, s)
  (f, flags)
end
