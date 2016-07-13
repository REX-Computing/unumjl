doc"""
  `Unums.Gflags` is an internal type strtucture thats carries calculation
  override information about the gnum.  Certain special values (infinity, NaN,
  zero, etc.) can trigger overrides of the default calculation and proceed to
  a faster calculation.  This needs to be in a separate, to allow the gnum
  itself to be immutable, and code-optimized.
"""
type Gflags
  lower::UInt16
  upper::UInt16
end


doc"""
  `Unums.Gnum{ESS,FSS}` is an internal type structure that's not exposed to
  the global scope.  It represents the g-layer from the "End of Error".  Some
  of the status flags are stored in the flags parameter of the 'lower' term.

  this will be mostly used by the internal `@glayer` directive which will take
  an expression and convert it to a series of functions, which, at compile-time,
  will allocate a set of 'global' gnum registers, then pass them through a chain
  of mutator functions which will keep the gnum value in the registers, then
  output the whole thing as a single Utype value as needed (Unum or Ubound)

  The Gnum value also keeps a 'buffer' variable to store calculated unums for
  certain operations.  This variable is DISTINCT from the 'scratchpad' in that
  it does NOT carry extra precision, and should only be used when operations
  need to use an intermediate value before or after a calculation.  For example,
  mmr - (val) requires calculating a lower bound starting with bigexact.  Or
  multiplication of ubounds requires storing unum variables for comparison.
"""
abstract Gnum{ESS,FSS} <: Real

immutable GnumSmall{ESS,FSS} <: Gnum{ESS,FSS}
  lower::UnumSmall{ESS,FSS}
  upper::UnumSmall{ESS,FSS}
  #the buffer a preallocated location to store unum values.
  buffer::UnumSmall{ESS,FSS}
  #flags is a section that holds flagged values about the lower and upper unums
  flags::Gflags
end

immutable GnumLarge{ESS,FSS} <: Gnum{ESS,FSS}
  lower::UnumLarge{ESS,FSS}
  upper::UnumLarge{ESS,FSS}
  #the buffer a preallocated location to store unum values.
  buffer::UnumLarge{ESS,FSS}
  #flags is a section that holds flagged values about the lower and upper unums]
  flags::Gflags
end

#these g-layer values go into the scratchpad to indicate properties of the gnum.
GNUM_ONESIDED_MASK = 0x8000
#throws a bit saying this number is NaN.
GNUM_NAN_MASK  = 0x4000
GNUM_SFLAGS_MASK = 0xC000

#g-layer flags that apply to both "lower" and "higher" slots.
#temporary flag saying to ignore calculations on this side of the gnum.
GNUM_IGNORE_SIDE_MASK = 0x2000

#################################
#precedence of bits:
# NAN > SBIT > IGNORE
# A nan is automatically single, even if sbit isn't thrown.
# An SBIT automatically ignores the second value, even if ignore isn't thrown.

#informational flags that report on the identity of the number.
GNUM_FLAG_MASK = 0x0F00
GNUM_INF_MASK  = 0x0800
GNUM_MMR_MASK  = 0x0400
GNUM_SSS_MASK  = 0x0200
GNUM_ZERO_MASK = 0x0100

#make lower and upper side designations more elegant.
const LOWER_UNUM = Val{:lower}
const UPPER_UNUM = Val{:upper}
const SCRATCHPAD = Val{:scratchpad}
const BUFFER = Val{:buffer}
#other values used for instruction directives in mults and divs
const DISCARD_PRIMARY = Val{:discard_primary}
const DISCARD_SECONDARY = Val{:discard_secondary}

#create a global scratchpad array.
const GLOBAL_SCRATCHPAD_SIZE = __cell_length(11) + (__cell_length(11) >> 1)
const GLOBAL_SCRATCHPAD = zeros(UInt64, GLOBAL_SCRATCHPAD_SIZE)

#scratches an operation.
macro scratch_this_operation!(s)
  esc(quote
    nan!($s)
    ignore_both_sides!($s)
    return
  end)
end

macro init_sflags()
  esc(:(sflags::UInt16))
end

macro preserve_sflags(s, expr)
  esc(quote
    sflags = $s.scratchpad.flags & GNUM_SFLAGS_MASK
    $expr
    $s.scratchpad.flags |= sflags
  end)
end
