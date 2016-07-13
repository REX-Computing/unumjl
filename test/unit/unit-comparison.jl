#unit-comparison.jl
#unit testing on comparison operators.

#equality operator.

UnumTypes = [Unum{0,0}, Unum{1,1}, Unum{2,2}, Unum{4,6}]

testfor(f) = map((T) -> (@test f(T)), UnumTypes)

#test sign-independent equality of zeroes
testfor((T) -> zero(T) == additiveinverse!(zero(T)))
#test cross-sign inequality for a nonzero
testfor((T) -> one(T) != additiveinverse!(one(T)))
#test inequality for NaNs
testfor((T) -> nan(T) != nan(T))
#but make sure isequal does see NaNs as equal.
testfor((T) -> isequal(nan(T), nan(T)))

#wierd equalities with subnormal numbers.
#whlf is the 'normal' representation of half.
#wsml is a subnormal representation of half.
whlf = Unum{4,6}(o64,                   z64, z16, 0x0001, z16)
wsml = Unum{4,6}(z64, 0x8000_0000_0000_0000, z16, z16,    z16)
@test whlf == wsml

#note that these are all the same value
wwd0 = Unum{4,6}(0x0000000000000020, 0x0000_0000_0000_0000, z16, 0x0006, z16       ) #normal form
wwd1 = Unum{4,6}(0x0000000000000000, 0x8000_0000_0000_0000, z16, 0x0005, z16       ) #5-subnormal form
wwd2 = Unum{4,6}(0x0000000000000000, 0x0000_8000_0000_0000, z16, 0x0004, UInt16(16)) #4-subnormal form
wwd3 = Unum{4,6}(0x0000000000000000, 0x0000_0080_0000_0000, z16, 0x0003, UInt16(24)) #3-subnormal form
wwd4 = Unum{4,6}(0x0000000000000000, 0x0000_0008_0000_0000, z16, 0x0002, UInt16(28)) #2-subnormal form

@test wwd0 == wwd1 && wwd1 == wwd2 && wwd2 == wwd3 && wwd3 == wwd4
@test wwd0 == wwd2 && wwd1 == wwd3 && wwd2 == wwd4
@test wwd0 == wwd3 && wwd1 == wwd4
@test wwd0 == wwd4

#let's make sure this works when we are using ulp-unums.
wwu0 = Unums.make_ulp!(copy(wwd0))
wwu1 = Unums.make_ulp!(copy(wwd1))
wwu2 = Unums.make_ulp!(copy(wwd2))
wwx1 = Unum{4,6}(0x0000000000000000, 0x8000_0000_0000_0000, Unums.UNUM_UBIT_MASK, 0x0005, UInt16(3)) #5-subnormal form
@test wwu0 != wwd0 && wwu1 != wwd1 && wwu2 != wwd2  #test that the ubits are not the same as the exact
@test wwu0 == wwu1 && wwu1 == wwu2 && wwu0 == wwu2  #test that the ubits are all the same as each other
@test wwx1 != wwu0 && wwx1 != wwu1 && wwx1 != wwu2  #but not if you move the fsize so that there are more bits.


#test to make sure that overlapping ubits provide the correct answer when passed
#to the min/max functions.
x = Unum{4,6}(0x0000000000000001, 0x0000000000000000, 0x0003, 0x0001, 0x0000)
y = Unum{4,6}(0x0000000000000001, 0x1000000000000000, 0x0003, 0x0001, 0x0003)

@test min(x, y) == x
@test max(x, y) == x

@test !(zero(Unum{4,6}) < zero(Unum{4,6}))
@test Unum{4,6}(6) < Unum{4,6}(7)
