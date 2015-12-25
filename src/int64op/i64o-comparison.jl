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

#compares two arraynums, up to a certain number of bits (fsize), returns true if
#a is bigger than (b with its lowest bit set).
@gen_code function cmpplusubit{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS}, fsize::UInt16)
  @code quote
    accum::Bool = true
    alive::Bool = true
    mask::UInt64 = mask_top(fsize & 0x003F)
    tmask::UInt64
    amask::UInt64
    bmask::UInt64
    fcell::UInt16 = fsize >> 6
  end

  for idx = 1:__cell_length(FSS)
    iminusone = idx - 1
    @code quote
      tmask = ((fcell < $iminusone) * f64) | mask & ~((fcell > $iminusone) * f64)
      amask = a.a[$idx] & tmask
      bmask = b.a[$idx] & tmask
      accum &= (amask < bmask)
      alive &= (amask == bmask)
    end
  end
  @code quote
    accum & (!alive)
  end
end


@gen_code function !={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  @code :(accum = z64)
  for idx = 1:__cell_length(FSS)
    @code :(accum |= a.a[$idx] $ b.a[$idx])
  end
  @code :(accum != 0)
end

@gen_code function =={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  @code :(accum = z64)
  for idx = 1:__cell_length(FSS)
    @code :(accum |= a.a[$idx] $ b.a[$idx])
  end
  @code :(accum == 0)
end
