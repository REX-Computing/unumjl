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
