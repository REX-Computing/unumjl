#goldschmidt-log.jl

include("../unum.jl")
using Unums

#implements an goldschmidt-like logarithm algorithm for Float64 as a testground for
#doing it in unums.

#returns a Int16 "1" if it's negative, "0" if it's positive.
function signof(x::Float64)
  ((reinterpret(UInt64, x) & 0x8000_0000_0000_0000) != 0) ? 1 : 0
end

function exponentof(x::Float64)
  int64((reinterpret(Int64, x) & 0x7FF0_0000_0000_0000) >> 52 - 1023)
end

function castfrac(x::Float64)
    (reinterpret(UInt64, x) & 0x000F_FFFF_FFFF_FFFF) << 12
end

function maskfor(T::Type)
  if (T == Float64)
    return 0xFFFF_FFFF_FFFF_FF00  #56 digits suffices for Float64 (52 digits)
  elseif (T == Float32)
    return 0xFFFF_FFE0_0000_0000  #27 digits of precision seems to suffice for a Float32 (23 digits)
  end
end

o16 = one(UInt16)
z16 = zero(UInt16)
__clz_array=[0x0004,0x0003,0x0002,0x0002, o16, o16, o16, o16, z16,z16,z16,z16,z16,z16,z16,z16]
function leading_zeros(n)
  (n == 0) && return 64
  res::UInt16 = 0
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
function smult(a::UInt64, b::UInt64)

  (fraction, _) = Unums.__chunk_mult(a, b)
  carry = one(UInt64)

  #only perform the respective adds if the *opposing* thing is not subnormal.
  ((carry, fraction) = Unums.__carried_add(carry, fraction, b))

  #carry may be as high as three!  So we must shift as necessary.
  (fraction, shift, is_ubit) = Unums.__shift_after_add(carry, fraction, _)
  fraction << 1
end

function reassemble(sign::UInt64, ev::UInt64, fv::UInt64)
  number = (fv >> 12) | ((ev + 1023) << 52) | (sign << 63)

  println(bits(number))

  reinterpret(Float64, number)
end


include("logtable.jl")
#ultimately, we may need to have more digits on the end of this value for logarithm.
const log2e = 0x71547652b82fe_000
const __logarithm_magicnumber = 0xb8aa3b27e0000000

function exlg(x::FloatingPoint)
  #exact floating point with the goldschmidt algorithm.
  T = typeof(x)

  isnan(x) && return (nan(T), false)

  x <= 0 && return nan(T)

  #calculate the exponent.
  exp_f::Int64 = exponentof(x) + (issubnormal(x) ? 1 : 0)

  #figure the decimals.
  fraction::UInt64 = castfrac(x)

  if (issubnormal(x))
    shift::UInt64 = leading_zeros(fraction) + 1
    fraction = fraction << shift
    exp_f -= shift
  end

  sign::UInt64 = 0
  if (exp_f < 0)
    exp_f = -exp_f - 1
    sign = 1
  end
  lz = leading_zeros(UInt64(exp_f))
  resexp = 63 - lz
  #add the exponent part onto the result fraction.
  resfrac = UInt64(exp_f << (lz + 1))

  #do the goldschmidt-type algorithm.
  #first, "divide by two" by doing a virtual shift left, appending the implied
  #one onto the most significant end.
  fraction = (fraction >> 1) | 0x8000_0000_0000_0000
  diff::UInt64 = 0
  d::Int64 = 0
  m::UInt64 = 0
  intsumdelta::UInt64 = 0
  intsumsofar::UInt64 = 0

  #goldschmidt-like algorithm.
  for idx = 1:32
    #figure the difference between the fraction we have and what's left.  This
    #is equivalent to the operation "2 - x".  For 0.5 < x < 1.0 x(2 - x) is
    #bounded between 0.5 and 1, so we get closer by iterative multiplication.
    #However, because calculating the log of this value is nontrivial, we must
    #use a lookup table which has precalculated logs for fractions f of the form
    # f = 1.0...010....0, indexed by the place of the one.
    diff = 0 - fraction
    #find the place of the top bit
    d = leading_zeros(diff)
    #generate the value (we will do a multiply with this to keep track of our progress.)
    m = 0x8000_0000_0000_0000 >> d

    #look up the value to be added, or, if it's far enough along, just do a bitshift.
    intsumdelta = d > 29 ? (__logarithm_magicnumber >> d) : lt64[d]
    intsumsofar += intsumdelta

    #update frac to be the product of our cumulative fraction and the 1.0...01
    (_, fraction) = Unums.__sfma(zero(UInt64), fraction, m)

    #terminating condition.
    if m < 0x0000_0000_0000_0400
      break
    end
  end

  #now do a flip (if the log is positive)
  iint::UInt64 = (sign == 0) ? -intsumsofar : intsumsofar
  resfrac |= iint >> resexp
  #reassemble the value into the requisite floating point
  reassemble(sign, resexp, resfrac)
end

v = rand(Int64)
x = abs(reinterpret(Float64, v))
z = exlg(x)
a = log2(x)

println("input :    $x")
println("answer:    $(log2(x))")
println("calculate: $z")

println("xbits:     ", bits(x))
println("abits:     ", bits(a))
println("zbits:     ", bits(z))

println("diff:      ", reinterpret(UInt64, a) - reinterpret(UInt64, z))

#######################################################
## testing fun

i2f(i) = reinterpret(Float64, (i >> 12) | 0x3FF0_0000_0000_0000)
