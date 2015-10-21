#i64o-masks.jl

#masking and related operations on superints.

#generates a mask of a certain number of bits on the right, or left if negative
function mask(bits::Integer)
  if bits >= 0
    (bits == 64) ? uint64(-1) : uint64((1 << bits) - 1)
  else
    uint64(~mask(64 + bits))
  end
end
#does the same, except with a unit range.
function mask(range::UnitRange)
  uint64((1 << (range.stop + 1)) - (1 << (range.start)))
end

#fill x least significant bits with ones.  Negative numbers fill most sig. bits
#assume there is one cell, if no value has been passed.
function fillbits(n::Integer, cells::Uint16 = 1)
  #kick it to the mask function if there's only one cell.
  if cells == 1
    return mask(n)
  end
  lowlimit::Uint16 = 0
  #generate the cells.
  if n == ((cells << 6)) || (-n == (cells << 6))
    #check to see if we're asking to fill the entire set of cells
    [f64 for i=1:cells]
  elseif n > 0
    #cells filled from the right to the left
    lowlimit = n >> 6
    [[f64 for i=1:lowlimit], mask(n % 64), [z64 for i=lowlimit+2:cells]]
  elseif n < 0
    #cells filled from the left to the right
    lowlimit = (-n) >> 6
    [[z64 for i=lowlimit + 2:cells], mask(n%64), [f64 for i=1:lowlimit]]
  else
    #empty cells
    zeros(Uint64, cells)
  end
end
