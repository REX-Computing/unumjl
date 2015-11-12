#i64o-masks.jl

#masking and related operations on superints.

#generates top and bottom masks corresponding to a certain fsize
function mask_top(fsize::UInt16)
  reinterpret(UInt64, -9223372036854775808 >> fsize)
end

function mask_bot(fsize::UInt16)
  ~reinterpret(UInt64, -9223372036854775808 >> fsize)
end

#fill x least significant bits with ones.  Negative numbers fill most sig. bits
#assume there is one cell, if no value has been passed.
#these functions are generated such that we have a switch-less design.
@generated function mask_top!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  code = :( middle_cell = div(fsize, 0x0040) + 1 )
  for idx = 1:__cell_length(FSS)
    code = :($code;
      @inbounds n.a[$idx] = $idx < middle_cell ? f64 : ($idx > middle_cell ? z64 : mask_top(fsize % 0x0040)))
  end
  :($code; nothing)
end
@generated function mask_bot!{FSS}(n::ArrayNum{FSS}, fsize::UInt16)
  code = :( middle_cell = div(fsize, 0x0040) + 1 )
  for idx = 1:__cell_length(FSS)
    code = :($code;
      @inbounds n.a[$idx] = $idx < middle_cell ? z64 : ($idx > middle_cell ? f64 : mask_bot(fsize % 0x0040)))
  end
  :($code; nothing)
end
