#i64o-constants.jl

#various superint constants and ways of generating them
Base.zero{FSS}(::Type{ArrayNum{FSS}}) = ArrayNum{FSS}(zeros(UInt64, __cell_length(FSS)))
Base.zero{FSS}(a::ArrayNum{FSS}) = ArrayNum{FSS}(zeros(UInt64, __cell_length(FSS)))

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
@fracproc zero

function Base.one{FSS}(::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  arr = zeros(UInt64, l)
  @inbounds arr[l] = 1
  ArrayNum{FSS}(arr)
end

function Base.one{FSS}(a::ArrayNum{FSS})
  one(ArrayNum{FSS})
end

function top{FSS}(::Type{ArrayNum{FSS}})
  l = __cell_length(FSS)
  arr = zeros(UInt64, l)
  @inbounds arr[1] = t64
  ArrayNum{FSS}(arr)
end

top(n::UInt64) = t64
function top{FSS}(a::ArrayNum{FSS})
  top(ArrayNum{FSS})
end
function top!{FSS}(a::Type{ArrayNum{FSS}})
  zero!(a)
  @inbounds a[1] = t64
end
export top

doc"""`Unums.frac_top!` sets the fraction of a unum to be zero, except with the top bit set."""
@fracproc top

doc"""`Unums.all(x::UInt64)` returns a UInt64 or an ArrayNum with all bits set."""
all(x::UInt64) = f64
all{FSS}(::Type{ArrayNum{FSS}}) = ArrayNum{FSS}([f64 for idx = 1:__cell_length(FSS)])
doc"""`Unums.all!(x::UInt64)` sets all bits on an arraynum."""
all!{FSS}(x::ArrayNum{FSS}) = for idx = 1:__cell_length(FSS); @inbounds x.a[idx] = f64; end

doc"""`Unums.frac_all!` sets the fraction of a unum to be all set."""
@fracproc all
