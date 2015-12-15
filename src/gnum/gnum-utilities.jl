@gen_code function copy_gnum!{ESS,FSS, side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})

  @gnum_interpolate

  @code quote
    #copy all data from the unum to the gnum.
    b.$fs = a.fsize
    b.$es = a.esize
    b.$fl = a.flags | GNUM_SBIT_MASK
    b.$exp = a.exponent
  end
  if (FSS < 7)
    :(b.$frc = a.fraction)
  else
    for idx=1:__cell_length(FSS)
      :(b.$frc.a[$idx] = a.fraction.a[$idx])
    end
  end
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
    for idx = 1:__cell_length(FSS)
      @code :(dest.fraction.a[$idx] = src.$frc.a[$idx])
    end
  end
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
