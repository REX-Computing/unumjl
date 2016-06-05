#i64o-shifts.jl

#bitshifting operations on superints
#iterative leftshift and rightshift operations on Array SuperInts

lsh(a::UInt64, b::Int64) = a << b
lsh(a::UInt64, b::UInt16) = a << b
lsh!{FSS}(a::ArrayNum{FSS}, b::UInt16) = lsh!(a, Int64(b))
function lsh!{FSS}(a::ArrayNum{FSS}, b::Int64)
  (b < 0) && return rsh!(a, -b)
  lsh!(a, to16(b))
end
#destructive version which clobbers the existing verion
function lsh!{FSS}(a::ArrayNum{FSS}, b::UInt16)
  #kick it back to right shift if it's negative
  l = __cell_length(FSS)
  #calculate how many cells apart our two ints shall be.
  celldiff::UInt16 = b >> 6
  #calculate how much we have to shift
  shift::UInt16 = b & 0x003F
  shift == 0 && @goto cellmove          #skip it, if it's more efficient.
  c_shift::UInt16 = 0x0040 - shift

  #go ahead and shift all blocks.
  for idx = 1:l-1
    @inbounds a.a[idx] = (a.a[idx] << shift) | a.a[idx + 1] >> c_shift
  end
  #finish the last block.
  @inbounds a.a[l] = a.a[l] << shift
  #cut in here if we skipped the cell movement.

  @label cellmove
  #move the cells
  (celldiff == 0) && return
  splitdex::Int64 = l - celldiff
  for idx = 1:l
    @inbounds a.a[idx] = (idx <= splitdex) ? a.a[idx + celldiff] : 0
  end
  return a
end

@fracproc lsh shft

rsh(a::UInt64, b::Int64) = a >> b
rsh(a::UInt64, b::UInt16) = a >> b
rsh!(a::UInt64, b::UInt16) = rsh!(a, Int64(b))

function rsh!{FSS}(a::ArrayNum{FSS}, b::Int64)
  (b < 0) && return lsh!(a, -b)
  rsh!(a, to16(b))
end
function rsh!{FSS}(a::ArrayNum{FSS}, b::UInt16)
  #kick it back to right shift if it's negative

  l = __cell_length(FSS)
  #calculate how many cells apart our two ints shall be.
  celldiff::UInt16 = b >> 6
  #calculate how much we have to shift
  shift::UInt16 = b & 0x003F
  shift == 0 && @goto cellmove          #skip it, if it's more efficient.
  c_shift::UInt16 = 0x0040 - shift
  
  #go ahead and shift all blocks.
  for idx = l:-1:2
    @inbounds a.a[idx] = (a.a[idx] >> shift) | a.a[idx - 1] << c_shift
  end

  #finish the last block.
  @inbounds a.a[1] = a.a[1] >> shift
  #cut in here if we skipped the cell movement.
  @label cellmove
  #move the cells
  (celldiff == 0) && return
  splitdex::Int64 = celldiff

  for idx = l:-1:1
    @inbounds a.a[idx] = (idx > splitdex) ? a.a[idx - celldiff] : 0
  end
  a
end

@fracproc rsh shft
#=
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
=#
