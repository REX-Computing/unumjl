#i64o-comparison.jl
#comparison operators on SuperInts

#note that the less than function walks UP the array (decreasing significance)
#seeking evidence definitively asserting the relationship between a and b.  if
#the cell at the examined significance is equal, then the algorithm moves to the
#next significant cell and seeks a decesion for that.  If all of the cells are
#equal then it spits out false.

import Base: <, >, ==, !=

@gen_code function <{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  @code quote
    res::Bool = false
    alive::Bool = true
  end
  for idx = 1:__cell_length(FSS)
    @code quote
      @inbounds res = res | (alive & (a.a[$idx] < b.a[$idx]))
      @inbounds alive = alive & (b.a[$idx] == a.a[$idx])
    end
  end
  @code :(res)
end

#the greater than function operates the same way with antisymmetrical relation
#checks.
@gen_code function >{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  @code quote
    res::Bool = false
    alive::Bool = true
  end
  for idx = 1:__cell_length(FSS)
    @code quote
      @inbounds res = res | (alive & (a.a[$idx] > b.a[$idx]))
      @inbounds alive = alive & (a.a[$idx] == b.a[$idx])
    end
  end
  @code :(res)
end

@gen_code function !={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  @code :(accum = z64)
  for idx = 1:__cell_length(FSS)
    @code :(accum |= a[$idx] $ b[$idx])
  end
  @code :(accum != 0)
end

@gen_code function =={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  @code :(accum = z64)
  for idx = 1:__cell_length(FSS)
    @code :(accum |= a[$idx] $ b[$idx])
  end
  @code :(accum == 0)
end
