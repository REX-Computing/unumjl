

################################################################################
## COMPARISON tests on the int64 part of the library.
AN7 = Unums.ArrayNum{7}

@test AN7([allbits, 0x0000_0000_0000_0001]) > AN7([allbits, nobits])
@test AN7([0x0000_0000_0000_0001, nobits]) >  AN7([nobits, allbits])
@test AN7([allbits, nobits]) < AN7([allbits, 0x0000_0000_0000_0001])
@test AN7([nobits, allbits]) < AN7([0x0000_0000_0000_0001, nobits])

#test developer safety on the cmplusubit_ordered function.
@devmode_on begin
  #if the two fsizes are in the same fsize region
  @test_throws ArgumentError Unums.cmpplusubit_ordered(zero(AN7), zero(AN7), z16, o16) #problem because they're in the same cell.
  @test_throws ArgumentError Unums.cmpplusubit_ordered(zero(AN7), zero(AN7), 0x0041, z16) #problem because cell b is before cell a.
  @test_throws ArgumentError Unums.cmpplusubit_matched(zero(AN7), zero(AN7), 0x0041, z16)
  @test_throws ArgumentError Unums.cmpplusubit_matched(zero(AN7), zero(AN7), z16, 0x0041)
end

@test contract_outer_fsize(0x0000_0000_0000_FFFF, 0x003F) == 0x0030
@test contract_outer_fsize(0x0000_FFFF_FFFF_FFFF, 0x003F) == 0x0010
@test contract_outer_fsize(0x0000_FFFF_0000_0000, 0x001F) == 0x0010
@test contract_outer_fsize(0x0000_FFFF_0000_0000, 0x002F) == 0x002f
@test contract_outer_fsize(0xFFFF_FFFF_0000_0000, 0x001F) == 0x0000
@test contract_outer_fsize(0x7FFF_FFFF_0000_0000, 0x001F) == 0x0001

@test contract_inner_fsize(0x0000_0000_0000_0000, 0x003F) == 0x0000
@test contract_inner_fsize(0x0000_1000_0000_0000, 0x003F) == 0x0014
@test contract_inner_fsize(0x0000_8000_0000_0000, 0x003F) == 0x0011
@test contract_inner_fsize(0x0001_0000_0000_0000, 0x003F) == 0x0010




#=
function __check_cmpplusubit_ordered(FSS, a, b, a_fsize::UInt16, b_fsize::UInt16)
  (div(a_fsize, 0x0040) < div(b_fsize, 0x0040)) || throw(ArgumentError("cmpplusubit_ordered called with improper fsize ordering."))
end

doc"""
  `Unums.cmpplusubit_ordered(a::ArrayNum, b::ArrayNum, a_fsize, b_fsize)`
  compares two ubit arraynums and sees if they have equivalent outer bounds.
  Prerequisite:  a_fsize and b_fsize fall in different array cells, a_fsize comes
  before b_fsize
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
  @inbounds (a.a[middle_spot_a] + ubit) != (b.a[middle_spot_a] + o64) && return false
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
function __check_cmpplusubit_matched(FSS, a, b, a_fsize::UInt16, b_fsize::UInt16)
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


function cmpplusubit{FSS}(a::UInt64, b::UInt64, a_fsize::UInt16, b_fsize::UInt16)
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
=#
