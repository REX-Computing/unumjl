#unum-division.jl - currently uses the newton-raphson method, but will also
#implement other division algorithms.

function /(a::Unum, b::Unum)
  nrd(a, b)
end

function nrd{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #calculate the amount of accuracy needed roughly scales with fsizesize.
  iters = max(FSS, 3)
  aexp = decode_exp(a)
  bexp = decode_exp(b)
  divfactor = bexp + 1

  negative = (a.flags & SIGN_MASK) != (b.flags & SIGN_MASK)

  #reset the exponentials for both a and b, and strip the sign
  (esize, exponent) = encode_exp(aexp - divfactor)
  a.esize = esize
  a.exponent = exponent
  a.flags &= ~ SIGN_MASK
  (esize, exponent) = encode_exp(bexp - divfactor)
  b.esize = esize
  b.exponent = exponent
  b.flags &= ~ SIGN_MASK

  #consider implementing this as a lookup table.
  nr_1 = one(Unum{ESS,FSS})
  nr_2 = convert(Unum{ESS,FSS}, 48/17)
  nr_3 = convert(Unum{ESS,FSS}, 32/17)

  #generate the test term for b^-1
  x = nr_2 - nr_3 * b

  #iteratively improve x.
  for i = 1:iters
    x = x + (x * (nr_1 - (b * x)))
  end

  #return a * x
  negative ? -(a * x) : a * x
end
