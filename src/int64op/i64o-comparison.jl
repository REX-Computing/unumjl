#i64o-comparison.jl
#comparison operators on SuperInts

#note that the less than function walks UP the array (decreasing significance)
#seeking evidence definitively asserting the relationship between a and b.  if
#the cell at the examined significance is equal, then the algorithm moves to the
#next significant cell and seeks a decesion for that.  If all of the cells are
#equal then it spits out false.

import Base: <, >, <=, >=, ==, !=

function <{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    (a.a[idx] < b.a[idx]) && return true
    (a.a[idx] > b.a[idx]) && return false
  end
  return false
end

function >{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    (a.a[idx] > b.a[idx]) && return true
    (a.a[idx] < b.a[idx]) && return false
  end
  return false
end

function <={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    (a.a[idx] < b.a[idx]) && return true
    (a.a[idx] > b.a[idx]) && return false
  end
  return true
end

function >={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    (a.a[idx] > b.a[idx]) && return true
    (a.a[idx] < b.a[idx]) && return false
  end
  return true
end

doc"""
  Unums.lessthanwithubit(a::UInt64, b::UInt64, fsize::UInt16)
  checks to make sure that a is less than b, even if a has a ubit value of fsize.
"""
function lessthanwithubit(a::UInt64, b::UInt64, fsize::UInt16, orequal::Bool = false)
  mask = mask_top(fsize) #first generate the mask corresponding to the int.
  orequal && return ((a & mask) <= (b & mask)) 
  ((a & mask) >= (b & mask)) && return false
  return true
end

function lessthanwithubit{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS}, fsize::UInt16, orequal::Bool = false)
  #compute the last cell we need to scan.
    middle_spot = div(fsize, 0x0040) + 1
    middle_mask = fsize % 0x0040
    for idx = 1:(middle_spot - 1)
      @inbounds begin
        a.a[idx] > b.a[idx] && return false
        a.a[idx] < b.a[idx] && return true
      end
    end
    @inbounds lessthanwithubit(a.a[middle_spot], b.a[middle_spot], middle_mask, orequal)
end
#=
function cmpplusubit(a::UInt64, b::UInt64, fsize)
  mask = mask_top(fsize)
  (a > b) && ((a & mask) != (b & mask))
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
=#

function !={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds (a.a[idx] != b.a[idx]) && return true
  end
  return false
end

function =={FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds (a.a[idx] != b.a[idx]) && return false
  end
  return true
end
