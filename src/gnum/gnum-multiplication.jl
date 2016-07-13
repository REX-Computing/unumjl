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

  #ascertain t he result sign
  result_sign::UInt16 = @signof(a) $ @signof(b.lower)

  #perform hard override checks on the multiply.
  __check_mul_hard_override!(a, b)

  #test sidedness and trampoline to the appropriate procedure.
  is_onesided(b) ? mul_onesided!(a, b) : mul_twosided!(a, b)

  (result_sign != 0) && additive_inverse!(b)
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

  if is_zero(b, LOWER_UNUM)
    ignore_side!(b, LOWER_UNUM)
  elseif is_inf(b, LOWER_UNUM)
    b.lower.flags &= ~UNUM_SIGN_MASK
    ignore_side!(b, LOWER_UNUM)
  elseif should_calculate(b, LOWER_UNUM) && is_unit(b.lower)
    copy_unum!(a, b.lower)
    #overwrite the sign; this will be re-xored later.
    b.lower.flags &= ~UNUM_SIGN_MASK
    ignore_side!(b, LOWER_UNUM)
  elseif is_mmr(a)
    should_calculate(b, LOWER_UNUM) && mmr_onesided_mult!(b)
  elseif is_sss(a)
    should_calculate(b, LOWER_UNUM) && sss_onesided_mult!(b)
  end

  #check for the gnum value being mmr or sss.
  if should_calculate(b, LOWER_UNUM)
    if is_mmr(b, LOWER_UNUM)
      copy_unum!(a, b.lower)
      mmr_onesided_mult!(b)
    elseif is_sss(b, LOWER_UNUM)
      copy_unum!(a, b.lower)
      sss_onesided_mult!(b)
    end
  end

  #we have exhausted all of the special cases, so just do the multiplication.
  should_calculate(b, LOWER_UNUM) && (__multiply!(a, b, LOWER_UNUM, UPPER_UNUM))
  #swap parity if a was negative.

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

  nan (multiplier, multiplicand) -> outputs nan
  inf (multiplier, multiplicand) -> outputs inf (unless other value is zero)
  zero (multiplier, multiplicand) -> outputs zero (unless other value is inf)
  one (multiplier, multiplicand) -> leaves value unchanged.
"""
function __check_mul_hard_override!{ESS,FSS}(a::Unum{ESS,FSS}, b::Gnum{ESS,FSS})
  ############################################
  # analysis of multiplication with NaNs.
  # if our multiplicand is nan, then set the product to nan.
  is_nan(a) && (@scratch_this_operation!(b); return)
  is_nan(b) && (ignore_both_sides!(b); return)

  ############################################
  # analysis of multiplictaion with infs
  # inf * anything becomes inf, except zero, which becomes NaN.

  if (is_g_inf(a))
    #infinity can't multiply across zero.
    is_twosided(b) && ((b.lower.flags & UNUM_SIGN_MASK) != (b.upper.flags & UNUM_SIGN_MASK)) && (@scratch_this_operation!(b))
    #infinity can't multiply times just zero, either
    should_calculate(b, LOWER_UNUM) && is_zero(b, LOWER_UNUM) && (@scratch_this_operation!(b))
    should_calculate(b, UPPER_UNUM) && is_zero(b, UPPER_UNUM) && (@scratch_this_operation!(b))
    #set to onesided.
    inf!(b, z16, LOWER_UNUM);
    ignore_side!(b, LOWER_UNUM); set_onesided!(b)
  end
  #next, check that infinities on either side don't mess things up.
  #if our lower value was infinity, then the whole thing must be infinity.
  if should_calculate(b, LOWER_UNUM) && is_inf(b, LOWER_UNUM)
    is_g_zero(a) && (@scratch_this_operation!(b))
    inf!(b, z16, LOWER_UNUM)
    #ignore it then set to onesided (although really it shouldn't be twosided)
    ignore_side!(b, UPPER_UNUM); set_onesided!(b)
  end
  #on the upper side we must consider the possibility that there are other numbers below.
  if should_calculate(b, UPPER_UNUM) && is_inf(b, UPPER_UNUM)
    is_g_zero(a) && (@scratch_this_operation!(b))
    inf!(b, z16, UPPER_UNUM)
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

  is_unit(a) && (abs!(b.lower); abs!(b.upper); ignore_both_sides!(b))
end

doc"""
  `sss_onesided_mult!(::Gnum)` multiplies a onesided Gnum times an sss.
  the lower value of the Gnum contains the value to be multiplied.  The upper
  value will contain the result value.
"""
function sss_onesided_mult!{ESS,FSS}(b::Gnum{ESS,FSS})
  #if the magnitude is more than one, then we multiply the value of b times
  #smallsubnormal.
  if is_magnitude_less_than_one(b.lower)
    sss!(b, z16, LOWER_UNUM)
    ignore_side!(b, LOWER_UNUM)
  else
    #we're going to have a two-valued solution, so alias the inner and outer values.
    set_twosided!(b)
    #first, make the upper part small_exact.
    small_exact!(b.upper, z16)
    __outward_exact!(b.lower)
    #do the multiplication
    __multiply!(b.lower, b, UPPER_UNUM, DISCARD_SECONDARY)
    #check to see if we need to retrace.
    is_exact(b.upper) && __inward_ulp!(b.upper)
    #set the lower unum to be small subnormal.
    sss!(b, z16, LOWER_UNUM)
    #finished with calculations.
    ignore_both_sides!(b)
  end
end

doc""" `mmr_onesided_mult!(::Gnum)` multiplies a onesided Gnum times an mmr."""
function mmr_onesided_mult!{ESS,FSS}(b::Gnum{ESS,FSS})
  if is_magnitude_less_than_one(b.lower)
    #we're going to have a two-valued solution, so alias the inner and outer values.
    set_twosided!(b)
    #first, make the buffer big_exact.
    big_exact!(b.buffer, z16)
    #multiply the buffer times the value in the lower unum, overwriting it.
    __multiply!(b.buffer, b, LOWER_UNUM, DISCARD_SECONDARY)
    #check to see if we need to retrace.
    is_exact(b.lower) && make_ulp!(b.lower)
    #make the upper side mmr.
    mmr!(b, z16, UPPER_UNUM)
    ignore_both_sides!(b)
  else
    #then everything stays mmr.
    mmr!(b, z16, LOWER_UNUM)
    ignore_side!(b, LOWER_UNUM)
  end
end

################################################################################
## actual algorithmic multiplication

doc"""
  `Unums.__multiply!(::Unum, ::Gnum, ::Type{Val}, ::Type{Val})`
  performs the algorithmic multiplication of an unum into one side of the gnum.
  Because a unum muliplication times another unum must always be on the same
  side of zero, this procedure ignores sign, always returning a positive value.

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

    #make the result positive
    b.scratchpad.flags &= ~UNUM_SIGN_MASK

    scratchpad_exp::Int64 = a_exp + b_exp + a_dev + b_dev

    #preliminary comparisons that will stop us from performing unnecessary steps.
    (scratchpad_exp > $max_exp + 1) && (@preserve_sflags b mmr!(b, z16, Val{side}); return)
    (scratchpad_exp < $sml_exp - 2) && (@preserve_sflags b sss!(b, z16, Val{side}); return)
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
    carry::UInt64 = o64 - (a_dev | b_dev) #if either a or b are subnormal, the carry is zero.
    #note that adding the fractions back in has a cross-multiplied effect.
    (b_dev == 0) && (carry = __carried_add_frac!(carry, a, b.scratchpad))
    (a_dev == 0) && (carry = __carried_add_frac!(carry, b.$side, b.scratchpad))

    #next, do carry analysis. carry can be 0, 1, 2, or 3 at the most.
    if (carry == 0)
      #shift over the fraction as far as we need to.
      shift::Int64 = leading_zeros(b.scratchpad.fraction) + 1
      #check if we're zero.
      is_frac_zero(b.scratchpad) && (sss!(b, z16, Val{side}); return)
      __leftshift_frac!(b.scratchpad, shift)
      #adjust the exponent.
      scratchpad_exp -= shift
      (scratchpad_exp < $sml_exp) && (sss!(b, z16, Val{side}); return)
      if (scratchpad_exp < $min_exp)
        #calculate the leftshift.
        shift = $min_exp - scratchpad_exp
        __rightshift_frac_with_underflow_check!(b.scratchpad, shift)
        set_frac_bit!(b.scratchpad, shift)
        b.scratchpad.esize = $mesize
        b.scratchpad.exponent = 0
      else
        (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
        carry = 1
      end
    elseif (carry == 1)
      if scratchpad_exp > $max_exp
        @preserve_sflags b (mmr!(b, z16, Val{side}); return)
      end
      (b.scratchpad.esize, b.scratchpad.exponent) = encode_exp(scratchpad_exp)
    else
      (scratchpad_exp += 1)
      if scratchpad_exp > $max_exp
        @preserve_sflags b (mmr!(b, z16, Val{side}); return)
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
  (directive == :discard_secondary) && (@code :(copy_unum_with_gflags!(b.scratchpad, b.$side); return); @goto __mult_end)
  #assign the destination for the secondary varibale.
  sdest = (directive == :discard_primary) ? side : directive
  #this code ge
  retrace_code1 = (directive == :discard_primary) ? :(nothing) : :(carry = __tandem_copy_add_frac!(carry, b.$side, b.scratchpad, a.fsize))
  retrace_code2 = (directive == :discard_primary) ? :(nothing) : :(copy_unum!(b.scratchpad, b.$side))
  needs_twosided = (sdest == :upper) ? (:(set_twosided!(b))) : :(nothing)
  #if we're writing to the lower side, then be prepared to collapse an mmr into a onesided.
  mmr_collapse = (side == :lower) && !(directive == :discard_primary) ? :(set_onesided!(b)) : :(nothing)

  @code quote
    #if both sides were exact, the result is fairly simple.  Just copy the scratchpad results
    #on over to the destination side, we don't have to do anything further.

    is_exact(a) && is_exact(b.$side) && (copy_unum_with_gflags!(b.scratchpad, b.$side); return)
    $needs_twosided

    #the scratchpad needs to be exact, but as a temporary shim we need to make
    #it an ulp to assess if the result is mmr.
    make_ulp!(b.scratchpad)
    is_mmr(b.scratchpad) && ($mmr_collapse; mmr!(b, z16, Val{side}); return)
    make_exact!(b.scratchpad)

#    println("a: ", bits(a))
#    println("1) scr: ", bits(b.scratchpad), " carry: ", carry)

    #from here on out we engage the heuristic algorithm.  The 'direct' algorithm
    #would be to do two multiplications, but it is possible to save on that
    #calculation.  The algorithm is as follows:
    # we're going to do the multiplication X1 * X2
    # X1 = (2^P1)(F1) (+) (2^(P1-U1))
    # X2 = (2^P2)(F2) (+) (2^(P2-U2))
    # X1 * X2 = 2^(P1P2)(F1F2 (+) (2^-U1)F2 + (2^-U2)F1 + 2^(-U1-U2))
    # where x (+) a ≡ x + (0, a)

    #copy the scratchpad back, and add into the scratchpad b.$side.fraction >> a.fsize
    (is_ulp(a)) ? $retrace_code1 : $retrace_code2


#    println("2) scr: ", bits(b.scratchpad), " carry: ", carry)
    #add into the scratchpad a.fraction >> b.$side.fsize
    (is_ulp(b.$side)) && (carry = __add_frac_with_shift!(carry, a, b.scratchpad, b.$side.fsize))
    #check to make sure the far value isn't exact; move it inward if so.

    #tentatively make the fsize the maximum
    b.$side.fsize = $mfsize

    #resolve the scratchpad's carry
    __carry_resolve!(carry, b.scratchpad, Val{true})

    is_exact(b.scratchpad) && __inward_ulp!(b.scratchpad)

    #move the scratchpad back to the destination
    copy_unum!(b.scratchpad, b.$sdest)
  end

  @label __mult_end
end
