#i64o-shifts.jl

#bitshifting operations on superints
#iterative leftshift and rightshift operations on Array SuperInts

lsh(a::UInt64, b::Int16) = a << b
#destructive version which clobbers the existing verion
@gen_code function lsh!{FSS}(a::ArrayNum{FSS}, b::Int16)
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

rsh(a::UInt64, b::Int16) = a >> b
@gen_code function rsh!{FSS}(a::ArrayNum{FSS}, b::Int16)
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
