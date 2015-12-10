#clzctz.jl
#leading_zeros and trailing_zeros operations, stored as global function variables.

doc"""
  `clz(::UInt64)` and 'clz(::ArrayNum)' count the leading zeros and return a
  UInt16 value (instead of the Int64 standard value for leading_zeros.)
"""
clz(n::UInt64) = UInt16(leading_zeros(n))  #NB:  This should be shimmed with a 'fast' version
                                           #that goes directly to UInt16
@gen_code function clz{FSS}(n::ArrayNum{FSS})
  @code :(res = z16)
  #iterate down the array starting from the most significant cell
  #unroll the instructions.
  for idx = 1:__cell_length(FSS)
    @code quote
      @inbounds (n.a[$idx] != 0) && return res + clz(n.a[$idx]) #kick it to the builtin clz internal.
      res += 0x0040                                             #add 64 to the result.
    end
  end
end

doc"""
  `ctz(::UInt64)` and 'ctz(::ArrayNum)' count the trailing zeros and return a
  UInt16 value (instead of the Int64 standard value for trailing_zeros.)
"""
ctz(n::UInt64) = UInt16(trailing_zeros(n))
#for when it's a superint (that's not a straight Uint64)
@gen_code function ctz{FSS}(n::ArrayNum{FSS})
  @code :(res = z16)
  #iterate down the array starting from the least significant cell (highest index)
  #unroll the instrucitons.
  for idx = __cell_length(FSS):-1:1
    @code quote
      #kick it to the builtin leading_zeros function which accesses the internal.
      @inbounds (n.a[$idx] != 0) && return res + ctz(n.a[$idx])
      res += 0x0040                                  #add 64 to the result.
    end
  end
end

export clz, ctz
