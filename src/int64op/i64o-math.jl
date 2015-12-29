#int64o-math.jl

#carried_add adds the value in the first passed arraynum into the second arraynum.
@gen_code function __carried_add!{FSS}(carry::UInt64, a::ArrayNum{FSS}, b::ArrayNum{FSS})
  #this algorithm follows exactly from the elementary school addition algorithm.
  #keep a "carry" variable around and go from least significant to most significant
  #bits.
  l = __cell_length(FSS)
  #initialize the carry variable.
  @code :(cellcarry::UInt64 = z64)
  for (idx = l:-1:1)
    @code quote
      @inbounds (b.a[$idx] += a.a[$idx])     #perform the addition
      @inbounds if (b.a[$idx] < a.a[$idx])   #check to see if we overflowed
                  @inbounds b.a[$idx] += cellcarry #yes, then go ahead and add the previous digit's carry
                  cellcarry = o64            #and reset the current carry to one.
                else                         #maybe we didn't overflow
                  @inbounds b.a[$idx] += cellcarry #go ahead and add the previous one in
                                             #check to see if this causes an overflow and we need to reset cellcarry.
                                             #the only possible situation is if it was FF..FF and adding one went to zero.
                  @inbounds cellcarry = ((cellcarry != z64) && (b.a[$idx] == z64)) ? o64 : z64
                end
    end
  end
  #add in the carry from the most significant segment to the entire carry.
  @code :(carry + cellcarry)
end

#carried_sub subtracts the value in the second passed arraynum from the first arraynum.
@gen_code function __carried_diff!{FSS}(vdigit::UInt64, a::ArrayNum{FSS}, b::ArrayNum{FSS})
  #this algorithm follows exactly from the elementary school addition algorithm.
  #keep a "borrow" variable around and go from least significant to most significant
  #bits.  Keep a guard digit around to borrow from at the end.
  l = __cell_length(FSS)
  @code :(borrow::UInt64 = 0)
  for (idx = l:-1:1)
    @code quote
      @inbounds (b.a[$idx] = a.a[$idx] - b.a[$idx])  #perform the subtraction
      @inbounds if (b.a[$idx] > a.a[$idx])  #check to see if we underflowed
                  @inbounds b.a[$idx] -= borrow  #go ahead and subtract the previous digit's carry.
                  borrow = o64#reset the current borrow to one
                else
                  @inbounds b.a[$idx] -= borrow
                  @inbounds borrow = ((borrow != z64) && (b.a[$idx] == f64)) ? o64 : z64
                end
    end
  end
  @code :(vdigit - borrow)
end

function __add_ubit(a::UInt64, fsize::UInt16)
  a += (t64 >> fsize)
  promoted = (a == 0)
  (promoted, a)
end

@gen_code function __add_ubit!{FSS}(a::ArrayNum{FSS}, fsize::UInt16)
  #basically the same as the addition alogrithm, except not adding in an array.
  l = __cell_length(FSS)
  #initialize the carry variable.
  @code quote
    middle_cell::UInt16 = (fsize >> 6) + 1
    cellcarry::UInt64 = z64
    ubitform::UInt64 = mask_top(fsize & 0x003F)
  end
  for (idx = l:-1:1)
    @code quote
      #figure out what cellcarry should be.
      cellcarry += ($idx == middle_cell) * ubitform
      @inbounds (a.a[$idx] += cellcarry)     #perform the addition
      @inbounds (cellcarry != 0) && (a.a[$idx] == 0) && (cellcarry = o64)
    end
  end
  #add in the carry from the most significant segment to the entire carry.
  @code :(cellcarry != 0)
end

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
