#i64o-constants.jl

#various superint constants and ways of generating them
Base.zero{FSS}(::Type{ArrayNum{FSS}}) = ArrayNum{FSS}(zeros(UInt64, __cell_length(FSS)))
Base.zero{FSS}(a::Type{ArrayNum{FSS}}) = ArrayNum{FSS}(zeros(UInt64, __cell_length(FSS)))

doc"""
`zero!` sets an `ArrayNum` to zero.
"""
function zero!{FSS}(a::ArrayNum{FSS})
  #unroll the loop that fills the contents of the a with zero.
  for idx = 1:__cell_length(FSS)
    @inbounds a.a[idx] = 0
  end
end

##create Unums.frac_zero!, out of zero(UInt64) and zero!(ArrayNum)
doc"""
`Unums.frac_zero!` sets the fraction of a unum to zero.
"""
@fracfunc zero

function Base.one{FSS}(::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  arr = zeros(UInt64, l)
  arr[l] = 1
  ArrayNum{FSS}(arr)
end

function Base.one{FSS}(a::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  arr = zeros(UInt64, l)
  arr[l] = 1
  ArrayNum{FSS}(arr)
end

function top{FSS}(::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  arr = zeros(UInt64, l)
  arr[1] = t64
  ArrayNum{FSS}(arr)
end

top(n::UInt64) = t64
function top{FSS}(a::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  arr = zeros(UInt64, l)
  arr[1] = t64
  ArrayNum{FSS}(arr)
end
function top!{FSS}(a::Type{ArrayNum{FSS}})
  zero!(a)
  a[1] = t64
end
export top

doc"""`Unums.frac_top!` sets the fraction of a unum to be zero, except with the top bit set."""
@fracfunc top

doc"""`Unums.all(x::UInt64)` returns a UInt64 or an ArrayNum with all bits set."""
all(x::UInt64) = f64
all{FSS}(::Type{ArrayNum{FSS}}) = ArrayNum{FSS}([f64 for idx = 1:__cell_length(FSS)])
doc"""`Unums.all!(x::UInt64)` sets all bits on an arraynum."""
all!{FSS}(x::ArrayNum{FSS}) = for idx = 1:__cell_length(FSS); x.a[idx] = f64; end

doc"""`Unums.frac_all!` sets the fraction of a unum to be all set."""
@fracfunc all


#=
#Generates a single UInt64 array that is all zeros except for a single bit
#flipped, which is the n'th bit from the msb, 0-indexed.
function __bit_from_top(n::Int, l::Int)
  (l == 1) && return (t64 >> n)

  res = zeros(UInt64, l)
  #calculate the cell number
  cellidx = (n >> 6) + 1
  #figure out what we should replace the cell with.
  cell = UInt64(t64 >> (n % 64))
  #do the replacement
  res[cellidx] = cell
  #return the result
  res
end
=#
