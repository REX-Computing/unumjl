#gnum-addition.jl
#addition algorithms between unums, ubounds and gnums.


#general exact addition algorithm.
@generated function __exact_arithmetic_addition!{ESS,FSS,side}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}})
  mesize::UInt16 = max_esize(ESS)
  mfsize::UInt16 = max_fsize(FSS)
  (FSS < 7) && (mfrac::UInt64 = mask_top(FSS))
  mexp::UInt64 = max_exponent(ESS)

  quote
    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b.$side)

    a_dev::UInt64 = is_exp_zero(a) * o64
    b_dev::UInt64 = is_exp_zero(b.$side) * o64

    #derive the "contexts" for each, which is a combination of the exponent and
    #deviation.
    a_ctx::Int64 = a_exp + a_dev
    b_ctx::Int64 = b_exp + b_dev

    #set up a placeholder for the addend.
    addend::Unum{ESS,FSS}
    shift::Int64
    carry::UInt64
    scratchpad_exp::Int64
    scratchpad_dev::UInt64
    @init_sflags()
    #check to see which context is bigger.
    if (a_ctx > b_ctx) || ((a_ctx == b_ctx) && (b_dev != z64))
      #set the placeholder to the value a.
      addend = a
      @preserve_sflags b copy_unum!(b.$side, b.scratchpad)
      #calculate shift as the difference between a and b
      shift = a_ctx - b_ctx
      #set up the carry bit.
      carry = (o64 - a_dev) + ((shift == z64) * (o64 - b_dev))
      scratchpad_exp = a_exp
      scratchpad_dev = a_dev
    else
      #set the placeholder to the value b.
      addend = b.$side
      #move the unum value to the scratchpad.
      @preserve_sflags b put_unum!(a, b, SCRATCHPAD)
      #calculate the shift as the difference between a and b.
      shift = b_ctx - a_ctx
      #set up the carry bit.
      carry = (o64 - b_dev) + ((shift == z64) * (o64 - a_dev))
      scratchpad_exp = b_exp
      scratchpad_dev = b_dev
    end

    #rightshift the scratchpad, then set the invisible bit that may have moved.
    __rightshift_frac_with_underflow_check!(b.scratchpad, shift)
    (shift != 0) && (b_dev == 0) && (set_frac_bit!(b.scratchpad, shift))

    #perform the carried add.
    carry = __carried_add_frac!(carry, addend, b.scratchpad)

    #set esize and exponent parts.
    b.scratchpad.esize = addend.esize
    b.scratchpad.exponent = addend.exponent

    if (scratchpad_dev == z64)
      #for non-subnormal things do the following:
      if (carry > 1)
        scratchpad_exp += 1
        if scratchpad_exp > $mexp
          @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)
        else
          #shift things over by one since we went up in size.
          __rightshift_frac_with_underflow_check!(b.scratchpad, 1)
          #carry from the carry over into the fraction.
          (carry == 3) && set_frac_top!(b.scratchpad)
          #re-encode the exponent.
          (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
        end
      end
    else
      #for subnormal values, we have to augment the exponent slightly differently.
      if (carry > 0)
        b.scratchpad.exponent = o64
      end
    end

    #set the fsize.
    b.scratchpad.fsize = $mfsize - min(((b.scratchpad.fsize & UNUM_UBIT_MASK != 0) ? 0 : ctz(b.scratchpad.fraction)), $mfsize)

    #another way to get overflow is: by adding just enough bits to exactly
    #make the binary value for inf or nan.  This should, instead, yield mmr.
    #nb:  the is_inf call here is the UNUM is_inf, which checks across all the
    #bits, not the gnum is_inf, which only looks at the flag in the flags holder.
    __is_nan_or_inf(b.scratchpad) && @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)
    is_mmr(b.scratchpad) && @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)

    copy_unum_with_gflags!(b.scratchpad, b.$side)
  end
end
