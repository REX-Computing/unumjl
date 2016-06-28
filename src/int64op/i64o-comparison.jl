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
  `Unums.lessthanwithubit(a::UInt64, b::UInt64, fsize::UInt16, orequal = false)`
  `Unums.lessthanwithubit(a::ArrayNum, b::ArrayNum, fisize::UInt16, orequal = false)`
  checks to make sure that a is less than b, even if a has a ubit value of fsize.
  you can do an 'orequal' which returns less than or equal.
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
    middle_size = fsize % 0x0040
    for idx = 1:(middle_spot - 1)
      @inbounds begin
        a.a[idx] > b.a[idx] && return false
        a.a[idx] < b.a[idx] && return true
      end
    end

    @inbounds res = lessthanwithubit(a.a[middle_spot], b.a[middle_spot], middle_size, orequal)
    return res
end

################################################################################
# cmpplusubit - checks to see if two fractions with ubits have the same exterior
# value.

doc"""
  `Unums.__check_cmpplusubit_ordered(FSS, a, b, a_fsize, b_fsize)`
  checks to make sure the a_fsize and b_fsize values parameters are correct
  prior to being passed to cmpplus_ubit_ordered.
"""
function __check_cmpplusubit_ordered(a, b, a_fsize::UInt16, b_fsize::UInt16)
  (div(a_fsize, 0x0040) < div(b_fsize, 0x0040)) || throw(ArgumentError("cmpplusubit_ordered called with improper fsize ordering."))
end

doc"""
  `Unums.cmpplusubit_ordered(a::ArrayNum, b::ArrayNum, a_fsize, b_fsize)`
  compares two ubit arraynums and sees if they have equivalent outer bounds.
  Prerequisite:  a_fsize and b_fsize fall in different array cells.
"""
@dev_check function cmpplusubit_ordered{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS}, a_fsize, b_fsize)
  middle_spot_a = div(a_fsize, 0x0040) + 1
  middle_spot_b = div(b_fsize, 0x0040) + 1
  middle_size_a = a_fsize % 0x0040
  middle_size_b = b_fsize % 0x0040

  for idx = 1:(middle_spot_a - 1)
    @inbounds (a.a[idx] != b.a[idx]) && return false
  end
  #do with middle_spot_a
  @inbounds (a.a[middle_spot_a] + (t64 >> middle_size_a)) != (b.a[middle_spot_a] + o64) && return false
  for idx = (middle_spot_a + 1):(middle_spot_b - 1)
    @inbounds (b.a[idx] != f64) && return false
  end
  #do with middle_spot_b
  @inbounds (b.a[middle_spot_b] != top_mask(middle_size_b)) && return false
  return true
end

doc"""
  `Unums.__check_cmpplusubit_matched(FSS, a, b, a_fsize, b_fsize)`
  checks to make sure the a_fsize and b_fsize values parameters are correct
  prior to being passed to matched.
"""
function __check_cmpplusubit_matched(a, b, a_fsize::UInt16, b_fsize::UInt16)
  (div(a_fsize, 0x0040) == div(b_fsize, 0x0040)) || throw(ArgumentError("cmpplusubit_matched called with mismatched fsize."))
end

doc"""
  `Unums.cmpplusubit_ordered(a::ArrayNum, b::ArrayNum, a_fsize, b_fsize)`
  compares two ubit arraynums and sees if they have equivalent outer bounds.
"""
@dev_check function cmpplusubit_matched{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS}, a_fsize, b_fsize)
  middle_spot = div(a_fsize, 0x0040) + 1
  middle_size_a = a_fsize % 0x0040
  middle_size_b = b_fsize % 0x0040

  for idx = 1:(middle_spot - 1)
    @inbounds (a.a[idx] != b.a[idx]) && return false
  end
  @inbounds cmpplusubit(a.a[middle_spot], b.a[middle_spot], middle_size_a, middle_size_b)
end


function cmpplusubit(a::UInt64, b::UInt64, a_fsize::UInt16, b_fsize::UInt16)
  a + (t64 >> a_fsize) == b + (t64 >> b_fsize)
end
function cmpplusubit{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS}, a_fsize::UInt16, b_fsize::UInt16)
  middle_spot_a = div(a_fsize, 0x0040) + 1
  middle_spot_b = div(b_fsize, 0x0040) + 1

  if (middle_spot_a > middle_spot_b)
    cmpplusubit_ordered(b, a, b_fsize, a_fsize)
  elseif (middle_spot_a == middle_spot_b)
    cmpplusubit_matched(a, b, a_fsize, b_fsize)
  else #middle_spot_b > middle_spot_a
    cmpplusubit_ordered(a, b, a_fsize, b_fsize)
  end
end



#=
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


function same_till_fsize(n1::UInt64, n2::UInt64, s::UInt16)
  fsize_mask = mask_top(s)
  (n1 & fsize_mask) == (n2 & fsize_mask)
end
function same_till_fsize{FSS}(n1::ArrayNum{FSS}, n2::ArrayNum{FSS}, s::UInt16)
  middle_cell = div(s, 0x0040) + o16
  middle_size = s % 0x0040
  for idx = 1:middle_cell - 1
    @inbounds (n1.a[idx] != n2.a[idx]) && return false
  end
  @inbounds return same_till_fsize(n1.a[middle_cell], n2.a[middle_cell], middle_size)
end
