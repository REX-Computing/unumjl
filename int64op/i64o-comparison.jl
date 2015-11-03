#i64o-comparison.jl
#comparison operators on SuperInts

#note that the less than function walks UP the array (decreasing significance)
#seeking evidence definitively asserting the relationship between a and b.  if
#the cell at the examined significance is equal, then the algorithm moves to the
#next significant cell and seeks a decesion for that.  If all of the cells are
#equal then it spits out false.
function <(a::Array{UInt64,1}, b::Array{UInt64,1})
  for i = 1:length(a)
    @inbounds (a[i] > b[i]) && return false
    @inbounds (a[i] < b[i]) && return true
  end
  return false
end

#the greater than function operates the same way with antisymmetrical relation
#checks.
function >(a::Array{UInt64,1}, b::Array{UInt64,1})
  for i=1:length(a)
    @inbounds (a[i] < b[i]) && return false
    @inbounds (a[i] > b[i]) && return true
  end
  return false
end
