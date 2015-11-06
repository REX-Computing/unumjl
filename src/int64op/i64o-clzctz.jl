#clzctz.jl
#leading_zeros and trailing_zeros operations, stored as global function variables.

function Base.leading_zeros(n::Array{UInt64, 1})
  #iterate down the array starting from the most significant cell
  res::Int = 0
  for idx = 1:length(n)
    #kick it to the previous leading_zeros function
    @inbounds (n[idx] != 0) && return res + leading_zeros(n[idx])
    res += 0x0040
  end
  res
end

#for when it's a superint (that's not a straight Uint64)
function Base.trailing_zeros(n::Array{UInt64, 1})
  #iterate down the array starting from the least significant cell (highest index)
  res::Int = 0
  for idx = length(n):-1:1
    #kick it to the previous leading_zeros function
    @inbounds (n[idx] != 0) && return res + trailing_zeros(n[idx])
    res += 0x0040
  end
  res
end
