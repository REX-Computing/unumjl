#goldschmidt-digits.jl

include("../unum.jl")
using Unums

#goldschmidt algorithm test on Float16, Float32, Float64.  The purpose of this is to
#determine if the understanding of where to put ULPs is correct.

#returns a Int16 "1" if it's negative, "0" if it's positive.
function signof(x::FloatingPoint)
  T = typeof(x)
  if (T == Float64)
    return ((reinterpret(Uint64, x) & 0x8000_0000_0000_0000) != 0) ? 1 : 0
  elseif (T == Float32)
    return ((reinterpret(Uint32, x) & 0x8000_0000) != 0) ? 1 : 0
  end
end

function exponentof(x::FloatingPoint)
  T = typeof(x)
  if (T == Float64)
    return int64((reinterpret(Int64, x) & 0x7FF0_0000_0000_0000) >> 52 - 1023)
  elseif (T == Float32)
    return int64((reinterpret(Int32, x) & 0x7F80_0000) >> 23 - 127)
  end
end

function castfrac(x::FloatingPoint)
  T = typeof(x)
  if (T == Float64)
    return (reinterpret(Uint64, x) & 0x000F_FFFF_FFFF_FFFF) << 12
  elseif (T == Float32)
    return uint64(reinterpret(Uint32, x) & 0x007F_FFFF) << 41
  end
end

function maskfor(T::Type)
  if (T == Float64)
    return 0xFFFF_FFFF_FFFF_FF00  #56 digits suffices for Float64 (52 digits)
  elseif (T == Float32)
    return 0xFFFF_FFE0_0000_0000  #27 digits of precision seems to suffice for a Float32 (23 digits)
  end
end

o16 = one(Uint16)
z16 = zero(Uint16)
__clz_array=[0x0004,0x0003,0x0002,0x0002, o16, o16, o16, o16, z16,z16,z16,z16,z16,z16,z16,z16]
function clz(n)
  (n == 0) && return 64
  res::Uint16 = 0
  #use the binary search method
  (n & 0xFFFF_FFFF_0000_0000 == 0) && (n <<= 32; res += 0x0020)
  (n & 0xFFFF_0000_0000_0000 == 0) && (n <<= 16; res += 0x0010)
  (n & 0xFF00_0000_0000_0000 == 0) && (n <<= 8;  res += 0x0008)
  (n & 0xF000_0000_0000_0000 == 0) && (n <<= 4;  res += 0x0004)
  res + __clz_array[(n >> 60) + 1]
end

#simple fused - multiply - add.  Assumes num1 has hidden bits "carry" and num2
#has no hidden bits.
rm = 0x0000_0000_FFFF_FFFF
function sfma(carry, num1, num2)
  (fracprod, _) = Unums.__chunk_mult(num1, num2)
  (_carry, fracprod) = Unums.__carried_add(carry, num1, fracprod)
  ((carry & 0x1) != 0) && ((_carry, fracprod) = Unums.__carried_add(_carry, num2, fracprod))
  ((carry & 0x2) != 0) && ((_carry, fracprod) = Unums.__carried_add(_carry, lsh(num2, 1), fracprod))
  (_carry, fracprod)
end

#performs a simple multiply, Assumes that number 1 has a hidden bit of exactly one
#and number 2 has a hidden bit of exactly zero
#(1 + a)(0 + b) = b + ab
function smult(a::Uint64, b::Uint64)

  (fraction, _) = Unums.__chunk_mult(a, b)
  carry = one(Uint64)

  #only perform the respective adds if the *opposing* thing is not subnormal.
  ((carry, fraction) = Unums.__carried_add(carry, fraction, b))

  #carry may be as high as three!  So we must shift as necessary.
  (fraction, shift, is_ubit) = Unums.__shift_after_add(carry, fraction, _)
  fraction << 1
end

function reassemble(T::Type, sign, exp_f, number)
  if T == Float64
    number = (number >> 12) | (exp_f + 1023) << 52 | sign << 63
  elseif T == Float32
    number = (number >> 9) | (exp_f + 127) << 55 | sign << 63
  end
  last(reinterpret(T, [number]))
end

function calculate(carry, number)
  carry + big(number) / (big(1) << 64)
end

function maxexp(T)
  if T == Float64
    1023
  elseif T == Float32
    127
  end
end

function minexp(T, subnormalq)
  if T == Float64
    -1022 - (subnormalq ? 52 : 0)
  elseif T == Float32
    -126 - (subnormalq ? 23 : 0)
  end
end

function findshift(shift)
  1 << (64 - shift)
end

function fixsn(T, exp_f, frac)
  if T == Float64
    shift = -1022 - exp_f
    return (-1023, (frac >> shift | findshift(shift)))
  elseif T == Float32
    shift = -126 - exp_f
    return (-127, (frac >> shift | findshift(shift)))
  end
end

function exct(x::FloatingPoint, y::FloatingPoint)
  #exact floating point with the goldschmidt algorithm.
  T = typeof(x)

  if isnan(x) || isnan(y)
    return (nan(T), false)
  end

  #figure out the sign.
  sign::Uint64 = signof(x) $ signof(y)

  #calculate the exponent.
  exp_f::Int64 = exponentof(x) - exponentof(y) + (issubnormal(x) ? 1 : 0) - (issubnormal(y) ? 1 : 0)

  #figure the decimals.
  numerator::Uint64 = castfrac(x)

  if (issubnormal(x))
    shift::Uint64 = clz(numerator) + 1
    numerator = numerator << shift
    exp_f -= shift
  end
  #save the old numerator
  old_numerator = numerator
  #set the carry on the numerator
  carry::Uint64 = 1

  denominator::Uint64 = castfrac(y)
  #adjust the denominator in the case that it's a subnormal
  if issubnormal(y)
    shift = clz(denominator)
    denominator = denominator << shift
    exp_f += shift
  else
    denominator = (denominator >> 1) | 0x8000_0000_0000_0000
    exp_f -= 1
  end
  #and then save this old denominator.
  old_denominator = denominator

  (exp_f > maxexp(T)) && (return (sign == 1 ? convert(T,-Inf) : inf(T), false))
  (exp_f < minexp(T, true) - 2) && (return ((sign == 1 ? convert(T,-0.0) : 0.0), false))

  ourfrac_mask = maskfor(T)
  #do the goldschmidt algorithm
  for (idx = 1:32)
    factor::Uint64 = (-denominator)
    #simple-fused-multiply-add.
    (carry, numerator) = sfma(carry, numerator, factor)
    (_, denominator) = sfma(uint64(0), denominator, factor)
    (~denominator & ourfrac_mask == 0) && break
    denominator &= ourfrac_mask
    numerator &= ourfrac_mask
  end
  if carry > 1
    numerator = numerator >> 1 | (carry & 0x1 << 63)
    exp_f += 1
  end

  (exp_f > maxexp(T)) && (return ((sign == 1 ? convert(T,-Inf) : inf(T)), false))
  (exp_f < minexp(T, true)) && (return ((sign == 1 ? convert(T,-0.0) : 0.0), false))


  #now, at this point, we have to go back and 'check our work.'
  #multiply the old_denominator times the current numerator, and should result
  #in the old_numerator

  numerator &= ourfrac_mask
  ans_subnormal = exp_f < minexp(T, false)
  is_ulp = true

  f_d = 0x0000_0000_0000_1000
  f_ma = 0xFFFF_FFFF_FFFF_F000
  #do a "remultiply" operation.  First attempt with the lower unit.

  reseq = smult(numerator & f_ma, old_denominator)
  resph = smult((numerator & f_ma + f_d), old_denominator)

  if (old_numerator < reseq)
    numerator = (numerator - f_d)
  elseif (old_numerator == reseq)
    #need to run an ulp check here.
    numerator = (numerator - f_d)
  elseif (old_numerator > (resph))
    numerator = (numerator + f_d)
  end

  (exp_f < minexp(T, false)) && ((exp_f, numerator) = fixsn(T, exp_f, numerator))

  #reassemble the value into the requisite floating point
  (reassemble(T, sign, exp_f, numerator), is_ulp)
end
#=
#one-time testing
#x = reinterpret(Float32, 0b00000110001001000111001101001111)
#y = reinterpret(Float32, 0b10000000010010100000111001111111)

x = reinterpret(Float64, rand(Uint64))
y = reinterpret(Float64, rand(Uint64))

#test exact divisions
#y = floor(rand() * 100000)
#q = floor(rand() * 100000)
#x = q * y
#println("theo. res: $(q)")

#x = 3.0
#y = 2.0

println("answer:    $(x/y)")
z = exct(x, y)
println("gscalc:    $z")
println("abits:     ", bits(x/y))
println("zbits:     ", bits(z))
#println("theo. bits:", bits(q))
=#

#continuous testing.
count = 0
errors = 0
while (true)
  x = reinterpret(Float64, rand(Uint64))
  y = reinterpret(Float64, rand(Uint64))
  (z, ulp) = exct(x, y)

  bigres = big(x) / big(y)
  bigguess = big(z)

  (isinf(z)) && continue

  if ulp
    nextfrac = big(reinterpret(Float64, (reinterpret(Uint64, z) + 1)))
    if (abs(bigguess) > abs(bigres))
      println("lower bound bad")
      println("gsans:", bits(z))
      println("fpans:", bits(x/y))
      println("count, $count")
      exit()
    end
    if (abs(nextfrac) < abs(bigres))
      println("upper bound bad")
      println(bits(z))
      println(bits(x/y))
      exit()
    end
  end
  count += 1
  println(count)
end

#NB:  This technique still has a vanishingly small ~(0.005%) error rate in assigning
#the correct ULP to the quotient.  Will need to take a  more careful look at why this
#is occurring.
