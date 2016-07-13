#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#test-things-from-the-book.jl

include("unum.jl")
using Unums
using Base.Test

#test various things from the book.
#are our representations of unums correct?

one16 = one(UInt16)
one64 = one(UInt64)
zero16 = zero(UInt16)
zero64 = zero(UInt64)
top64 = 0x8000_0000_0000_0000 #our representation for the fraction part is left-shifted.

#p.27, representation of simple unums.  In the tiny environment{1, 0}

#John Gustafsson's formula for unum calculation is as follows:
#(note that in our internal Unum structure, esize = es - 1)
#this differs from our internal unum calculation
function bookcalculate(x::Unum)
  #the sub`normal case
  if (x.exponent == 0)
    2.0^(x.exponent - 2.0^(x.esize)) * (big(x.fraction) / 2.0^64)
  else #the normalcase
    2.0^(x.exponent - 2.0^(x.esize) - 1) * (1 + big(x.fraction) / 2.0^64)
  end
end

#FOR REFERENCE, the code internal to the standard unum looks as follows:
# 2.0^(x.exponent - 2.0^(x.esize) + 1) * (big(x.fraction) / 2.0^64)
# 2.0^(x.exponent - 2.0^(x.esize)) * (1 + big(x.fraction) / 2.0^64)
#note that this actually matches the description of subnormals in the book
#
# "If all exponent bits are 0 , then add one to the exponent and use 0 for the hidden bit."

#claim: 0 00 1 0 +(utag) should be 1/2
uhalf = Unum{1,0}(zero16, one16, zero16, top64, zero64)
@test "0 00 1 0" == bits(uhalf, " ")[1:8] #note throw away the utag, as in the book.
#oops!  Neither formula yields the correct result.
@test 0.5 != Unums.calculate(uhalf)
@test 0.5 != bookcalculate(uhalf)
#let's try the better Unum representation 0 0 1 0 (0 0)
uhalf = Unum{1,0}(zero16, zero16, zero16, top64, zero64)
@test "0 0 1 0 0 " == bits(uhalf, " ") #note the trailing space due to the zero-bit float
@test 0.5 == Unums.calculate(uhalf)

#claim: 0 01 0 0 +(utag) should be one
uone = Unum{1,0}(zero16, one16, zero16, zero64, one64)
@test "0 01 0 0" == bits(uone, " ")[1:8] #note: throw away the utag, as in the book.
@test 1.0 != Unums.calculate(uone)
@test 1.0 != bookcalculate(uone)
#try the better Unum representation 0 1 0 0 (0 0)
uone = Unum{1,0}(zero16, zero16, zero16, zero64, one64)
@test "0 1 0 0 0 " == bits(uone, " ") #note the trailing space due to the zero-bit fraction
@test 1.0 == Unums.calculate(uone)

#fixing the warlpiri numbers
#the claim is that in warlpiri numbers:
#0010 == 1
#0100 == 2
#let's construct them.
warlone = Unum{0,0}(zero16, zero16, zero16, top64, zero64)
@test "0010" == bits(warlone)
#unfortunately this doesn't jive with the gustafson formula
@test 1.0 != bookcalculate(warlone)
#turns out it's even worse than our formula, which says that it should be a half
@test 0.5 == Unums.calculate(warlone)
@test 0.25 == bookcalculate(warlone)

warltwo = Unum{0,0}(zero16, zero16, zero16, zero64, one64)
@test "0100" == bits(warltwo)
#again, this doesn't jive with the gustafson formula
@test 2.0 != bookcalculate(warltwo)
#whereas our formula says it should be "one", which is consistent with above!
@test 1.0 == Unums.calculate(warltwo)
@test 0.5 == bookcalculate(warltwo)

#we find the following, that:
#0010 = 1/2
#0100 = 1
#note that while upshifting the exponent representation could fix the values for
#the previous bookcalculate() values, it doesn't fix them for the warlpiris.

#That's ok, though, for two reasons.
# 1) the construction exp = 1, frac = 0 is consistent with the one-constructor
# for all other unums, we don't want there to be a special case for warlpiris
# 2) A warlpiri system {-Inf, -1, -1/2, 0, 1/2, 1, Inf} is strictly mathematically
# equivalent to {-Inf, -2, -1, 0, 1, 2, Inf}
