#unum-oddsandends.jl
#mathematical odds and ends

#literally calculate the value of the Unum.  Please don't use this for Infs and NaNs
__arraynumval(x::UInt64) = x
function __arraynumval{FSS}(v::ArrayNum{FSS})
  (typeof(v) == UInt64) && return big(v)
  sum = big(0)
  for i = 1:length(v.a)
    sum += big(v.a[i]) * (big(1) << ((i - 1) * 64))
  end
  sum
end

function calculate{ESS,FSS}(x::Unum{ESS,FSS})
  sign = (x.flags & UNUM_SIGN_MASK != 0) ? -1 : 1
  #the sub`normal case
  if (x.exponent == 0)
    2.0^(decode_exp(x) + 1) * sign * (__arraynumval(x.fraction)) / 2.0^(64 * length(x.fraction))
  else #the normalcase
    2.0^(decode_exp(x)) * sign * (1 + __arraynumval(x.fraction) / 2.0^(64 * length(x.fraction)))
  end
end
export calculate

doc"""
  `additiveinverse!` creates the additive inverse value of a unum, by flipping
  the sign.  This can be better than the `-` operator because it doesn't copy
  the unum.  A reference to the unum is returned.
"""
function additiveinverse!{ESS,FSS}(x::Unum{ESS,FSS})
  x.flags $= UNUM_SIGN_MASK
  x
end
export additiveinverse!

@gen_code function copy_unum!{ESS,FSS}(src::Unum{ESS,FSS}, dest::Unum{ESS,FSS})
  @code quote
    dest.fsize = src.fsize
    dest.esize = src.esize
    dest.flags = src.flags & UNUM_FLAG_MASK
    dest.exponent = src.exponent
  end

  if FSS < 7
    @code :(dest.fraction = src.fraction)
  else
    for idx = 1:__cell_length(FSS)
      @code :(@inbounds dest.fraction[$idx] = src.fraction[$idx])
    end
  end
end

doc"""
  Unums.match_fsize!{ESS,FSS} takes the location of fsize and moves it over to dest.

  The exponent on src should less than or equal to the exponent on dest.
"""
function match_fsize!{ESS,FSS}(src::Unum{ESS,FSS}, dest::Unum{ESS,FSS})
  src_exp::Int64 = decode_exp(src)
  dest_exp::Int64 = decode_exp(dest)
  dest.fsize = UInt16(min(src.fsize + dest_exp - src_exp, max_fsize(FSS)))
end
#=
#note the difference between "more/less", and "next/prev" - next/prev refers
#to position along the number line, "more/less" refers to magnitude along the
#number line.  NB:  __bigger_exact and __smaller_exact do *not* perform checks
#on the properties of their passed values so should be used with caution.

function __outward_exact{ESS,FSS}(a::Unum{ESS,FSS})
  #set the location of the added bit:  remember that fsize is the actual length - 1
  location = (is_ulp(a)) ? a.fsize + 1 : max_fsize(FSS)
  #generate a new superint that represents what we're going to add in.
  delta = __bit_from_top(location, length(a.fraction))
  #add the delta in, making it a
  (carry, fraction) = __carried_add(z64, a.fraction, delta)

  #check the two cases.
  if (carry != 0)
    (esize, exponent) = encode_exp(decode_exp(a) + 1)
    fraction = lsh(fraction, o16)
  else
    esize = a.esize
    exponent = a.exponent
  end
  #recalculate fsize, since this is exact, we can deal with ULPs as needed.
  fsize::UInt16 = __minimum_data_width(fraction)

  Unum{ESS,FSS}(fsize, esize, a.flags & UNUM_SIGN_MASK, fraction, exponent)
end
=#

function __resolve_subnormal!{ESS,FSS}(a::Unum{ESS,FSS})
  #resolves a unum with an "unusual exponent", i.e. when esize is not
  #max_esize.  This is an "unsafe" operation, in that it does not check
  #if the passed value is actually subnormal, or that esize isn't pushed to the brim.
  _aexp::Int64 = decode_exp(a)
  #don't forget to add one, because in theory we're going to want to move that
  #first one PAST the left end of the fraction value.
  _ashl::UInt16 = clz(a.fraction) + 1

  is_zero(a) && return

  if (_aexp - _ashl) >= min_exponent(ESS)
    (a.esize, a.exponent) = encode_exp(_aexp - _ashl + 1) #don't forget the +1 because decode_exp on a subnormal is
    #one off of the actual exponent.
    #constrain the fsize to zero.
    a.fsize = (_ashl > a.fsize) ? 0 : a.fsize - _ashl

    __leftshift_frac!(a, _ashl)
  else  #then all we have to do is encode it as the deeper exponent.
    #reassign _ashl to be the most we can shift it over.
    _ashl = _aexp - min_exponent(ESS) + 1
    #take care of the corner case where thete's a single one that we're disappearing
    if (a.fsize + 1 == _ashl)
      a.fsize = z16
      a.esize = max_esize(ESS)
      a.exponent = z64
      __zero_frac!(a)
    else
      a.fsize = (a.fsize - _ashl)
      a.esize = max_esize(ESS)
      __leftshift_frac!(a, _ashl)
      a.exponent = z64
    end
  end
  a
end

#=
function __inward_exact{ESS,FSS}(a::Unum{ESS,FSS})
  #TODO:  throw in a zero check here.  Maybe?
  l::UInt16 = length(a.fraction)
  if (is_ulp(a))
    #all we have to do is strip the ubit mask.
    unum_unsafe(a, a.flags & ~UNUM_UBIT_MASK)
  else
    #check if it's a subnormal number.  If so, try to move it to the right.
    #resolve a from (possibly inoptimal subnormal) to optimal subnormal or normal
    is_exp_zero(a) && (a = __resolve_subnormal(a))

    #the next step is pretty trivial.  First, check if a is all zeros.
    if is_frac_zero(a)
      #in which case just make it a bunch of ones, decrement the exponent, and
      #make sure we aren't subnormal, in which case, we just encode as subnormal.
      _aexp::Int64 = decode_exp(a)
      fraction::VarInt = fillbits(-(max_fsize(FSS) + 1), l)
      fsize::UInt16 = max_fsize(FSS)
      (esize, exponent) = (_aexp == min_exponent(ESS)) ? (max_esize(ESS), z64) : encode_exp(_aexp - 1)
    else
      #even easier.  Just do a direct subtraction.
      fraction = a.fraction - __bit_from_top(max_fsize(FSS) + 1, l)
      #don't forget to trim it down.
      fraction &= __frac_mask(FSS)
      fsize = __minimum_data_width(a.fraction)
      esize = a.esize
      exponent = a.exponent
    end
    Unum{ESS,FSS}(fsize, esize, a.flags & UNUM_SIGN_MASK, fraction, exponent)
  end
end

#next_exact and last_exact operate on the number line as a well-ordered set, so
#they function to run tests on the input and then, if appropriate, pass to the
#repsecting more/less function.  Because these have input tests, they are exported
#and don't have the doubleunderscore prefix.
function next_exact{ESS,FSS}(x::Unum{ESS,FSS})
  is_neg_inf(x) && return neg_maxreal(Unum{ESS,FSS})
  is_zero(x) && return pos_sss(Unum{ESS,FSS})
  is_pos_mmr(x) && return pos_inf(Unum{ESS,FSS})
  is_pos_inf(x) && return nan(Unum{ESS,FSS})
  return (x.flags & UNUM_SIGN_MASK != 0) ? __inward_exact(x) : __outward_exact(x)
end

function prev_exact{ESS,FSS}(x::Unum{ESS,FSS})
  is_neg_inf(x) && return nan(Unum{ESS,FSS})
  is_neg_mmr(x) && return neg_inf(Unum{ESS,FSS})
  is_zero(x) && return neg_sss(Unum{ESS,FSS})
  is_pos_inf(x) && return maxreal(Unum{ESS,FSS})
  return (x.flags & UNUM_SIGN_MASK != 0) ? __outward_exact(x) : __inward_exact(x)
end

export next_exact, prev_exact

#upper_bound and lower_bound operate on the number line as a well-ordered set, so
#they function to run tests on the input and then, if appropriate, pass to the
#repsecting more/less function.

function upper_bound{ESS,FSS}(x::Unum{ESS,FSS})
  is_exact(x) && return x
  return (x.flags & UNUM_SIGN_MASK != 0) ? unum_unsafe(x, x.flags & (~UNUM_UBIT_MASK)) : __outward_exact(x)
end

function lower_bound{ESS,FSS}(x::Unum{ESS,FSS})
  is_exact(x) && return x
  return (x.flags & UNUM_SIGN_MASK != 0) ? __outward_exact(x) : unum_unsafe(x, x.flags & (~UNUM_UBIT_MASK))
end

export upper_bound, lower_bound

function outward_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_ulp(x) && throw(ArgumentError("function only for exact numbers"))
  #note that infinity will throw NAN, which is just fine.
  is_neg_inf(x) && return nan(Unum{ESS,FSS})
  Unum{ESS,FSS}(max_fsize(FSS), x.esize, x.flags | UNUM_UBIT_MASK, x.fraction, x.exponent)
end

function inward_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_ulp(x) && throw(ArgumentError("function only for exact numbers"))
  is_zero(x) && return nan(Unum{ESS,FSS})
  is_pos_inf(x) && return pos_mmr(Unum{ESS,FSS})
  is_neg_inf(x) && return neg_mmr(Unum{ESS,FSS})
  tx = __inward_exact(x)
  Unum{ESS,FSS}(max_fsize(FSS), tx.esize, x.flags | UNUM_UBIT_MASK, tx.fraction, tx.exponent)
end
function next_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_zero(x) && return pos_sss(Unum{ESS,FSS})
  is_negative(x) && return inward_ulp(x)
  outward_ulp(x)
end
function prev_ulp{ESS,FSS}(x::Unum{ESS,FSS})
  is_zero(x) && return neg_sss(Unum{ESS,FSS})
  is_negative(x) && return outward_ulp(x)
  inward_ulp(x)
end

export outward_ulp, inward_ulp, next_ulp, prev_ulp
=#
