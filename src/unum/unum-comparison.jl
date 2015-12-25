#unum-comparison.jl

#test equality on unums.
import Base.==
function =={ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #first compare the ubits.... These must be the same or else they aren't equal.
  ((a.flags & UNUM_UBIT_MASK) != (b.flags & UNUM_UBIT_MASK)) && return false

  #next, compare the sign bits...  The only one that spans is zero.
  ((a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK)) && (return (is_zero(a) && is_zero(b)))
  #check if either is nan.  Note that NaN != NaN.
  (isnan(a) || isnan(b)) && return false

  #resolve strange subnormals.
  is_strange_subnormal(a) && (a = __resolve_subnormal(a))
  is_strange_subnormal(b) && (b = __resolve_subnormal(b))

  #first calculate the exponents.
  _aexp::Int64 = decode_exp(a)
  _bexp::Int64 = decode_exp(b)

  (_aexp != _bexp) && return false
  #now that we know that the exponents are the same,
  #the fractions must also be identical
  (a.fraction != b.fraction) && return false
  #the ubit on case is simple - the fsizes must be equal
  ((a.flags & UNUM_UBIT_MASK) == UNUM_UBIT_MASK) && return (a.fsize == b.fsize)
  #so we are left with exact floats at any resolution, ok, or uncertain floats
  #with the same resolution.  These must be equal.
  return true
end

#note that unlike IEEE floating points, 0 == -0 for Unums.  So the only isequal
#exception should be the NaN exception.  In order to achieve this, we take negative
#zero and make it the degenerate zero.  We also collapse fsize and esize to the
#most reasonable value.
@gen_code function Base.hash{ESS,FSS}(a::Unum{ESS,FSS}, h::UInt)
  @code quote
    b = Unum{ESS,FSS}(a)
    #mask out the sign flag if it's zero so that they're degenerate.
    is_zero(a) && (b.flags = a.flags & (~UNUM_SIGN_MASK))

    #convert strange subnormals.
    is_strange_subnormal(a) && (b = __resolve_subnormal(b))
    if (!is_subnormal(a))
      (esize, exponent) = encode_exp(decode_exp(a))
      b.esize = esize
      b.exponent = exponent
    end
  end
  mfs = max_fsize(FSS)
  if (FSS < 7)
    @code :((b.fraction, b.fsize, _) = __frac_trim(a.fraction, $mfs))
  else
    @code :((b.fsize, _) = __frac_trim!(b.fraction, $mfs))
  end

  @code quote
    #now generate the hash.
    h = hash((UInt(b.fsize) << 32) | (UInt(b.esize) << 16) | (UInt(b.flags & (UNUM_UBIT_MASK | UNUM_SIGN_MASK))), h)
    h = hash(b.fraction, h)
    h = hash(b.exponent, h)
    h
  end
end

#the corresponding isequal function.
Base.isequal{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = (hash(a) == hash(b))

@gen_code function >{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  @code quote
    (is_nan(a) || is_nan(b)) && return false
    _b_pos::Bool = (is_positive(b))
    _a_pos::Bool = (is_positive(a))

    (_b_pos) && (!_a_pos) && return false
    (!_b_pos) && (_a_pos) && return (!(is_zero(a) && is_zero(b)))
    #resolve exponents for strange subnormals.

    is_strange_subnormal(a) && (a = __resolve_subnormal(a); _aexp = decode_exp(a))
    is_strange_subnormal(b) && (b = __resolve_subnormal(b); _bexp = decode_exp(b))

    #so now we know that these two have the same sign.
    (decode_exp(b) > decode_exp(a)) && return (!_a_pos)
    (decode_exp(b) < decode_exp(a)) && return _a_pos
    #check fractions.

    #if the fractions are equal, then the condition is satisfied only if a is
    #an ulp and b is exact.
    (b.fraction == a.fraction) && return (is_exact(b) && is_ulp(a) && _a_pos)
    #check the condition that b.fraction is less than a.fraction.  This should
    #be xor'd to the _a_pos to give an instant failure condition.  Eg. if we are
    #positive, then b > a means failure.
    ((b.fraction < a.fraction) != _a_pos) && return false
    #####################################################
    (_a_pos) ? cmpplusubit(a.fraction, b.fraction, b.fsize) : cmpplusbit(b.fraction, a.fraction, b.fsize)
  end
end

#hopefully the julia compiler knows what to do here.
function <{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  return b > a
end
#=
import Base.min
import Base.max
function min{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #adjust them in case they are subnormal
  is_strange_subnormal(a) && (a = __resolve_subnormal(a))
  is_strange_subnormal(b) && (b = __resolve_subnormal(b))

  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    is_negative(a) && return a
    return b
  end
  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    ((_aexp > _bexp) != is_negative(a)) && return a
    return b
  end
  #next criteria, check the fractions
  if (a.fraction != b.fraction)
    ((a.fraction > b.fraction) != is_negative(a)) && return a
    return b
  end
  #finally, check the ubit
  (is_ulp(a) != is_negative(a)) && return a
  return b
end

function max{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #adjust them in case they are subnormal
  is_strange_subnormal(a) && (a = __resolve_subnormal(a))
  is_strange_subnormal(b) && (b = __resolve_subnormal(b))

  #first, fastest criterion:  Are they not the same sign?
  if (a.flags $ b.flags) & UNUM_SIGN_MASK != 0
    isnegative(a) && return b
    return a
  end
  #next criterion, are the exponents different
  _aexp = decode_exp(a)
  _bexp = decode_exp(b)
  if (_aexp != _bexp)
    ((_aexp > _bexp) != is_negative(a)) && return b
    return a
  end
  #next criteria, check the fractions
  if (a.fraction != b.fraction)
    ((a.fraction > b.fraction) != is_negative(a)) && return b
    return a
  end
  #finally, check the ubit
  (is_ulp(a) != is_negative(a)) && return b
  return a
end
export min, max
=#
