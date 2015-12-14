#gnum-constants.jl
#setting gnum values to unum constants.

@gen_code function __infnanset!{ESS,FSS,side}(x::Gnum{ESS,FSS}, flags::UInt16, ::Type{Val{side}})
  #pre-calculate the things that are needed.
  esize::UInt16 = max_esize(ESS)
  fsize::UInt16 = max_fsize(FSS)
  exp::UInt64 = max_biased_exponent(ESS)

  @gnum_interpolate

  @code quote
    x.$fs = $fsize
    x.$es = $esize
    x.$fl = flags
    x.$fr = $exp
  end

  if FSS < 7
    frac = mask_top(fsize)
    @code :(x.$fr_param = $frac; x)
  else
    @code :(mask_top!(x.$fr_param, $fsize); x)
  end
end

function inf!{ESS,FSS,side}(x::Gnum{ESS,FSS}, flags::UInt16, ::Type{Val{side}} = Val{:lower})
  __infnanset!(x, flags | UNUM_UBIT_MASK, Val{side})
end

function nan!{ESS,FSS,side}(x::Gnum{ESS,FSS}, flags::UInt16)
  __infnanset!(x, UNUM_UBIT_MASK | GNUM_SBIT_MASK, Val{:lower})
end

#zero! for a gnum can zero out either the upper or lower gnum, or if no side is
#passed, then it zeroes out both sides.
@gen_code function zero!{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate
  @code quote
    x.$fs = x.$es = x.$fl = z16
    x.$exp = z64
  end
  if (FSS < 7)
    @code :(x.$frc = z64)
  else
    @code :(zero!(x.$frc))
  end
end
@gen_code function zero!{ESS,FSS}(x::Gnum{ESS,FSS})
  @code quote
    x.lower_flags = x.upper_flags = x.lower_esize = x.upper_esize = x.lower_fsize = x.upper_fsize = z16
    x.lower_exponent = x.upper_exponent = z64
  end
  if (FSS < 7)
    @code :(x.lower_fraction = x.upper_fraction = z64)
  else
    @code :(zero!(x.lower_fraction); zero!(x.upper_fraction))
  end
end

@gen_code function mmr!{ESS,FSS,side}(x::Gnum{ESS,FSS}, flags::UInt16, ::Type{Val{side}})
  @gnum_interpolate

  esize   ::UInt16 = max_esize(ESS)
  fsize   ::UInt16 = max_fsize(FSS)
  fsmone  ::UInt16 = (FSS != 0) ? fsize - 1 : 0  #prevents an inexact error
  max_exp ::UInt64 = max_biased_exponent(ESS)
  @code quote
    x.$fs = $fsize
    x.$es = $esize
    x.$fs = flags
    x.$exp = $max_exp
  end

  if (FSS == 0)
    @code :(x.$frc = z64; x)
  elseif (FSS < 7)
    frac = mask_top(fsmone)
    @code :(x.$frc = $frac; x)
  else
    @code :(mask_top!(x.$frc, $fsmone); x)
  end
end

@gen_code function sss!{ESS,FSS,side}
  esize   ::UInt16 = max_esize(ESS)
  fsize   ::UInt16 = max_fsize(FSS)
  @code quote
    x.$fs = $fsize
    x.$es = $esize
    x.$fl = flags | UNUM_UBIT_MASK
    x.$exp = z64
  end

  if FSS < 7
    @code :(x.$frc = z64; x)
  else
    @code :(zero!(x.$frc); x)
  end
end
