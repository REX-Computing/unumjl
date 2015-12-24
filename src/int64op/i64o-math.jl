#int64o-math.jl

<<<<<<< HEAD
=======
#implements mathematical stuff for int64ops
function carrytoken(idx)
  return (idx == 1) ? :(carry) : :(b.a[$idx - 1])
end
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
#carried_add adds the value in the first passed arraynum into the second arraynum.
@gen_code function __carried_add!{FSS}(carry::UInt64, a::ArrayNum{FSS}, b::ArrayNum{FSS})
  l = __cell_length(FSS)
  #iterating from most significant to least significant, while counter-intuitive
  #works because it prevents having to disambiguate between the +0...0 and the
  #+(F...F + carry) cases.
<<<<<<< HEAD
  @code :(cellcarry::UInt64 = 0)
  for (idx = l:-1:1)
    #first do the direct sum.
    @code quote
      @inbounds (b.a[$idx] += a.a[$idx])
      @inbounds if (b.a[$idx] < a.a[$idx])
        @inbounds b.a[$idx] += cellcarry
        cellcarry = 1
      else
        @inbounds b.a[$idx] += cellcarry
        @inbounds cellcarry = ((cellcarry != 0) && (b.a[$idx] == 0)) ? 1 : 0
      end
    end
  end
  #add in the carry from the most significant segment to the entire carry.
  @code :(carry + cellcarry)
=======
  for (idx = l:-1:1)
    #store the form of the destination, which might either be the next siginficant
    #cell, or alternatively the carry variable.
    dest = carrytoken(idx)
    #first do the direct sum.
    @code quote
      @inbounds b.a[$idx] += a.a[$idx]
      if (a.a[$idx] != 0)
        (b.a[$idx] <= a.a[$idx]) && ($dest += 1)
      else
        (b.a[$idx] == 0) && ($dest += 1)
      end
    end
  end
  @code :(carry)
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
end
