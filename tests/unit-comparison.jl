#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#unit-comparison.jl
#unit testing on comparison operators.

#equality operator.

UnumTypes = [Unum{0,0}, Unum{1,1}, Unum{2,2}, Unum{4,6}]

testfor(f) = map((T) -> (@test f(T)), UnumTypes)

#test sign-independent equality of zeroes
testfor((T) -> zero(T) == -zero(T))
#test cross-sign inequality for a nonzero
testfor((T) -> one(T) != -one(T))
#test inequality for NaNs
testfor((T) -> nan(T) != nan(T))
#but make sure isequal does see NaNs as equal.
testfor((T) -> isequal(nan(T), nan(T)))

#wierd equalities with subnormal numbers.
#whlf is the 'normal' representation of half.
#wsml is a subnormal representation of half.
whlf = Unum{4,6}(z16, 0x0001, z16,                   z64, o64)
wsml = Unum{4,6}(z16, z16,    z16, 0x8000_0000_0000_0000, z64)
@test whlf == wsml

#note that these are all the same value
wwd0 = Unum{4,6}(z16,        0x0006, z16, 0x0000_0000_0000_0000, 0x0000000000000020) #normal form
wwd1 = Unum{4,6}(z16,        0x0005, z16, 0x8000_0000_0000_0000, 0x0000000000000000) #5-subnormal form
wwd2 = Unum{4,6}(uint16(16), 0x0004, z16, 0x0000_8000_0000_0000, 0x0000000000000000) #4-subnormal form
wwd3 = Unum{4,6}(uint16(24), 0x0003, z16, 0x0000_0080_0000_0000, 0x0000000000000000) #3-subnormal form
wwd4 = Unum{4,6}(uint16(28), 0x0002, z16, 0x0000_0008_0000_0000, 0x0000000000000000) #2-subnormal form

@test wwd0 == wwd1 && wwd1 == wwd2 && wwd2 == wwd3 && wwd3 == wwd4
@test wwd0 == wwd2 && wwd1 == wwd3 && wwd2 == wwd4
@test wwd0 == wwd3 && wwd1 == wwd4
@test wwd0 == wwd4

#let's make sure this works when we are using unums.
wwu0 = unum_unsafe(wwd0, Unums.UNUM_UBIT_MASK)
wwu1 = unum_unsafe(wwd1, Unums.UNUM_UBIT_MASK)
wwu2 = unum_unsafe(wwd2, Unums.UNUM_UBIT_MASK)
wwx1 = Unum{4,6}(uint16(3), 0x0005, Unums.UNUM_UBIT_MASK, 0x8000_0000_0000_0000, 0x0000000000000000) #5-subnormal form
@test wwu0 != wwd0 && wwu1 != wwd1 && wwu2 != wwd2  #test that the ubits are not the same as the exact
@test wwu0 == wwu1 && wwu1 == wwu2 && wwu0 == wwu2  #test that the ubits are all the same as each other
@test wwx1 != wwu0 && wwx1 != wwu1 && wwx1 != wwu2  #but not if you move the fsize so that there are more bits.

@test !(zero(Unum{4,6}) > zero(Unum{4,6}))
