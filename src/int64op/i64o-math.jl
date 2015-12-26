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
@gen_code function __carried_diff!{FSS}(vdigit::UInt64, v1::ArrayNum{FSS}, v2::ArrayNum{FSS}, guard::UInt64 = z64)
  #this algorithm follows exactly from the elementary school addition algorithm.
  #keep a "borrow" variable around and go from least significant to most significant
  #bits.  Keep a guard digit around to borrow from at the end.
  l = __cell_length(FSS)
  @code :(borrow::UInt64 = 0)
  for (idx = l:-1:1)
    @code quote
      @inbounds (b.a[$idx] -= a.a[$idx])  #perform the subtraction
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
