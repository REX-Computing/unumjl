#unum-test-division.jl

#some simple tests in Unum{4,5}
x = Unum{4,5}(30.0)
y = Unum{4,5}(1.5)

@test calculate(x / y) == 20.0
