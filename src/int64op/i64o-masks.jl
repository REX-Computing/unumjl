#i64o-masks.jl

#masking and related operations on superints.

#generates a mask of a certain number of bits on the right, or left if negative
function mask(bits::Int)
  if bits >= 0
    (bits == 64) ? -one(UInt64) : UInt64((1 << bits) - 1)
  else
    UInt64(~mask(64 + bits))
  end
end

#fill x least significant bits with ones.  Negative numbers fill most sig. bits
#assume there is one cell, if no value has been passed.
function fillbits(n::Int, cells::Int = 1)
  #kick it to the mask function if there's only one cell.
  (cells == 1) && return mask(n)

  #allocate our filling mask.
  res = zeros(UInt64, cells)
  #generate the cells.
  if n == ((cells << 6)) || (-n == (cells << 6))
    #check to see if we're asking to fill the entire set of cells
    for idx = 1:cells; res[idx] = f64; end
  elseif n == 0
    #we don't have to fill up anything.
    nothing
  else
    #first assign the border cell.
    bordercell::Int = n < 0 ? (abs(n) >> 6 + 1) : cells - (n >> 6)
    #cells filled from the right to the left
    for idx = 1:cells
      if idx < bordercell
        #the lower indices are populated with zeros if we're filling from lsb.
        res[idx] = n > 0 ? z64 : f64
      elseif idx == bordercell
        #easily gets passed to mask.
        res[idx] = mask(n % 64)
      else
        #the higher indices are populated with ones if we're filling from msb.
        res[idx] = n > 0 ? f64 : z64
      end
    end
  end
  res
end
