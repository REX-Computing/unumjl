#clzctz.jl
#leading_zeros and trailing_zeros operations, stored as global function variables.

doc"""
  `clz(::UInt64)` and 'clz(::ArrayNum)' count the leading zeros and return a
  UInt16 value (instead of the Int64 standard value for leading_zeros.)
"""
clz(n::UInt64) = to16(leading_zeros(n))  #NB:  This should be shimmed with a 'fast' version
                                           #that goes directly to UInt16
clz(n::UInt16) = to16(leading_zeros(n))
function clz{FSS}(n::ArrayNum{FSS})
  res::UInt16 = z16
  cellvalue::UInt64 = z64
  #iterate down the array starting from the most significant cell
  for idx = 1:__cell_length(FSS)
    @inbounds (cellvalue = n.a[idx])
    res += clz(cellvalue)
    (cellvalue != z64) && return res
  end
  res
end

doc"""
  `ctz(::UInt64)` and 'ctz(::ArrayNum)' count the trailing zeros and return a
  UInt16 value (instead of the Int64 standard value for trailing_zeros.)
"""
ctz(n::UInt64) = to16(trailing_zeros(n))
#for when it's a superint (that's not a straight Uint64)
function ctz{FSS}(n::ArrayNum{FSS})
  res::UInt16 = z16
  should_continue::Bool = true
  cellvalue::UInt64 = z64
  #iterate down the array starting from the least significant cell (highest index)
  for idx = __cell_length(FSS):-1:1
    @inbounds (cellvalue = n.a[idx])
    res += ctz(cellvalue)
    (cellvalue != z64) && return res
  end
  res
end

doc"""
  `cto(::UInt64)` and 'cto(::ArrayNum)' count the trailing ones and return a
  UInt16 value (instead of the Int64 standard value for trailing_zeros.)
"""
cto(n::UInt64) = to16(trailing_ones(n))
#for when it's a superint (that's not a straight Uint64)
function cto{FSS}(n::ArrayNum{FSS})
  res::UInt16 = z16
  should_continue::Bool = true
  cellvalue::UInt64 = z64
  #iterate down the array starting from the least significant cell (highest index)
  for idx = __cell_length(FSS):-1:1
    @inbounds (cellvalue = n.a[idx])
    res += cto(cellvalue)
    (cellvalue != f64) && return res
  end
  res
end

export clz, ctz, cto
