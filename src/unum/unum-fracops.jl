#unum-fracops.jl

#pass-throughs on fraction operations which make working with unums much better.
#basically, the distinction between side-effect-less functions on UInt64s and
#side-effected functions on ArrayNum{FSS} are encapsulated.

#encapsulation of set_bit/set_bit!
@generated function set_frac_bit!{ESS,FSS}(x::Unum{ESS,FSS}, s::Int64)
  if (FSS < 7)
    :(x.fraction = set_bit(x.fraction, s); nothing)
  else
    :(set_bit!(x.fraction, s); nothing)
  end
end

@generated function set_frac_top!{ESS,FSS}(x::Unum{ESS,FSS})
  if (FSS < 7)
    :(x.fraction |= t64)
  else
    :(x.fraction[1] |= t64)
  end
end

doc"""
  `Unums.is_top_frac_bit_zero(::Unum)` reports whether or not the top bit in the
  fraction is zero.
"""
@generated function is_top_frac_bit_zero{ESS,FSS}(x::Unum{ESS,FSS})
  if (FSS < 7)
    :(x.fraction & t64 == 0)
  else
    :(x.fraction[1] & t64 == 0)
  end
end

#encapsulates the problem of copying a fraction value.
@gen_code function copy_frac!{ESS,FSS}(a::ArrayNum{FSS}, x::Gnum{ESS,FSS})
  #do an assertion to make sure that FSS matches the type.
  FSS < 7 && throw(ArgumentError("FSS = $FSS < 7 must copy_frac! using a Uint64."))
  for idx = 1:__cell_length(FSS)
    @code :(x.fraction.a[$idx] = a.a[$idx])
  end
  @code :(nothing)
end

@generated function copy_frac!{ESS,FSS}(a::UInt64, x::Gnum{ESS,FSS})
  FSS > 6 && throw(ArgumentError("FSS = $FSS > 6 must copy_frac! using an ArrayNum"))
  :(x.fraction = a; nothing)
end

@generated function __zero_frac!{ESS,FSS}(x::Unum{ESS,FSS})
  if (FSS < 6)
    :(x.fraction = z64)
  else
    :(x.fraction = zero(ArrayNum{FSS}))
  end
end

__leftshift_frac!{ESS,FSS}(x::Unum{ESS,FSS}, s::UInt16) = __leftshift_frac!(x, Int64(s))
@generated function __leftshift_frac!{ESS,FSS}(x::Unum{ESS,FSS}, s::Int64)
  if (FSS < 7)
    :(x.fraction <<= s)
  else
    :(lsh!(x.fraction))
  end
end

@generated function __rightshift_frac_with_underflow_check!{ESS,FSS}(x::Unum{ESS,FSS}, s::Int64)
  if (FSS < 6)
    _bot_mask = mask_bot(FSS)
    _top_mask = mask_top(FSS)
    quote
      (x.fraction, x.flags) = __rightshift_with_underflow_check(x.fraction, s, x.flags)
      x.flags |= (x.fraction & $_bot_mask == 0) ? z16 : UNUM_UBIT_MASK
      x.fraction &= $_top_mask
    end
  elseif (FSS == 6)
    :((x.fraction, x.flags) = __rightshift_with_underflow_check(x.fraction, s, x.flags))
  else
    :(x.flags = __rightshift_with_underflow_check!(x.fraction, s, x.flags))
  end
end

@generated function __carried_add_frac!{ESS,FSS}(carry::UInt64, a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  if (FSS < 7)
    quote
      b.fraction = a.fraction + b.fraction
      carry + ((b.fraction < a.fraction) ? o16 : z16)
    end
  else
    :(__carried_add!(carry, a.fraction, b.fraction))
  end
end

@generated function __carried_diff_frac!{ESS,FSS}(carry::UInt64, a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #NB at some point this is going to need to do something about the ULP.
  if (FSS < 7)
    quote
      b.fraction = a.fraction - b.fraction
      carry - ((b.fraction > a.fraction) ? o16 : z16)
    end
  else
    :(__carried_diff!(carry, a.fraction, b.fraction))
  end
end

@generated function __add_ubit_frac!{ESS,FSS}(a::Unum{ESS,FSS})
  #NB at some point this is going to need to do something about the ULP.
  if (FSS < 7)
    :(is_ulp(a) && ((promoted::Bool, a.fraction) = __add_ubit(a.fraction, a.fsize); promoted))
  else
    :(is_ulp(a) && __add_ubit!(a.fraction, a.fsize))
  end
end


doc"""
  `Unums.__tandem_copy_add_frac!(data::Unum, scratchpad::Unum, shift::Int64)`
  adds the value in data to scratchpad incurring the specified rightshift, while
  at the same time copying the value of scratchpad back into the data variable.
  This is done without heap allocation in the FSS >= 6 case.
"""
@gen_code function __tandem_copy_add_frac!{ESS,FSS}(carry::UInt64, data::Unum{ESS,FSS}, scratchpad::Unum{ESS,FSS}, shift::UInt16)
  if (FSS < 6)
    @code quote
      __temp_scratchpad::UInt64 = scratchpad.fraction
      scratchpad.fraction += data.fraction >> shift
      #then do the top bit.
      scratchpad.fraction += (t64 >> shift) * (!is_exp_zero(data))
      data.fraction = __temp_scratchpad
      carry += (scratchpad.fraction < __temp_scratchpad) * o64
    end
  else
    throw(ArgumentError("FSS >= 6 not supported yet."))
  end
end

doc"""
  `Unums.__add_frac_with_shift!(data::Unum, scratchpad::Unum, shift::Int64)`
  adds the value in data's fraction to the scratchpad incurring the specified rightshift.
  This is done without heap allocation in the FSS >= 6 case.
"""
@gen_code function __add_frac_with_shift!{ESS,FSS}(carry::UInt64, data::Unum{ESS,FSS}, scratchpad::Unum{ESS,FSS}, shift::UInt16)
  if (FSS < 6)
    @code quote
      old_fraction = scratchpad.fraction
      scratchpad.fraction += data.fraction >> shift
      #then do the top bit.
      scratchpad.fraction += (t64 >> shift) * (!is_exp_zero(data))
      carry += (scratchpad.fraction < old_fraction) * o64
    end
  else
    throw(ArgumentError("FSS >= 6 not supported yet."))
  end
end
