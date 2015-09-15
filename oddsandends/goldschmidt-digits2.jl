#goldschmidt-digits.jl

#goldschmidt algorithm test on Float16, Float32, Float64.  The purpose of this is to
#determine if the understanding of iterations to complete digits is correct.

import Base.issubnormal
issubnormal(x::Float16) = (x != 0) && ((reinterpret(Uint16, x) & 0x7c00) == 0)
export issubnormal

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
  old::Uint64 = num1
  res::Uint64 = carry * num2 + num1 + (num1 >> 32) * (num2 >> 32) + (((num1 & rm) * (num2 >> 32)) >> 32) + (((num2 & rm) * (num1 >> 32)) >> 32)
  ((old > res ? uint64(carry + 1) : carry), res)
end

#performs a simple multiply, Assumes that number 1 has a hidden bit of exactly one
#and number 2 has a hidden bit of exactly zero
#(1 + a)(0 + b) = b + ab
function smult(subdigit, num1, num2)
  subdigit * num2 + (num1 >> 32) * (num2 >> 32) + (((num1 & rm) * (num2 >> 32)) >> 32) + (((num2 & rm) * (num1 >> 32)) >> 32)
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
    return nan(T)
  end

  #figure out the sign.
  sign::Uint64 = signof(x) $ signof(y)

  #calculate the exponent.
  exp_f::Int64 = exponentof(x) - exponentof(y) + (issubnormal(x) ? 1 : 0) - (issubnormal(y) ? 1 : 0)

  #figure the decimals.
  numerator::Uint64 = castfrac(x)

  #save the old numerator
  old_numerator = numerator
  if (issubnormal(x))
    shift::Uint64 = clz(numerator) + 1
    numerator = numerator << shift
    exp_f -= shift
  end
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

  (exp_f > maxexp(T)) && (return (sign == 1 ? convert(T,-Inf) : inf(T)))
  (exp_f < minexp(T, true) - 2) && (return (sign == 1 ? convert(T,-0.0) : 0.0))

  ourfrac_mask = maskfor(T)

  pass_denominator::Uint64 = 0

  #do the goldschmidt algorithm
  for (idx = 1:32)
    factor::Uint64 = (-denominator)
    #simple-fused-multiply-add.
    (carry, numerator) = sfma(carry, numerator, factor)
    (_, denominator) = sfma(uint64(0), denominator, factor)
    #println(bits(numerator))
    #println(bits(denominator))

    #~denominator == 0 && break
    (~denominator & ourfrac_mask == 0) && break
    denominator &= ourfrac_mask
    numerator &= ourfrac_mask
  end
  if carry > 1
    numerator = numerator >> 1 | (carry & 0x1 << 63)
    exp_f += 1
  end

  (exp_f > maxexp(T)) && (return (sign == 1 ? convert(T,-Inf) : inf(T)))
  (exp_f < minexp(T, true)) && (return (sign == 1 ? convert(T,-0.0) : 0.0))

  exp_f < minexp(T, false) && ((exp_f, numerator) = fixsn(T, exp_f, numerator))

  #now, at this point, we have to go back and 'check our work.'
  #multiply the old_denominator times the current numerator, and should result
  #in the old_numerator

  numerator &= 0xFFFF_FFFF_FFFF_F000

  subdigit = exp_f < minexp(T, false) ? 0 : 1
  check = (smult(subdigit, numerator, old_denominator) << (carry > 1 ? 1 : 0))

  if ((check & 0xFFFF_FFFF_0000_0000) != (old_numerator & 0xFFFF_FFFF_0000_0000))
    println("subnormal wierdness")
    println(bits(check))
    println(bits(old_numerator))
    println("----")
    println(bits(numerator))
    println(bits(x/y))
    exit()
  else

#  println(bits(check))
#  println(bits(old_numerator))
  if (check > old_numerator)
    #println(bits(check))
    #println(bits(old_numerator))
    #println("prev_ulp!")
    #exit()
  elseif (check == old_numerator)
    #println("exact 1!")
  else
    numerator += 0x0000_0000_0000_1000
    check = (smult(subdigit, numerator, old_denominator) << (carry > 1 ? 1 : 0))
    if (check < old_numerator)
      println("a")
      #println("middle_ulp!")
    elseif (check == old_numerator)
      #println("exact 2!")
    else
      println("b")
      #println("next_ulp!")
    end
  end
  end

  #how do we know if it was exact?  Well, there are two possibilities.  first
  #possibility is that new-denominator

  #reassemble the value.
  reassemble(T, sign, exp_f, numerator)
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
while (true)

  x = reinterpret(Float64, rand(Uint64))
  y = reinterpret(Float64, rand(Uint64))
  z = exct(x, y)
#=
  delta = reinterpret(Uint64,float64(x/y)) - reinterpret(Uint64, float64(z))

  if (delta != 0) && (delta != 1) && (!(isnan(x / y) && isnan(z)))
    println(bits(x/y))
    println(bits(z))
    println("$x / $y = $(x / y) ?= $(z)")
    println(bits(x))
    println(bits(y))
    (issubnormal(x)) && println("snx")
    (issubnormal(y)) && println("sny")
    println("----")
  end
=#
end
