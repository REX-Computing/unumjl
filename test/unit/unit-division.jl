#unum-test-division.jl

#some simple tests in Unum{4,5}
x = Unum{4,5}(30.0)
y = Unum{4,5}(1.5)
z = (x / y)
@test is_exact(z)
@test calculate(z) == 20.0

x = Unum{4,6}(30.0)
y = Unum{4,6}(1.5)
z = (x / y)
@test is_exact(z)
@test calculate(z) == 20.0

x = Unum{4,7}(30.0)
y = Unum{4,7}(1.5)
z = (x / y)
@test is_exact(z)
@test calculate(z) == 20.0

x = Unum{4,8}(30.0)
y = Unum{4,8}(1.5)
z = (x / y)
@test is_exact(z)
@test calculate(x / y) == 20.0

x = Unums.make_exact!(Unum{4,5}(1) / Unum{4,5}(3))
@test (x / x) == one(Unum{4,5})

x = Unums.make_exact!(Unum{4,6}(1) / Unum{4,6}(3))
@test (x / x) == one(Unum{4,6})

x = Unum{4,7}(1.0) / Unum{4,7}(3.0)
@test x == Unum{4,7}(0x0000000000000001, UInt64[0x5555555555555555,0x5555555555555555], 0x0001, 0x0002, 0x007f)
Unums.make_exact!(x)
@test (x / x) == one(Unum{4,7})
