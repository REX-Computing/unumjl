#gnum-multiplication.jl
#multiplication algorithms between unums, ubounds and gnums.

doc"""
  `mul!(::Unum, ::Gnum)` multiplies a unum INTO a gnum.
  the gnum will be altered as a result.  This function may also alter the unum
  by appending g-flags into the flags section.  Returns a reference to the
  gnum to allow chaining.
"""
function mul!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  #make sure our ignore_sides parameters are set.
  clear_ignore_sides!(b)
  #go ahead and set "g-flags" on the value a.
  set_g_flags!(a)
  #perform hard override checks on the multiply.
  __check_mul_hard_override!(a, b)

  #test sidedness and trampoline to the appropriate procedure.
  is_onesided(b) ? mul_onesided!(a, b) : mul_twosided!(a, b)
end

doc"""
  `mul!(::Ubound, ::Gnum)` multiplies a ubound INTO a gnum.
  the gnum will be altered as a result.  This function may also alter the ubound
  by appending g-flags into the flags section of the constituent unums.  Returns
  a reference to the gnum to allow chaining.
"""
function mul!{ESS,FSS}(a::Ubound{ESS,FSS}, b::Gnum{ESS,FSS})
  throw(ArgumentError("not implemented yet."))
end

doc"""
  `mul!(a::Gnum, b::Gnum)` multiplies a gnum `a` INTO a gnum `b`.
  the *second* gnum will be altered as a result.  Following at&t assembly syntax,
  the result is on the right hand side (this is the equivalent of b \*= a ).
  Returns a reference to the gnum to allow chaining.
"""
function mul!{ESS,FSS}(a::Gnum{ESS,FSS}, b::Gnum{ESS,FSS})
  throw(ArgumentError("not implemented yet."))
end

################################################################################
## onesided/twosided multiplies.

doc"""
  `mul_onesided!(::Unum, ::Gnum)` performs a multiplication of a unum a into
  a unum b, where the starting gnum is one-sided.  This function does not check
  that the passed parameters match this description.
"""
function mul_onesided!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  #all procedures in onesided multiply presume that a is positive.
  _sign_temp = z16

  if is_zero(b, LOWER_UNUM)
    ignore_side!(b, LOWER_UNUM)
  elseif is_inf(b, LOWER_UNUM)
    ignore_side!(b, LOWER_UNUM)
  elseif is_unit(b.lower)
    _sign_temp = @signof(b.lower)
    copy_unum!(a, b.lower)
    #overwrite the sign; this will be re-xored later.
    @write_sign(b.lower, _sign_temp)
    ignore_side!(b, LOWER_UNUM)
  elseif is_mmr(a)
    mmr_onesided_mult!(b)
  elseif is_sss(a)
    sss_onesided_mult!(b)
  end

  #check for the gnum value being mmr or sss.
  if should_calculate(b, LOWER_UNUM)
    if is_mmr(b, LOWER_UNUM)
      _sign_temp = @signof(b.lower)
      copy_unum!(a, b.lower)
      @write_sign(b.lower, _sign_temp)
      mmr_onesided_mult!(b)
    elseif is_sss(b, LOWER_UNUM)
      _sign_temp = @signof(b.lower)
      copy_unum!(a, b.lower)
      @write_sign(b.lower, _sign_temp)
      sss_onesided_mult!(b)
    end
  end

  #we have exhausted all of the special cases, so just do the multiplication.
  should_calculate(b, LOWER_UNUM) && __multiply!(a, b, LOWER_UNUM, UPPER_UNUM)
  #swap parity if a was negative.
  is_negative(a) && parity_swap!(b)

  #return the gnum.
  b
end

doc"""
  `mul_twosided!(::Unum, ::Gnum)` performs a multiplication of a unum a into
  a unum b, where the starting gnum is one-sided.  This function does not check
  that the passed parameters match this description.
"""
function mul_twosided!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  throw(ArgumentError("twosided mults not implemented yet"))
end

################################################################################
## shortcut multiplication, for special values.

doc"""
  `__check_mul_hard_override!(::Unum, ::Gnum)` checks to see if the terms in
  the multiplier or the multiplicand trigger a "hard override".  These values
  are:
"""
function __check_mul_hard_override!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  ############################################
  # analysis of multiplication with NaNs.
  # if our multiplicand is nan, then set the product to nan.
  is_nan(a) && (@scratch_this_operation!(b))
  is_nan(b) && (ignore_both_sides!(b); return)

  ############################################
  # analysis of multiplictaion with infs
  # inf * anything becomes inf, except zero, which becomes NaN.

  if (is_g_inf(a))
    #infinity can't multiply across zero.
    is_twosided(b) && ((b.lower.flags & UNUM_SIGN_MASK) != (b.upper.flags & UNUM_SIGN_MASK)) && (@scratch_this_operation!(b))
    #infinity can't multiply times just zero, either
    should_calculate(b, LOWER_UNUM) && is_zero(b, LOWER_UNUM) && (@scratch_this_operation!(b))
    should_calculate(b, UPPER_UNUM) && is_zero(b, LOWER_UNUM) && (@scratch_this_operation!(b))
    #set to onesided.
    inf!(b, (b.lower.flags & UNUM_SIGN_MASK), LOWER_UNUM); ignore_side!(b, LOWER_UNUM); set_onesided!(b)
  end
  #next, check that infinities on either side don't mess things up.
  if should_calculate(b, LOWER_UNUM) && is_inf(b, LOWER_UNUM)
    is_g_zero(a) && (@scratch_this_operation!(b))
    ignore_side!(b, LOWER_UNUM)
  end
  if should_calculate(b, UPPER_UNUM) && is_inf(b, UPPER_UNUM)
    is_g_zero(a) && (@scratch_this_operation!(b))
    ignore_side!(b, UPPER_UNUM)
  end

  ############################################
  # analysis of multiplictaion with zeros
  # zero * anything becomes zero.
  # n.b. this does not check inf, because that has already been checked.
  if is_g_zero(a)
    zero!(b, LOWER_UNUM)
    set_onesided!(b)
    ignore_side!(b, LOWER_UNUM)
  end

  ############################################
  # analysis of multiplictaion with unit value
  # one * anything becomes itself.

  is_unit(a) && ignore_both_sides!(b)
end

doc"""
  `sss_onesided_mult!(::Gnum)` multiplies a onesided Gnum times an sss.
"""
function sss_onesided_mult!{ESS,FSS}(b::Gnum{ESS,FSS})
  #if the magnitude is more than one, then we multiply the value of b times
  #smallsubnormal.
  if is_magnitude_less_than_one(b.lower)
    sss!(b, @signof(b.lower), LOWER_UNUM)
    ignore_side!(b, LOWER_UNUM)
  else
    #we're going to have a two-valued solution, so alias the inner and outer values.
    set_twosided!(b)
    #first, make the buffer small_exact.
    small_exact!(b.buffer, @signof(b.lower))
    #we do something different if it's negative vs. if it's positive.
    if is_negative(b.lower)
      neg_sss!(b.upper)
      __multiply!(b.buffer, b, LOWER_UNUM, DISCARD_PRIMARY)
      #check to see if we need to retrace.
      is_exact(b.lower) && __inward_ulp!(b.lower)
    else
      #we'll need to copy the value of b.lower over to b.upper
      copy_unum!(b.lower, b.upper)
      pos_sss!(b.lower)
      __multiply!(b.buffer, b, UPPER_UNUM, DISCARD_PRIMARY)
      #check to see if we need to retrace.
      is_exact(b.upper) && __inward_ulp!(b.upper)
    end
    ignore_both_sides!(b)
  end
end

doc"""
  `mmr_onesided_mult!(::Gnum)` multiplies a onesided Gnum times an mmr.
"""
function mmr_onesided_mult!{ESS,FSS}(b::Gnum{ESS,FSS})
  if is_magnitude_less_than_one(b.lower)
    #we're going to have a two-valued solution, so alias the inner and outer values.
    set_twosided!(b)
    #first, make the buffer small_exact.
    big_exact!(b.buffer, @signof(b.lower))
    #we do something different if it's negative vs. if it's positive.
    if is_negative(b.lower)
      copy_unum!(b.lower, b.upper)
      neg_mmr!(b.lower)
      __multiply!(b.buffer, b, UPPER_UNUM, DISCARD_SECONDARY)
      #check to see if we need to retrace.
      is_exact(b.lower) && __outward_ulp!(b.lower)
    else
      #we'll need to copy the value of b.lower over to b.upper
      pos_mmr!(b.upper)
      __multiply!(b.buffer, b, LOWER_UNUM, DISCARD_SECONDARY)
      #check to see if we need to retrace.
      is_exact(b.upper) && __outward_ulp!(b.upper)
    end
    ignore_both_sides!(b)
  else
    #then everything stays mmr.
    mmr!(b, @signof(b.lower), LOWER_UNUM)
    ignore_side!(b, LOWER_UNUM)
  end
end

################################################################################
## actual algorithmic multiplication

doc"""
  `Unums.__multiply!(::Unum, ::Gnum, ::Type{Val}, ::Type{Val})`
  performs the algorithmic multiplication of an unum into one side of the gnum.

  The *primary result* is the result of the exact multiplication between the two
  values; the *secondary result* is the result of multiplying the ulp values.

  The first value parameter contains the side that contains the multiplicand:
  this may be UPPER_GNUM, LOWER_GNUM, or BUFFER.

  The second value parameter contains a directive that determines what to do
  when the value is inexact.  If this is UPPER_GNUM, LOWER_GNUM, or BUFFER, then
  the secondary result is stored in the respective destination.  This destination
  cannot be identical to the first value parameter.

  You may also specify DISCARD_PRIMARY or DISCARD_SECONDARY as the directives,
  which will discard the primary or secondary results.
"""
@gen_code function __multiply!{ESS,FSS,side,directive}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS}, ::Type{Val{side}}, ::Type{Val{directive}})
  max_exp = max_exponent(ESS)
  sml_exp = min_exponent(ESS, FSS)
  min_exp = min_exponent(ESS)
  mesize = max_esize(ESS)
  mfsize = max_fsize(FSS)

  (side == directive) && throw(ArgumentError("multiply algorithm cannot send an ulp result to the same side as source"))

  @code quote
    a_exp::Int64 = decode_exp(a)
    b_exp::Int64 = decode_exp(b.$side)
    a_dev::UInt64 = is_exp_zero(a) * o64
    b_dev::UInt64 = is_exp_zero(b.$side) * o64

    @write_sign(b.scratchpad, @signof(b.$side))

    scratchpad_exp::Int64 = a_exp + b_exp + a_dev + b_dev
    #preliminary comparisons that will stop us from performing unnecessary steps.
    (scratchpad_exp > $max_exp + 1) && (@preserve_sflags b mmr!(b, b.$side.flags & UNUM_SIGN_MASK, Val{$side}); return)
    (scratchpad_exp < $sml_exp - 2) && (@preserve_sflags b sss!(b, b.$side.flags & UNUM_SIGN_MASK, Val{$side}); return)
  end

  if FSS < 6
    #fss < 6 can perform a multiplication within the existing 64-bit integer width.
    @code :(b.scratchpad.fraction = __chunk_mult_small(a.fraction, b.$side.fraction))
  elseif FSS == 6
    #fss = 6 requires access to the scratchpad array.
    @code :(nan!(b); return)
  else
    @code :(nan!(b); return)
  end

  @code quote
    #fraction multiplication:  where va is "virtual bit" that is 1 for normals or 0 for subnormals.
    #  va + a
    #  vb + b
    #  va*vb + vb * a + va * b + ab
    #
    carry::UInt64 = o64 - (a_dev | b_dev) #if both a and b are subnormal, the carry is zero.
    #note that adding the fractions back in has a cross-multiplied effect.
    (b_dev == 0) && (carry = __carried_add_frac!(carry, a, b.scratchpad))
    (a_dev == 0) && (carry = __carried_add_frac!(carry, b.$side, b.scratchpad))
    #next, do carry analysis. carry can be 0, 1, 2, or 3 at the most.
    if (carry == 0)
      #shift over the fraction as far as we need to.
      shift::Int64 = leading_zeros(b.scratchpad.fraction) + 1
      #check if we're zero.
      is_frac_zero(b.scratchpad) && (sss!(b, b.scratchpad.flags & UNUM_SIGN_MASK, Val{side}); return)
      __leftshift_frac!(b.scratchpad, shift)
      #adjust the exponent.
      scratchpad_exp -= shift
      (scratchpad_exp < $sml_exp) && (sss!(b, b.scratchpad.flags & UNUM_SIGN_MASK, Val{side}); return)
      if (scratchpad_exp < $min_exp)
        #calculate the leftshift.
        shift = $min_exp - scratchpad_exp
        __rightshift_frac_with_underflow_check!(b.scratchpad, shift)
        set_frac_bit!(b.scratchpad, shift)
        b.scratchpad.esize = $mesize
        b.scratchpad.exponent = 0
      else
        (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
      end
    else
      #promote the exponent if necessary.
      (carry > 1) && (scratchpad_exp += 1)
      if scratchpad_exp > $max_exp
        @preserve_sflags b mmr!(b, b.scratchpad.flags & UNUM_SIGN_MASK, SCRATCHPAD)
      else
        #shift things over by one since we went up in size.
        __rightshift_frac_with_underflow_check!(b.scratchpad, 1)
        #carry from the carry over into the fraction.
        (carry == 3) && set_frac_top!(b.scratchpad)
        #re-encode the exponent.
        (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
      end
      #set the carry to one
      carry = 1
    end
  end

  #if we're instructed to discard the secondary value, then simply copy over
  #the values, and we're done.
  (directive == :discard_secondary) && (@code :(copy_unum_with_gflags!(b.scratchpad, b.$side); return); return)
  #assign the destination for the secondary varibale.
  sdest = (directive == :discard_primary) ? side : directive

  @code quote
    #if both sides were exact, the result is fairly simple.  Just copy the scratchpad results
    #on over to the destination side, we don't have to do anything further.
    is_exact(a) && is_exact(b.$side) && (copy_unum_with_gflags!(b.scratchpad, b.$side); return)

    #from here on out we engage the heuristic algorithm.  The 'direct' algorithm
    #would be to do two multiplications, but it is possible to save on that
    #calculation.  The algorithm is as follows:
    # we're going to do the multiplication X1 * X2
    # X1 = (2^P1)(F1) (+) (2^(P1-U1))
    # X2 = (2^P2)(F2) (+) (2^(P2-U2))
    # X1 * X2 = 2^(P1P2)(F1F2 (+) (2^-U1)F2 + (2^-U2)F1 + 2^(-U1-U2))
    # where x (+) a ≡ x + (0, a)

    #copy the scratchpad back.
    if (is_ulp(a))
      carry = __tandem_copy_add_frac!(carry, b.$side, b.scratchpad, a.fsize)
    else
      copy_unum!(b.scratchpad, b.$side)
    end
    #copy the scratchpad back.
    if (is_ulp(b.$side))
      carry = __add_frac_with_shift!(carry, a, b.scratchpad, b.$side.fsize)
    end

    #tentatively make the fsize the maximum
    b.$side.fsize = $mfsize
    make_ulp!(b.$side)

    #reassess the carry/frac

  end
end
