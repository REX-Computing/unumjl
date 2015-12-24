#int64o-math.jl

#carried_add adds the value in the first passed arraynum into the second arraynum.
@gen_code function __carried_add!{FSS}(carry::UInt64, a::ArrayNum{FSS}, b::ArrayNum{FSS})
  l = __cell_length(FSS)
  #iterating from most significant to least significant, while counter-intuitive
  #works because it prevents having to disambiguate between the +0...0 and the
  #+(F...F + carry) cases.
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
end
