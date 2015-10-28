#unit-ubound.jl
#test that ubound constructors work

#check to see that the safe ubound constructor fails on various invalid constructions.
@test_throws ArgumentError ubound(one(Unum{0,0}), zero(Unum{0,0}))
@test_throws ArgumentError ubound(one(Unum{0,0}), neg_one(Unum{0,0}))

Unums.unset_option("development-safety")

Unums.set_option("development-safety")
