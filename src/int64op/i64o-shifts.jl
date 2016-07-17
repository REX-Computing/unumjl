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

################################################################################
## rightshift with underflow check.

@generated function rsh_underflow_check{FSS}(num::UInt64, shift::UInt16, ::Type{Val{FSS}})
  mfsize = Unums.max_fsize(FSS)
  quote
    mask = ((shift > $mfsize) * f64) | mask_bot($mfsize - shift)
    ubit_needed = ((num & mask) != z64) * UNUM_UBIT_MASK
    num = rsh(num, shift)
    (num, ubit_needed)
  end
end

@generated function underflow_check{FSS}(num::ArrayNum{FSS}, shift::UInt16)
  l = __cell_length(FSS)
  mfsize = Unums.max_fsize(FSS)
  quote
    shift = (shift > $mfsize) ? ($mfsize + o16) : shift
    middle_cell = $l - div(shift, 0x0040)
    middle_mask = 0x0040 - shift % 0x0040
    for idx = __cell_length(FSS):-1:(middle_cell + 1)
      @inbounds (num.a[idx] == 0) || return UNUM_UBIT_MASK
    end
    return @inbounds ((num.a[middle_cell] & mask_bot(middle_mask)) != z64) * UNUM_UBIT_MASK
  end
end

function rsh_underflow_check!{FSS}(num::ArrayNum{FSS}, shift::UInt16)
  ubit_needed = underflow_check(num, shift)
  rsh!(num, shift)
  ubit_needed
end

################################################################################
## frac versions of this function

function frac_rsh_underflow_check!{ESS, FSS}(x::UnumSmall{ESS,FSS}, shift::UInt16)
  (x.fraction, ubit_needed) = rsh_underflow_check(x.fraction, shift, Val{FSS})
  x.flags |= ubit_needed
  return x
end

function frac_rsh_underflow_check!{ESS, FSS}(x::UnumLarge{ESS,FSS}, shift::UInt16)
  ubit_needed = rsh_underflow_check!(x.fraction, shift)
  x.flags |= ubit_needed
  return x
end

################################################################################
## shift with carry
doc"""
  `shift_with_carry(carry::UInt64, fraction::UInt64, shift::UInt16)`
  `shift_with_carry(carry::UInt64, fraction::ArrayNum, shift::UInt16)`

  shifts a fraction by shift spaces to the left, and copies that number of
  bits into the fraction at the shift position.
"""
function shift_with_carry(carry::UInt64, fraction::UInt64, shift::UInt16)
  fraction = rsh(fraction, shift)
  carry_xfer = carry << (0x0040 - shift)
  carry >>= shift
  old_fraction = fraction
  fraction += carry_xfer
  (old_fraction < fraction) && (carry += o64)
  return (carry, fraction)
end
function shift_with_carry{FSS}(carry::UInt64, fraction::ArrayNum{FSS}, shift::UInt16)
  rsh!(fraction, shift)
  shiftbits = shift % 0x0040
  shiftcell = (shift ÷ 0x0040) + 1
  carry_xfer = carry << (0x0040 - shiftbits)
  carry >>= shift
  @inbounds begin
    oldvalue = fraction.a[shiftcell]
    fraction.a[shiftcell] += carry_xfer
    (oldvalue < fraction.a[shiftcell]) && (carry += o64)
  end
  if (shiftcell > 1)
    @inbounds fraction.a[shiftcell - 1] = carry
    carry = 0
  end
  return (carry, fraction)
end

@universal function frac_shift_with_carry!(carry::UInt64, x::Unum, shift::UInt16)
  (carry, x.fraction) = shift_with_carry(carry, x.fraction, shift)
  return carry
end
