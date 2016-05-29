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
function mask_top(fsize::UInt16)
  reinterpret(UInt64, -9223372036854775808 >> fsize)
end
mask_top(FSS::Int64) = mask_top(max_fsize(FSS))

doc"""
`Unums.mask_bot` returns an UInt64 with the 'bottom mask' of a particular fsize.
The bottom mask labels the bits which are going to be thrown away and are not
part of the unum representation and are there only because of the padding
scheme.   Note that this is only valid for single UInt64s.  For ArrayNums, you
will need the Unums.mask_bot! function.
Passing an Int64 to `mask_top(FSS::Int64)` automatically detects it to generate
a mask for the FSS in general.
"""
function mask_bot(fsize::UInt16)
  ~reinterpret(UInt64, -9223372036854775808 >> fsize)
end
mask_bot(FSS::Int64) = mask_bot(max_fsize(FSS))

const top_array = [f64, z64, z64]
doc"""
`Unums.mask_top!` fills an array with the 'top mask' of a particular fsize.  The
top mask labels the bits which are part of the unum representation.
"""
function mask_top!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  middle_cell = div(fsize, 0x0040) + 1
  top_array[2] = mask_top(fsize % 0x0040)
  for idx = 1:__cell_length(FSS)
    @inbounds n.a[idx] = top_array[sign(idx - middle_cell) + 2]
  end
  n
end

const bot_array = [z64, z64, f64]
doc"""
`Unums.mask_bot!` fills an array with the 'bottom mask' of a particular fsize.
The bottom mask labels the bits which are going to be thrown away and are not
part of the unum representation and are there only because of the padding
scheme.
"""
function mask_bot!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  middle_cell = div(fsize, 0x0040) + 1
  bot_array[2] = mask_bot(fsize % 0x0040)
  for idx = 1:__cell_length(FSS)
    @inbounds n.a[idx] = bot_array[sign(idx - middle_cell) + 2]
  end
end

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
function bottom_bit(fsize::UInt16)
  reinterpret(UInt64, -9223372036854775808 >>> fsize)
end

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
  n
end

function bottom_bit!{FSS}(n::ArrayNum{FSS})
  l = __cell_length(FSS)
  for idx = 1:(l-1)
    @inbounds n.a[idx] = z64
  end
  @inbounds n.a[l] = o64
  n
end
