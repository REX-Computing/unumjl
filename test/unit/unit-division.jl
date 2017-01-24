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

################################################################################
# test with ubounds
x = Ubound(Unum{4,6}(6), Unum{4,6}(7))
y = Unum{4,6}(3)
@test (x / y) == Ubound(Unum{4,6}(2), Unum{4,6}(7) / Unum{4,6}(3))

################################################################################
# discovered errors.

#as a result of matrix solving.  Jan 2017

x = Unum{3,5}(0x0000000000000001, 0x0000000000000000, 0x0000, 0x0001, 0x0000)
y = Ubound(Unum{3,5}(0x000000000000000F, 0x373FE2B700000000, 0x0001, 0x0003, 0x001F), Unum{3,5}(0x000000000000000F, 0x373FE2D800000000, 0x0001, 0x0003, 0x001E))

@test (x / y) == Ubound(Unum{3,5}(0x0000000000000006, 0xA51D8EDD00000000, 0x0001, 0x0004, 0x001F), Unum{3,5}(0x0000000000000006, 0xA51D8F0C00000000, 0x0001, 0x0004, 0x001F))

x = Ubound(Unum{3,5}(0x0000000000000031, 0x77A419CC00000000, 0x0003, 0x0005, 0x001F), Unum{3,5}(0x0000000000000031, 0x77A4195000000000, 0x0003, 0x0005, 0x001F))
y = Ubound(Unum{3,5}(0x0000000000000018, 0x071A55DD00000000, 0x0003, 0x0004, 0x001F), Unum{3,5}(0x0000000000000018, 0x071A55D200000000, 0x0003, 0x0004, 0x001F))
@test (x / y) ==  Ubound(Unum{3,5}(0x0000000000000018, 0x6D7FFFB800000000, 0x0001, 0x0004, 0x001D), Unum{3,5}(0x0000000000000018, 0x6D80004000000000, 0x0001, 0x0004, 0x001D))

#more parity errors

x = Ubound(Unum{3,5}(0x0000000000000030, 0xDD99D88C00000000, 0x0003, 0x0005, 0x001E), Unum{3,5}(0x0000000000000030, 0xDD99D87800000000, 0x0003, 0x0005, 0x001D))
y = Ubound(Unum{3,5}(0x0000000000000018, 0x1BADF0DB00000000, 0x0001, 0x0004, 0x001F), Unum{3,5}(0x0000000000000018, 0x1BADF0DC00000000, 0x0001, 0x0004, 0x001D))

@test x / y == Ubound(Unum{3,5}(0x000000000000000F, 0xAF00000800000000, 0x0003, 0x0003, 0x001D), Unum{3,5}(0x000000000000000F, 0xAEFFFFF000000000, 0x0003, 0x0003, 0x001F))
