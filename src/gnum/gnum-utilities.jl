#testing the sbit state of the Gnum.
<<<<<<< HEAD
set_onesided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.lower.flags |= GNUM_ONESIDED_MASK; x)
set_twosided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.lower.flags &= ~GNUM_ONESIDED_MASK; x)
is_onesided{ESS,FSS}(x::Gnum{ESS,FSS}) = ((x.lower.flags & GNUM_ONESIDED_MASK != 0) || (is_nan(x)))
is_twosided{ESS,FSS}(x::Gnum{ESS,FSS}) = ((x.lower.flags & GNUM_ONESIDED_MASK == 0) && (!is_nan(x)))
=======
set_onesided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags |= GNUM_SINGLE_MASK; x)
set_twosided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags &= ~GNUM_SINGLE_MASK; x)
is_onesided{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags & (GNUM_SINGLE_MASK | GNUM_NAN_MASK) != 0)
is_twosided{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.scratchpad.flags & (GNUM_SINGLE_MASK | GNUM_NAN_MASK) == 0)
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8

#the ignore_side utility is used for operations that do identity checks before
#proceeding with calculations, and flags that a side has already been checked
#and should not be altered.  the `should_calculate` directive runs this downstream
@generated function ignore_side!{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
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
#reports on whether or not the side referred to should be calculated.
@generated function should_calculate{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  if (side == :lower)
    :((x.lower.flags & GNUM_IGNORE_SIDE_MASK) == 0)
  else
<<<<<<< HEAD
    :(is_twosided(x) && ((x.upper.flags & GNUM_IGNORE_SIDE_MASK) == 0))
=======
    :(((x.scratchpad.flags & GNUM_SINGLE_MASK) == 0) && ((x.upper.flags & GNUM_IGNORE_SIDE_MASK) == 0))
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
  end
end

function put_unum!{ESS,FSS}(src::Unum{ESS,FSS}, dest::Gnum{ESS,FSS})
  #puts a unum into the gnum, assuming it is going to be a single-sided unum.
  copy_unum!(src, dest.lower)
  set_flags!(dest, LOWER_UNUM)
<<<<<<< HEAD
  set_onesided!(dest)
=======
  dest.scratchpad.flags |= GNUM_SINGLE_MASK
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
  nothing
end

function get_unum!{ESS,FSS}(src::Gnum{ESS,FSS}, dest::Unum{ESS,FSS})
  #puts a unum into the gnum, assuming it already is a single-sided unum.
<<<<<<< HEAD
  (is_twosided(src) && !is_nan(src)) && throw(ArgumentError("Error: Gnum represents a Ubound"))
=======
  (is_twosided(src) || !is_nan(src)) && throw(ArgumentError("Error: Gnum represents a Ubound"))
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
  is_nan(src) && return nan(Unum{ESS,FSS})
  force_from_flags!(src, dest, LOWER_UNUM) || copy_unum!(src.lower, dest)
  nothing
end

@generated function put_unum!{ESS,FSS,side}(src::Unum{ESS,FSS}, dest::Gnum{ESS,FSS}, ::Type{Val{side}})
  #sets the unum value on either side of the Gnum (or possibly the scratchpad.)
  quote
    copy_unum!(src, dest.$side)
    set_flags!(dest, Val{side})
    nothing
  end
end

@generated function get_unum!{ESS,FSS,side}(src::Gnum{ESS,FSS}, dest::Unum{ESS,FSS}, ::Type{Val{side}})
  #retrieves the unum value from either side of the Gnum (or possibly the scratchpad.)
  quote
    force_from_flags!(src, dest, Val{$side}) || copy_unum!(src.$side, dest);
    nothing
  end
end

function put_ubound!{ESS,FSS}(src::Ubound{ESS,FSS}, dest::Gnum{ESS,FSS})
  #fills the Gnum data from a source Ubound.
  copy_unum!(src.lower, dest.lower)
  copy_unum!(src.upper, dest.upper)
  set_flags!(dest)
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
  `set_flags(::Gnum{ESS,FSS}, ::Type{Val{side}})` sets flags on one side of the
  gnum by examining the value.
"""
@generated function set_flags!{ESS,FSS,side}(v::Gnum{ESS,FSS}, ::Type{Val{side}})
<<<<<<< HEAD
=======
  println("what is up here $side")
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
  quote
    is_nan(v.$side) && (v.scratchpad.flags |= GNUM_NAN_MASK; return)
    is_inf(v.$side) && (v.$side.flags |= GNUM_INF_MASK; return)
    is_mmr(v.$side) && (v.$side.flags |= GNUM_MMR_MASK; return)
    is_sss(v.$side) && (v.$side.flags |= GNUM_SSS_MASK; return)
    is_zero(v.$side) && (v.$side.flags |= GNUM_ZERO_MASK; return)
  end
end


doc"""
  `emit_data(::Gnum{ESS,FSS})` takes the contents of a gnum and decides if it's
  represents a solo unum or a ubound.  It then allocates the appropriate type and
  emits that as a result.
"""
<<<<<<< HEAD
function emit_data{ESS,FSS}(src::Gnum{ESS,FSS})
  #be ready to release a utype as a result.
  res::Utype
  #check to see if we're a NaN
  (src.scratchpad.flags & GNUM_ONESIDED_MASK != 0) && return nan(Unum{ESS,FSS})
  #check to see if we're a single unum
  if (is_onesided(src))
=======
function emit_data!{ESS,FSS}(src::Gnum{ESS,FSS})
  #be ready to release a utype as a result.
  res::Utype
  #check to see if we're a NaN
  (src.scratchpad.flags & GNUM_NAN_MASK != 0) && return nan(Unum{ESS,FSS})
  #check to see if we're a single unum
  if (src.scratchpad.flags & GNUM_SINGLE_MASK != 0)
>>>>>>> 8c38c19ff2565364afda9fd9b858e63545e3add8
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
