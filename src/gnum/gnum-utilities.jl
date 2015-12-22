#scratches an operation.
macro scratch_this_operation!(s)
  esc(quote
    nan!(s)
    ignore_both_sides!(s)
    return
  end)
end

#testing the sbit state of the Gnum.
set_onesided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags |= GNUM_SINGLE_MASK; x)
set_twosided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags &= ~GNUM_SINGLE_MASK; x)
is_onesided{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags & (GNUM_SINGLE_MASK | GNUM_NAN_MASK) != 0)
is_twosided{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags & (GNUM_SINGLE_MASK | GNUM_NAN_MASK) == 0)

@generated function ignore_side!{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate
  :(x.$side.flags |= GNUM_IGNORE_SIDE_MASK; nothing)
end
function ignore_both_sides!{ESS,FSS}(x::Gnum{ESS,FSS})
  x.lower.flags |= GNUM_IGNORE_SIDE_MASK
  x.upper.flags |= GNUM_IGNORE_SIDE_MASK
  nothing
end
function clear_ignore_sides!{ESS,FSS}(x::Gnum{ESS,FSS})
  x.lower.flags &= ~GNUM_IGNORE_SIDE_MASK
  x.upper.flags &= ~GNUM_IGNORE_SIDE_MASK
  nothing
end
@generated function should_calculate{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  if (side == :lower)
    :((x.lower.flag & GNUM_IGNORE_SIDE_MASK) == 0)
  else
    :(((x.scratchpad.flag & GNUM_SINGLE_MASK) == 0) && ((x.upper.flag & GNUM_IGNORE_SIDE_MASK) == 0))
  end
end

function put_unum!{ESS,FSS}(src::Unum{ESS,FSS}, dest::Gnum{ESS,FSS})
  copy_unum!(src, dest.lower)
  set_flags!(dest)
  dest.scratchpad.flag |= GNUM_SINGLE_MASK
  nothing
end
function get_unum!{ESS,FSS}(src::Gnum{ESS,FSS}, dest::Unum{ESS,FSS})
  (is_twosided(src) || !is_nan(src)) && throw(ArgumentError("Error: Gnum represents a Ubound"))
  is_nan(src) && return nan(Unum{ESS,FSS})
  nothing
end

@generated function put_unum!{ESS,FSS,side}(src::Unum{ESS,FSS}, dest::Gnum{ESS,FSS}, ::Type{Val{side}})
  quote
    copy_unum!(src, dest.$side)
    set_flags!(src, Val{$side})
    nothing
  end
end

@generated function get_unum!{ESS,FSS,side}(src::Gnum{ESS,FSS}, dest::Unum{ESS,FSS}, ::Type{Val{side}})
  quote
    force_from_flags!(src, dest, Val{$side}) || copy_unum!(src.$side, dest);
    nothing
  end
end

function put_ubound!{ESS,FSS}(src::Ubound{ESS,FSS}, dest::Unum{ESS,FSS})
  #fills the Gnum data from a source Ubound.
  copy_unum!(src.lower, dest.lower)
  copy_unum!(src.upper, dest.upper)
  set_flags!(src)
  nothing
end

function get_ubound!{ESS,FSS}(src::Gnum{ESS,FSS}, dest::Ubound{ESS,FSS})
  #fills the Ubound data from a source Gnum.
  (is_nan(src) || is_onesided(src)) && throw(ArgumentError("Error:  Gnum represents a Unum"))
  #be sure to check if one of the flags is thrown before copying, otherwise
  #undefined results may occur.
  force_from_flags!(src, dest, LOWER_UNUM) || copy_unum!(src.lower, dest.lower)
  force_from_flags!(src, dest, UPPER_UNUM) || copy_unum!(src.upper, dest.upper)
  nothing
end

doc"""
  `emit_data(::Gnum{ESS,FSS})` takes the contents of a gnum and decides if it's
  represents a solo unum or a ubound.  It then allocates the appropriate type and
  emits that as a result.
"""
function emit_data!{ESS,FSS}(src::Gnum{ESS,FSS})
  #be ready to release a utype as a result.
  res::Utype
  #check to see if we're a NaN
  (src.scratchpad.flags & GNUM_NAN_MASK != 0) && return nan(Unum{ESS,FSS})
  #check to see if we're a single unum
  if (src.scratchpad.flags & GNUM_SINGLE_MASK != 0)
    #prepare the result by allocating.
    res = zero(Unum{ESS,FSS})
    #put the value in the allocated space.
    get_unum!(src, res)
  else
    #this time, we know it's a ubound.
    #prepare the result by allocating.
    res = zero(Ubound{ESS,FSS})
    #put the value in the allocated space.
    get_ubound!(src, res)
  end
  res
end
