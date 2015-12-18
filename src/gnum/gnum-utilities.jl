#testing the sbit state of the Gnum.
set_onesided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.lower_flags |= GNUM_SBIT_MASK; x)
set_twosided!{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.lower_flags &= ~GNUM_SBIT_MASK; x)
is_onesided{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.lower_flags & (GNUM_SBIT_MASK | GNUM_NAN_MASK) != 0)
is_twosided{ESS,FSS}(x::Gnum{ESS,FSS}) = (x.lower_flags & (GNUM_SBIT_MASK | GNUM_NAN_MASK) == 0)

@generated function set_ignore_side!{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate
  :(x.$fl |= GNUM_IGNORE_SIDE_MASK; nothing)
end
function ignore_both_sides!{ESS,FSS}(x::Gnum{ESS,FSS})
  x.lower_flags |= GNUM_IGNORE_SIDE_MASK
  x.upper_flags |= GNUM_IGNORE_SIDE_MASK
  nothing
end
function clear_ignore_sides!{ESS,FSS}(x::Gnum{ESS,FSS})
  x.lower_flags &= ~GNUM_IGNORE_SIDE_MASK
  x.upper_flags &= ~GNUM_IGNORE_SIDE_MASK
  nothing
end
@generated function should_calculate{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  if (side == :lower)
    :((x.lower_flag & GNUM_IGNORE_SIDE_MASK) == 0)
  else
    :(((x.lower_flag & GNUM_SBIT_MASK) == 0) && ((x.upper_flag & GNUM_IGNORE_SIDE_MASK) == 0))
  end
end

@gen_code function put_unum!{ESS,FSS, side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})

  @gnum_interpolate

  @code quote
    #copy all data from the unum to the gnum.
    b.$fs = a.fsize
    b.$es = a.esize
    b.$fl = a.flags | GNUM_SBIT_MASK
    b.$exp = a.exponent
  end
  if (FSS < 7)
    @code :(b.$frc = a.fraction)
  else
    for idx=1:__cell_length(FSS)
      @code :(b.$frc.a[$idx] = a.fraction.a[$idx])
    end
  end
  @code :(nothing)
end

@gen_code function get_unum!{ESS,FSS,side}(src::Gnum{ESS,FSS}, dest::Unum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate

  @code quote
    dest.fsize = src.$fs
    dest.esize = src.$es
    dest.flags = src.$fl & (~GNUM_SBIT_MASK)
    dest.exponent = src.$exp
  end
  if (FSS < 7)
    @code :(dest.fraction = src.$frc)
  else
    @code :(copy_data!(src.$frc, dest.fraction))
  end
  @code :(nothing)
end

#DEFINE A QUICK MACRO THAT MAKES TRANSFERRING DATA in the next function painless.
macro srcdest(fields::Array{Symbol,1})
  q = :()
  for s in fields
    ls = symbol(:lower_, s)
    us = symbol(:upper_, s)
    quote
      $q
      dest.lower.$s = src.$ls
      dest.upper.$s = src.$us
    end
  end
  esc(q)
end

@gen_code function get_ubound!{ESS,FSS}(src::Gnum{ESS,FSS}, dest::Ubound{ESS,FSS})
  #transfer most of the fields
  @code :(@srcdest [:fsize, :esize, :flags, :exponent])
  if (FSS < 7)
    #we only have an int64 so a raw transfer is fine.
    @code :(@srcdest [:fraction])
  else
    #unroll and reach into the array.
    for idx = 1:__cell_length(FSS)
      @code quote
        dest.lower.fraction[$idx] = src.lower_fraction[$idx]
        dest.upper.fraction[$idx] = src.upper_fraction[$idx]
      end
    end
  end
end

doc"""
  `emit_data(::Gnum{ESS,FSS})` takes the contents of a gnum and decides if it's
  represents a solo unum or a ubound.  It then allocates the appropriate type and
  emits that as a result.
"""
function emit_data{ESS,FSS}(src::Gnum{ESS,FSS})
  if (src.lower_flags & GNUM_SBIT_MASK != 0)
    #then we are a single unum result.
    ures::Unum{ESS,FSS} = zero(Unum{ESS,FSS})
    get_unum!(src, ures, Val{:lower})
    return ures
  else
    bres::Ubound{ESS,FSS} = zero(Ubound{ESS,FSS})
    get_ubound!(src, bres)
    return bres
  end
end
