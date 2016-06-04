#unum-comparison.jl

import Base:  ==, <, >  #this statement is necessary to redefine these functions directly

@universal function ==(a::Unum, b::Unum)
  #first compare the ubits.... These must be the same or else they aren't equal.
  ((a.flags & UNUM_UBIT_MASK) != (b.flags & UNUM_UBIT_MASK)) && return false
  #next, compare the sign bits...  The only one that spans is zero.
  ((a.flags & UNUM_SIGN_MASK) != (b.flags & UNUM_SIGN_MASK)) && (return (is_zero(a) && is_zero(b)))
  #check if either is nan.  Note that NaN != NaN.
  (isnan(a) || isnan(b)) && return false

  #resolve degenerate forms.
  resolve_degenerates!(a)
  resolve_degenerates!(b)

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

#note that unlike IEEE floating points, 0 === -0 for Unums.  So the only isequal
#exception should be the NaN exception.  In order to achieve this, we take negative
#zero and make it the degenerate zero.  We also collapse fsize and esize to the
#most reasonable value.
@universal function Base.hash(a::Unum, h::UInt)
  #use the full_decode function to extract
  resolve_degenerates!(a)

  #now generate the hash.
  h = hash(a.esize << 32 | a.fsize << 16 | a.flags, h)
  h = hash(a.fraction, h)
  h = hash(a.exponent, h)
  h
end

#the corresponding isequal function.
@universal Base.isequal(a::Unum, b::Unum) = (hash(a) == hash(b))

#=
@generated function >{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  maxfsize = max_fsize(FSS)
  quote
    (is_nan(a) || is_nan(b)) && return false
    _b_pos::Bool = (is_positive(b))
    _a_pos::Bool = (is_positive(a))

    (_b_pos) && (!_a_pos) && return false
    (!_b_pos) && (_a_pos) && return (!(is_zero(a) && is_zero(b)))

    #zero can cause problems down the line.
    is_zero(a) && return !(_b_pos || is_zero(b))
    is_zero(b) && return _a_pos

    #resolve exponents for strange subnormals.
    is_strange_subnormal(a) && (__resolve_subnormal!(a); _aexp = decode_exp(a))
    is_strange_subnormal(b) && (__resolve_subnormal!(b); _bexp = decode_exp(b))

    #so now we know that these two have the same sign.
    (decode_exp(b) > decode_exp(a)) && return (!_a_pos)
    (decode_exp(b) < decode_exp(a)) && return _a_pos
    #check fractions.


    #if the fractions are equal, then the condition is satisfied only if a is
    #an ulp and b is exact.
    (b.fraction == a.fraction) && return ((is_exact(b) && is_ulp(a) && _a_pos) ||
       (is_ulp(b) && is_exact(a) && !_a_pos))
    #check the condition that b.fraction is less than a.fraction.  This should
    #be xor'd to the _a_pos to give an instant failure condition.  Eg. if we are
    #positive, then b > a means failure.

    (b.fraction < a.fraction) && (!_a_pos) && return false
    (a.fraction < b.fraction) && (_a_pos) && return false

    true
    #####################################################
    #(_a_pos) ? cmpplusubit(a.fraction, b.fraction, is_ulp(b) ? b.fsize : $maxfsize) :
   #           cmpplusubit(b.fraction, a.fraction, is_ulp(a) ? b.fsize : $maxfsize)
  end
end

#hopefully the julia compiler knows what to do here.
function <{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  return b > a
end

###############################################################################3
#specialized comparison functions

#compare lower bounds without actually computing it.  Precondition:  a and b are
#both ulps (and not exact), a and b have the same sign.
function cmp_lower_bound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  if is_positive(a)
    cmp_exact_value(a,b)
  else
    cmp_bounding_exact(a,b)
  end
end

#similar to the previous function, Precondition:  A and b are both ulps, and
#a and b have the same sign.
function cmp_upper_bound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  if is_negative(a)
    cmp_exact_value(a, b)
  else
    cmp_bounding_exact(a,b)
  end
end

#looks at the exact values of two thingies.
function cmp_exact_value{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #mercilessly destroy strange subnormals in a or b.
  is_strange_subnormal(a) && resolve_subnormal!(a)
  is_strange_subnormal(b) && resolve_subnormal!(b)
  #now we have unique esize; exponent pairs, as well as fractions.
  a.esize == b.esize || return false
  a.exponent == b.exponent || return false
  a.fraction == b.fraction || return false
  return true #aka a == b
end

@gen_code function cmp_bounding_exact{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  @code quote
    is_strange_subnormal(a) && resolve_subnormal!(b)
    is_strange_subnormal(b) && resolve_subnormal!(b)
    #we'll need to decode_exponent
    a.esize == b.esize || return false
    a.exponent == b.exponent || return false
  end
  if FSS < 7
    @code :(__add_ubit(a.fraction, a.fsize) == __add_ubit(b.fraction, b.fsize))
  else
    #for longer fractions we can't do this.  Instead, we will use a clever
    #heuristic.  1) from bits 0...lower_fsize, b != a disqualifies.
    #2) from bits lower_fsize...higher_fsize, if b has a lower fsize, then a
    #must be all ones.
    @code quote
      a_middle::UInt16 = (a.fsize >> 6) + 1
      b_middle::UInt16 = (b.fsize >> 6) + 1
      l_middle::UInt16 = min(b_middle, a_middle)
      l_mask::UInt16 = top_mask(l_middle)
      h_middle::UInt16 = max(b_middle, a_middle)
      h_mask::UInt16 = top_mask(h_middle)
      longfrac = (a_middle > b_middle) ? a : b
    end
    for idx = __cell_length(FSS):-1:1
      @code quote
        if ($idx < l_middle)
          a.fraction.a[$idx] == b.fraction.a[$idx] || return false
        elseif ($idx == l_middle)
          (a.fraction.a[$idx] & l_mask) == (b.fraction.a[$idx] & l_mask) || return false
          if ($idx == h_middle)
            m_mask::UInt16 = ~l_mask & h_mask
            longfrac.fraction.a[$idx] & m_mask == m_mask || return false
          end
        elseif ($idx < h_middle)
          longfrac.fraction.a[$idx] == f64 || return false
        elseif ($idx == h_middle)
          longfrac.fraction.a[$idx] & m_mask == m_mask || return false
        end
      end
    end
    return true
  end
end
=#
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
