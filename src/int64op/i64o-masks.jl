#i64o-masks.jl

#masking and related operations on superints.

#generates top and bottom masks corresponding to a certain fsize
doc"""
`Unums.mask_top` returns an UInt64 with the 'top mask' of a particular fsize.
The top mask labels the bits which are part of the unum representation.  Note
that this is only valid for single UInt64s.  For ArrayNums, you will need the
Unums.mask_top! function.
"""
function mask_top(fsize::UInt16)
  reinterpret(UInt64, -9223372036854775808 >> fsize)
end

doc"""
`Unums.mask_bot` returns an UInt64 with the 'bottom mask' of a particular fsize.
The bottom mask labels the bits which are going to be thrown away and are not
part of the unum representation and are there only because of the padding
scheme.   Note that this is only valid for single UInt64s.  For ArrayNums, you
will need the Unums.mask_bot! function.
"""
function mask_bot(fsize::UInt16)
  ~reinterpret(UInt64, -9223372036854775808 >> fsize)
end

doc"""
`Unums.mask_top!` fills an array with the 'top mask' of a particular fsize.  The
top mask labels the bits which are part of the unum representation.
"""
@gen_code function mask_top!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  @code :( middle_cell = div(fsize, 0x0040) + 1 )
  for idx = 1:__cell_length(FSS)
    @code :(@inbounds n.a[$idx] = $idx < middle_cell ? f64 : ($idx > middle_cell ? z64 : mask_top(fsize % 0x0040)))
  end
  @code :(nothing)
end

doc"""
`Unums.mask_bot!` fills an array with the 'bottom mask' of a particular fsize.
The bottom mask labels the bits which are going to be thrown away and are not
part of the unum representation and are there only because of the padding
scheme.
"""
@gen_code function mask_bot!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  @code :( middle_cell = div(fsize, 0x0040) + 1 )
  for idx = 1:__cell_length(FSS)
    @code :(@inbounds n.a[$idx] = $idx < middle_cell ? z64 : ($idx > middle_cell ? f64 : mask_bot(fsize % 0x0040)))
  end
  @code :(nothing)
end

doc"""
`Unums.fill_mask!` takes two arraynums and fills the first one with the UInt64 AND
operation with each other UInt64.
"""
@gen_code function fill_mask!{FSS}(n::ArrayNum{FSS}, m::ArrayNum{FSS})
  for idx = 1:__cell_length(FSS)
    @code :(@inbounds n.a[$idx] = n.a[$idx] & m.a[$idx])
  end
  @code :(nothing)
end
