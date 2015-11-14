#clzctz.jl
#leading_zeros and trailing_zeros operations, stored as global function variables.

@gen_code function Base.leading_zeros{FSS}(n::ArrayNum{FSS})
  @code :(res::Int = 0)
  #iterate down the array starting from the most significant cell
  #unroll the instructions.
  for idx = 1:__cell_length(FSS)
    @code quote
      @inbounds (n.a[$idx] != 0) && return res + leading_zeros(n.a[$idx]) #kick it to the builtin clz internal.
      res += 64                                                           #add 64 to the result.
    end
  end
end

#for when it's a superint (that's not a straight Uint64)
@gen_code function Base.trailing_zeros{FSS}(n::ArrayNum{FSS})
  @code :(res::Int = 0)
  #iterate down the array starting from the least significant cell (highest index)
  #unroll the instrucitons.
  for idx = __cell_length(FSS):-1:1
    @code quote
      #kick it to the builtin leading_zeros function which accesses the internal.
      @inbounds (n.a[$idx] != 0) && return res + trailing_zeros(n.a[$idx])
      res += 64                                   #add 64 to the result.
    end
  end
end
