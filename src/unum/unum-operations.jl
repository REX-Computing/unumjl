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

@gen_code function __inward_ulp!{ESS,FSS}(x::Unum{ESS,FSS})
  @code quote
    is_strange_subnormal(x) && __resolve_subnormal!(x)
    if is_frac_zero(x)
      #deal with subnormal.
      is_exp_zero(x) && (sss!(x, x.flags & UNUM_SIGN_MASK); return x)
      current_exponent = decode_exp(x)
      (x.esize, x.exponent) = ((current_exponent == min_exponent(ESS)) ? (z16, z64) : encode_exp(decode_exp(x) - 1))
    end
    x.flags |= UNUM_UBIT_MASK
  end
  if (FSS < 7)
    @code :(x.fraction -= bottom_bit(max_fsize(FSS)); x)
  else
    @code :(prev_val!(x.fraction); x)
  end
end

function make_min_ulp!{ESS,FSS}(x::Unum{ESS,FSS})
  x.fsize = max_fsize(FSS)
  x.flags |= UNUM_UBIT_MASK
  x
end

function __outward_exact!{ESS,FSS}(x::Unum{ESS,FSS})
  promoted::Bool = __add_ubit_frac!(x)
  promoted && ((x.esize, x.exponent) = (encode_exp(decode_exp(x) + 1)))
  x.flags &= ~UNUM_UBIT_MASK
  x
end

function upper_ulp!{ESS,FSS}(x::Unum{ESS,FSS})
  is_zero(x) && return pos_sss!(x)
  return is_positive(x) ? make_min_ulp!(x) : __inward_ulp!(x)
end

function lower_ulp!{ESS,FSS}(x::Unum{ESS,FSS})
  is_zero(x) && return neg_sss!(x)
  return is_positive(x) ? __inward_ulp!(x) : make_min_ulp!(x)
end

doc"""
  upper_bound_exact! converts x into the unum which is the exact number that
  upper bounds it.
"""
function upper_bound_exact!{ESS,FSS}(x::Unum{ESS,FSS})
  __is_nan_or_inf(x) && (nan!(x); return)
  is_exact(x) && return x
  return is_negative(x) ? make_exact!(x) : __outward_exact!(x)
end

doc"""
  lower_bound_exact! converts x into the unum which is the exact number that
  upper bounds it.
"""
function lower_bound_exact!{ESS,FSS}(x::Unum{ESS,FSS})
  __is_nan_or_inf(x) && (nan!(x); return)
  is_exact(x) && return x
  return is_negative(x) ? __outward_exact!(x) : make_exact!(x)
end

export upper_bound_exact!, lower_bound_exact!
