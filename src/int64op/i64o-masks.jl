#i64o-masks.jl

#masking and related operations on superints.

#generates top and bottom masks corresponding to a certain fsize
doc"""
`Unums.mask_top` returns an UInt64 with the 'top mask' of a particular fsize.
The top mask labels the bits which are part of the unum representation.  Note
that this is only valid for single UInt64s.  For ArrayNums, you will need the
Unums.mask_top! function.
Passing an Int64 to `mask_top(FSS::Int64)` automatically detects it to generate
a mask for the FSS in general.
"""
mask_top(fsize::UInt16) = reinterpret(UInt64, -9223372036854775808 >> fsize)
mask_top(FSS::Int64) = mask_top(max_fsize(FSS))
mask_top(::UInt64, fsize::UInt16) = reinterpret(UInt64, -9223372036854775808 >> fsize)

doc"""
`Unums.mask_bot` returns an UInt64 with the 'bottom mask' of a particular fsize.
The bottom mask labels the bits which are going to be thrown away and are not
part of the unum representation and are there only because of the padding
scheme.   Note that this is only valid for single UInt64s.  For ArrayNums, you
will need the Unums.mask_bot! function.
Passing an Int64 to `mask_top(FSS::Int64)` automatically detects it to generate
a mask for the FSS in general.
"""
mask_bot(fsize::UInt16) = ~reinterpret(UInt64, -9223372036854775808 >> fsize)
mask_bot(FSS::Int64) = mask_bot(max_fsize(FSS))
mask_bot(::UInt64, fsize::UInt16) = ~reinterpret(UInt64, -9223372036854775808 >> fsize)

doc"""
`Unums.mask_top!` fills an array with the 'top mask' of a particular fsize.  The
top mask labels the bits which are part of the unum representation.
"""
function mask_top!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  middle_spot = div(fsize, 0x0040) + 1
  middle_cell = mask_top(fsize % 0x0040)
  for idx = 1:__cell_length(FSS)
    @inbounds n.a[idx] = (idx < middle_spot) * f64
    @inbounds n.a[idx] += (idx == middle_spot) * middle_cell
  end
  return n
end

#generates frac_mask_top!{ESS,FSS}(Unum{ESS,FSS})
@fracproc mask_top fsize

const bot_array = [z64, z64, f64]
doc"""
`Unums.mask_bot!` fills an array with the 'bottom mask' of a particular fsize.
The bottom mask labels the bits which are going to be thrown away and are not
part of the unum representation and are there only because of the padding
scheme.
"""
function mask_bot!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  middle_spot = div(fsize, 0x0040) + 1
  middle_cell = mask_bot(fsize % 0x0040)
  for idx = 1:__cell_length(FSS)
    @inbounds n.a[idx] = (idx > middle_spot) * f64
    @inbounds n.a[idx] += (idx == middle_spot) * middle_cell
  end
  return n
end

@fracproc mask_bot fsize

doc"""
`Unums.fill_mask!` takes two arraynums and fills the first one with the UInt64 AND
operation with each other UInt64.
"""
function fill_mask!{FSS}(n::ArrayNum{FSS}, m::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @inbounds n.a[idx] = n.a[idx] & m.a[idx]
  end
  n
end

doc"""
`Unums.bottom_bit` returns the bottom bit of a fraction with a given fsize.
"""
bottom_bit(fsize::UInt16) = reinterpret(UInt64, -9223372036854775808 >>> fsize)
bottom_bit(FSS::Int64) = bottom_bit(max_fsize(FSS))
bottom_bit(::UInt64, fsize::UInt16) = reinterpret(UInt64, -9223372036854775808 >>> fsize)
bottom_bit(::UInt64) = reinterpret(UInt64, -9223372036854775808 >>> fsize)

doc"""
`Unums.bottom_bit!` returns the bottom bit of a fraction with a given fsize.
If no fsize is provided, it returns a zero arraynum with the lowest bit set.
"""
function bottom_bit!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  middle_cell = div(fsize, 0x0040) + 1
  middle_word = t64 >> (fsize % 0x0040)
  for idx = 1:__cell_length(FSS)
    @inbounds n.a[idx] = (idx == middle_cell) * middle_word
  end
  return n
end

function bottom_bit!{FSS}(n::ArrayNum{FSS})
  l = __cell_length(FSS)
  for idx = 1:(l-1)
    @inbounds n.a[idx] = z64
  end
  @inbounds n.a[l] = o64
  return n
end

@fracproc bottom_bit fsize
frac_bottom_bit!{ESS,FSS}(x::UnumSmall{ESS,FSS}) = (x.fraction = bottom_bit(FSS); return x)
frac_bottom_bit!{ESS,FSS}(x::UnumLarge{ESS,FSS}) = (bottom_bit!(x.fraction); return x)
