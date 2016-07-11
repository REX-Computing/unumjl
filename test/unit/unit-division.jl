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

#testing special ubound division (NB: p. 138, TEoE).
UT = Unum{3,5}

################################################################################
## TOP chart, left -> right, top -> bottom
x = Ubound(UT(0), UT(1))
y = Ubound(UT(-1), UT(0))
@test x / y == Ubound(neg_inf(UT), UT(0))
y = Ubound(UT(1), Unums.inner_ulp!(UT(2)))
@test x / y == Ubound(UT(0), UT(1))
y = Ubound(UT(1), UT(2))
@test x / y == Ubound(UT(0), UT(1))
y = Ubound(UT(1), mmr(UT))
@test x / y == Ubound(UT(0), UT(1))
y = Ubound(UT(1), inf(UT))
@test x / y == Ubound(UT(0), UT(1))
################################################################################
x = Ubound(sss(UT), UT(1))
y = Ubound(UT(-1), UT(0))
@test x / y == Ubound(neg_inf(UT), neg_sss(UT))
y = Ubound(UT(1), Unums.inner_ulp!(UT(2)))
@test x / y == Ubound(sss(UT), UT(1))
y = Ubound(UT(1), UT(2))
@test x / y == Ubound(sss(UT), UT(1))
y = Ubound(UT(1), mmr(UT))
@test x / y == Ubound(sss(UT), UT(1))
y = Ubound(UT(1), inf(UT))
@test x / y == Ubound(UT(0), UT(1))
################################################################################
x = Ubound(UT(1), UT(2))
y = Ubound(UT(-1), UT(0))
@test x / y == Ubound(neg_inf(UT), UT(-1))
y = Ubound(UT(1), Unums.inner_ulp!(UT(2)))
@test x / y == Ubound(Unums.outer_ulp!(UT(0.5)), UT(2))   #[1,2] / [1,2) == (1/2, 2]
y = Ubound(Unums.outer_ulp!(UT(1)), mmr(UT))
@test x / y == Ubound(sss(UT), Unums.inner_ulp!(UT(2)))   #[1,2] / (1, inf) == (0, 2)
y = Ubound(UT(1), mmr(UT))
@test x / y == Ubound(sss(UT), UT(2))                     #[1,2] / [1, inf) == (0, 2]
y = Ubound(UT(1), inf(UT))
@test x / y == Ubound(UT(0), UT(2))                       #[1,2] / [1, inf] = [0, 2]
