#unum-test-division.jl

#some simple tests in Unum{4,5}
x = Unum{4,5}(30.0)
y = Unum{4,5}(1.5)

@test calculate(x / y) == 20.0

x = Unums.make_exact!(Unum{4,5}(1) / Unum{4,5}(3))
@test (x / x) == one(Unum{4,5})
