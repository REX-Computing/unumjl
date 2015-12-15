#gnum-fracops.jl

#pass-throughs on fraction operations which make working with gnums much better.
#basically, the distinction between side-effect-less functions on UInt64s and
#side-effected functions on ArrayNum{FSS} are encapsulated.  Also, these functions
#are enabled with the possibility of choosing sides.

#encapsulation of set_bit/set_bit!
@generated function set_frac_bit!{ESS,FSS,side}(x::Gnum{ESS,FSS}, s::UInt16, Type{Val{side}} = Val{:lower})
  @gnum_interpolate #creates the $frc member that matches the side
  if (FSS < 6)
    :(x.$frc = set_bit(x.$frc, s); nothing)
  else
    :(set_bit!(x.$frc, s); nothing)
  end
end

#encapsulates the problem of copying a fraction value.
@gen_code function copy_frac!{ESS,FSS,side}(a::ArrayNum{FSS}, x::Gnum{ESS,FSS}, Type{Val{side}} = Val{:lower})
  @gnum_interpolate #creates the $frc member that matches the side
  for idx = 1:__cell_length(FSS)
    @code :(x.$frc.a[$idx] = a.a[$idx])
  end
  @code :(nothing)
end
@generated function copy_frac!{ESS,FSS,side}(a::UInt64, x::Gnum{ESS,FSS}, Type{Val{side}} = Val{:lower})
  @gnum_interpolate #creates the $frc member that matches the side
  :(x.$frc = a; nothing)
end


@generated function __rightshift_frac_with_underflow_check!{ESS,FSS,side}(x::Gnum{ESS,FSS}, s::UInt16, f::UInt16, Type{Val{side}} = Val{:lower})
  @gnum_interpolate #creates the $frc member that matches the side.
  if (FSS < 7)
    :()
  elseif (FSS == 6)
    :(ubit = __rightshift_with_underflow_check(x.$frc, s, f))
  else
    :(__rightshift_with_underflow_check(x.$frc, s, f))
end

@generated function __carried_add_frac!{ESS,FSS,side}(carry::UInt64, fraction::UInt64, x::Gnum{ESS,FSS}, Type{Val{side}} = Val{:lower})
  @gnum_interpolate #create the $frc member that matches the side.
  quote
    x.$frc += fraction
    return (x.$frc <= fraction) ? carry + 1 : carry
  end
end
@generated function __carried_add_frac!{ESS,FSS,side}(carry::UInt64, fraction::ArrayNum{FSS}, x::Gnum{ESS,FSS}, Type{Val{side}} = Val{:lower})
  @gnum_interpolate #create the $frc member that matches the side.
  :(__carried_add!(carry, fraction, x.$frc))
end
