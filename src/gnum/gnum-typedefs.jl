
doc"""
  `Unums.Gnum{ESS,FSS}` is an internal type structure that's not exposed to
  the global scope.  It represents the g-layer from the "End of Error".  Some
  of the status flags are stored in the flags parameter of the 'lower' term.

  this will be mostly used by the internal `@unum` directive which will take
  an expression and convert it to a series of functions, which, at compile-time,
  will allocate a set of 'global' gnum registers, then pass them through a chain
  of mutator functions which will keep the gnum value in the registers, then
  output the whole thing as a single UType value as needed (Unum or Ubound)

  the Gnum value keeps a 'scratchpad' variable to store intermediate calculations
  for any expressions.  The array value for this is pre-allocated and global.
  Although this scratchpad shouldn't be considered to be tied to each register,
  it is convenient to include it with the Gnum so that it is strongly typed.
"""
immutable Gnum{ESS,FSS}
  lower::Unum{ESS,FSS}
  upper::Unum{ESS,FSS}

  #although there only ever needs to one scratchpad, the difficulty is that it
  #is nearly impossible to type this correctly.  We'll create the scratchpad
  #object to be tied to the Gnum calculation layer.

  scratchpad::Unum{ESS,FSS}
end

@generated function Base.zero{ESS,FSS}(t::Type{Gnum{ESS,FSS}})
  if (FSS < 7)
    :(Gnum{ESS,FSS}(zero(Unum{ESS,FSS}), zero(Unum{ESS,FSS}), zero(Unum{ESS,FSS})))
  else
    :(Gnum{ESS,FSS}(zero(Unum{ESS,FSS}), zero(Unum{ESS,FSS}),
      Unum{ESS,FSS}(z16, z16, z16, ArrayNum{FSS}(GNUM_SCRATCHPAD), z64)))
  end
end

#these g-layer values go into the scratchpad to indicate properties of the gnum.
GNUM_ONESIDED_MASK = 0x8000
#throws a bit saying this number is NaN.
GNUM_NAN_MASK  = 0x4000

#g-layer flags that apply to both "lower" and "higher" slots.
#temporary flag saying to ignore calculations on this side of the gnum.
GNUM_IGNORE_SIDE_MASK = 0x2000

#################################
#precedence of bits:
# NAN > SBIT > IGNORE
# A nan is automatically single, even if sbit isn't thrown.
# An SBIT automatically ignores the second value, even if ignore isn't thrown.

#informational flags that report on the identity of the number.
GNUM_INF_MASK  = 0x0800
GNUM_MMR_MASK  = 0x0400
GNUM_SSS_MASK  = 0x0200
GNUM_ZERO_MASK = 0x0100

#make lower and upper side designations more elegant.
const LOWER_UNUM = Val{:lower}
const UPPER_UNUM = Val{:upper}
const SCRATCHPAD = Val{:scratchpad}

#create a global scratchpad array.
const GLOBAL_SCRATCHPAD_SIZE = __cell_length(11) + (__cell_length(11) >> 1)
const GLOBAL_SCRATCHPAD = zeros(UInt64, GLOBAL_SCRATCHPAD_SIZE)

#scratches an operation.
macro scratch_this_operation!(s)
  esc(quote
    nan!(s)
    ignore_both_sides!(s)
    return
  end)
end
