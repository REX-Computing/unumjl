#ubox.jl - Ubox method

@universal function same_exp(x::Unum, y::Unum)
  is_negative(x) && is_positive(y) && return false
  (decode_exp(x) - (x.exponent == z64)) == (decode_exp(y) - (y.exponent == z64))
end

function isterminal{ESS,FSS}(x::Utype{ESS,FSS})
  isterminal(x.val)
end
function isterminal{ESS,FSS}(a::Vector{Utype{ESS,FSS}})
  for element in a
    isterminal(element) || return false
  end
  return true
end
@universal function isterminal(x::Unum)
  is_exact(x) && return true
  (x.fsize == max_fsize(FSS)) && return true
  return false
end
@universal function isterminal(x::Ubound)
  return false
end

upper_avg(x, y) = ((x + y) ÷ 2) + ((x + y < 0) ? 0 : 1) * isodd(x + y)

@universal function udivide(x::Unum)
  isterminal(x) && throw(ArgumentError("can't udivide an terminal unum"))

  if is_positive(x)
    #the low_ulp is the original unum, except with an extended ubit.
    low_ulp = copy(x)
    low_ulp.fsize += 1
    mid_exact = lub(low_ulp)
    high_ulp = copy(mid_exact)
    high_ulp.flags |= UNUM_UBIT_MASK
  else
    high_ulp = copy(x)
    high_ulp.fsize += 1
    mid_exact = glb(high_ulp)
    low_ulp = copy(mid_exact)
    low_ulp.flags |= UNUM_UBIT_MASK
  end

  (low_ulp, mid_exact, high_ulp)
end

function count_same(a::UInt64, b::UInt64)
  UInt16(leading_zeros(a $ b))
end

function count_same{FSS}(a::ArrayNum{FSS}, b::ArrayNum{FSS})
  total::UInt16 = 0
  for idx = 1:__cell_length(FSS)
    read = leading_zeros(a.a[idx] $ b.a[idx])
    total += read
    (read != 64) && return total
  end
end

function maskout(a::UInt64, count::UInt16)
  mask_top(count) & a
end
function maskout!{FSS}(a::ArrayNum{FSS}, count::UInt16)
  t = zero(ArrayNum{FSS})
  mask_top!(t, count)
  for idx = 1:__cell_length(FSS)
    a.a[idx] &= t.a[idx]
  end
end
@fracproc maskout count

function bitin(a::UInt64, count::UInt16)
  bottom_bit(count) | a
end
function bitin!{FSS}(a::ArrayNum{FSS}, count::UInt16)
  t = zero(ArrayNum{FSS})
  bottom_bit!(t, count)
  for idx = 1:__cell_length(FSS)
    a.a[idx] |= t.a[idx]
  end
end
@fracproc bitin count

@universal function udivide(x::Ubound)
  #special case where the bounds are exact.

  if is_exact(x.lower)
    if is_exact(x.upper)
      middlebound = Ubound(is_zero(x.lower) ? pos_sss(U) : upper_ulp(x.lower), is_zero(x.upper) ? neg_sss(U) : lower_ulp(x.upper))
      return (x.lower, middlebound, x.upper)
    end
    return (x.lower, Ubound(is_zero(x.lower) ? pos_sss(U) : upper_ulp(x.lower), x.upper), nothing)
  elseif is_exact(x.upper)
    return (Ubound(x.lower, is_zero(x.upper) ? neg_sss(U) : lower_ulp(x.upper)), x.upper, nothing)
  end

  if (is_strange_subnormal(x.lower) && is_all_zero(x.lower.fraction))
    return udivide(Ubound(pos_sss(U), x.upper))
  end

  if (is_strange_subnormal(x.upper) && is_all_zero(x.upper.fraction))
    return udivide(Ubound(x.lower, neg_sss(U)))
  end

  #if the ubound straddles zero, then naturally cleave across zero.
  if (is_negative(x.lower) && is_positive(x.upper))

    return (resolve_as_utype!(copy(x.lower), neg_sss(Unum{ESS,FSS})),
            zero(Unum{ESS,FSS}),
            resolve_as_utype!(pos_sss(Unum{ESS,FSS}), copy(x.upper)))
  end

  #if the bounds are not exact...  First check if the exponents are the same
  if same_exp(x.lower, x.upper)
    #each exponential range cleaves over two single ubounds.  First, check to
    #see if they are in the upper half or the lower half.
    count::UInt16 = count_same(x.lower.fraction, x.upper.fraction)

    middle_value = copy(x.lower)
    middle_value.flags = x.lower.flags & (~UNUM_UBIT_MASK)
    frac_maskout!(middle_value, count)
    frac_bitin!(middle_value, count)

    #set the middle_value to look like
    return (resolve_as_utype!(copy(x.lower), lower_ulp(middle_value)), middle_value, resolve_as_utype!(upper_ulp(middle_value), x.upper))
  else
    #if they're not, then do a binary search on the exponents.
    middle_exp = upper_avg(decode_exp(x.lower), decode_exp(x.upper))
    middle_value = zero(U)
    middle_value.flags = x.lower.flags & UNUM_SIGN_MASK
    (middle_value.esize, middle_value.exponent) = encode_exp(middle_exp)

    return (resolve_as_utype!(copy(x.lower), lower_ulp(middle_value)), middle_value, resolve_as_utype!(upper_ulp(middle_value), copy(x.upper)))
  end
end

udivide(x::Utype) = map(Utype, udivide(x.val))

doc"""
  ufilter(f::Function, uvalue::Utype)
  ufilter(f::Function, uarray::Vector{Utype,1})

  passes an array of utype boxed objects and does a binary search to whittle down
  the results to a minimal array of solutions.  Function f should be a predicate
  fuction, aka, returns a boolean value.
"""
function ufilter{ESS,FSS, verbose}(f::Function, u::Utype{ESS,FSS}, ::Type{Val{verbose}} = Val{false})
  #first create an anonymous function g which takes an array of Utypes and passes
  #the first member to f.
  g = (a::Vector{Utype{ESS, FSS}}) -> f(a[1])
  #then execute the g function on the array ufilter method.
  ufilter(g, [u], Val{verbose})
end

const max_iters = 2
iters = 0

function ufilter{ESS,FSS, verbose}(f::Function, v::Vector{Utype{ESS,FSS}}, ::Type{Val{verbose}} = Val{false})

  global iters

  l = length(v)
  result = Array{Utype,2}(l, 0)

  #trigger a terminal check.
  isterminal(v) && return f(v) ? v : Matrix{Utype{ESS,FSS}}(l,0)

  #pick a random index that isn't terminal.
  validindices = filter((idx)->(!isterminal(v[idx])), 1:l)
  ridx = rand(validindices)

  (lower_u, middle_u, upper_u) = udivide(v[ridx])

  vl = copy(v)
  vm = copy(v)

  vl[ridx] = lower_u
  vm[ridx] = middle_u

  if f(vl)
    verbose && (print("searching "); describe.(vl))
    iters == max_iters && exit()
    result = hcat(result, ufilter(f, vl, Val{verbose}))
  end

  if f(vm)
    verbose && (print("searching "); describe.(vm))
    iters == max_iters && exit()
    (result = hcat(result, ufilter(f, vm, Val{verbose})))
  end

  if (upper_u != nothing)
    vu = copy(v)
    vu[ridx] = upper_u
    if f(vu)
      verbose && (print("searching "); describe.(vu))
      iters == max_iters && exit()
      (result = hcat(result, ufilter(f, vu, Val{verbose})))
    end
  end

  result
end

export ufilter
