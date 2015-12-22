#gnum-fracops.jl

#pass-throughs on fraction operations which make working with gnums much better.
#basically, the distinction between side-effect-less functions on UInt64s and
#side-effected functions on ArrayNum{FSS} are encapsulated.  Also, these functions
#are enabled with the possibility of choosing sides.

#encapsulation of set_bit/set_bit!
@generated function set_frac_bit!{ESS,FSS,side}(x::Gnum{ESS,FSS}, s::UInt16, ::Type{Val{side}})
  @gnum_interpolate #creates the $frc member that matches the side
  if (FSS < 6)
    :(x.$frc = set_bit(x.$frc, s); nothing)
  else
    :(set_bit!(x.$frc, s); nothing)
  end
end

@generated function set_frac_top!{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate
  if (FSS < 6)
    :(x.$frc |= 0x8000_0000_0000_0000)
  else
    :(x.$frc[1] |= 0x8000_0000_0000_0000)
  end
end

#encapsulates the problem of copying a fraction value.
@gen_code function copy_frac!{ESS,FSS,side}(a::ArrayNum{FSS}, x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate #creates the $frc member that matches the side
  for idx = 1:__cell_length(FSS)
    @code :(x.$frc.a[$idx] = a.a[$idx])
  end
  @code :(nothing)
end
@generated function copy_frac!{ESS,FSS,side}(a::UInt64, x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate #creates the $frc member that matches the side
  :(x.$frc = a; nothing)
end


@generated function __rightshift_frac_with_underflow_check!{ESS,FSS,side}(x::Gnum{ESS,FSS}, s::UInt16, ::Type{Val{side}})
  @gnum_interpolate #creates the $frc member that matches the side.
  if (FSS < 6)
    _bot_mask = mask_bot(FSS)
    _top_mask = mask_top(FSS)
    quote
      (x.$frc, x.$fl) = __rightshift_with_underflow_check(x.$frc, s, x.$fl)
      x.$fl |= (x.$frc & $_bot_mask == 0) ? z16 : UNUM_UBIT_MASK
      x.$frc &= $_top_mask
    end
  elseif (FSS == 6)
    :((x.$frc, x.$fl) = __rightshift_with_underflow_check(x.$frc, s, x.$fl))
  else
    :(x.$fl = __rightshift_with_underflow_check!(x.$frc, s, x.$fl))
  end
end

@generated function __carried_add_frac!{ESS,FSS,side}(carry, a::UInt64, x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate
  (FSS > 6) && throw(ArgumentError("FSS = $FSS > 6 requires ArrayNum"))
  quote
    x.$frc += a
    return carry + ((x.$frc < a) ? o64 : z64)
  end
end
@generated function __carried_add_frac!{ESS,FSS,side}(carry, a::ArrayNum{FSS}, x::Gnum{ESS,FSS}, ::Type{Val{side}})
  @gnum_interpolate
  (FSS < 7) && throw(ArgumentError("FSS = $FSS < 7 requires ArrayNum"))
  :(__carried_add!(carry, a, x.$frc))
end
