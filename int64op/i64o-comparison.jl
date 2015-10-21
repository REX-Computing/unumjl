#i64o-comparison.jl
#comparison operators on SuperInts

function <(a::Array{Uint64,1}, b::Array{Uint64,1})
  for i = length(a):-1:1
    (a[i] > b[i]) && return false
    (a[i] < b[i]) && return true
  end
  return false
end

function >(a::Array{Uint64,1}, b::Array{Uint64,1})
  for i=length(a):-1:1
    (a[i] < b[i]) && return false
    (a[i] > b[i]) && return true
  end
  return false
end
