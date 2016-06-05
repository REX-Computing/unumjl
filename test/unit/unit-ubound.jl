#unit-ubound.jl
#test that ubound constructors work

@devmode_on

#check to see that the safe ubound constructor fails on various invalid constructions.
@test_throws ArgumentError Ubound{0,0}(one(Unum{0,0}), zero(Unum{0,0}))
@test_throws ArgumentError Ubound{0,0}(one(Unum{0,0}), neg_one(Unum{0,0}))
@test_throws ArgumentError Ubound{0,0}(one(Unum{0,0}), neg_one(Unum{0,0}))

wtwo = Unum{0,0}(o64, z64, z16, z16, z16)
#check to see that the ubound constructors are okay.
@test_throws ArgumentError Ubound{0,0}(Ubound{0,0}(zero(Unum{0,0}), wtwo), one(Unum{0,0}))
#and conversely we have a problem in the other direction
@test_throws ArgumentError Ubound{0,0}(one(Unum{0,0}), Ubound{0,0}(zero(Unum{0,0}), wtwo))
#and check that strange, overlapping ubounds are not ok.
wnsome = Unum{0,0}(UInt64(0), UInt64(0), UInt16(3), z16, z16)
@test_throws ArgumentError Ubound{0,0}(Ubound{0,0}(wnsome, zero(Unum{0,0})), Ubound{0,0}(neg_one(Unum{0,0}), wtwo))

################################################################################
## open-ubound-helper:  A short function which returns the open interval version
## of a bounding unum for a ubound.
#=
# first test warlpiri one as a lower bound should yield walpiri some.
@test Unums.__open_ubound_helper(one(Unum{0,0}), true) == Unum{0,0}(z16, z16, o16, t64, z64)
# as an upper bound should yield walpiri few
@test Unums.__open_ubound_helper(one(Unum{0,0}), false) == Unum{0,0}(z16, z16, o16, z64, z64)
# check to see that warlpiri few is unchanged.
@test Unums.__open_ubound_helper(pos_sss(Unum{0,0}), true) == pos_sss(Unum{0,0})
@test Unums.__open_ubound_helper(pos_sss(Unum{0,0}), false) == pos_sss(Unum{0,0})
# let's do some awkward zero tests.
@test Unums.__open_ubound_helper(zero(Unum{0,0}), true) == pos_sss(Unum{0,0})
@test Unums.__open_ubound_helper(zero(Unum{0,0}), false) == neg_sss(Unum{0,0})
@test Unums.__open_ubound_helper(-zero(Unum{0,0}), true) == pos_sss(Unum{0,0})
@test Unums.__open_ubound_helper(-zero(Unum{0,0}), false) == neg_sss(Unum{0,0})
#and finally, test wierd infinities
#@test_throws ArgumentError Unums.__open_ubound_helper(pos_inf(Unum{0,0}), true)
#@test_throws ArgumentError Unums.__open_ubound_helper(neg_inf(Unum{0,0}), false)
@test Unums.__open_ubound_helper(pos_inf(Unum{0,0}), false) == pos_mmr(Unum{0,0})
@test Unums.__open_ubound_helper(neg_inf(Unum{0,0}), true) == neg_mmr(Unum{0,0})

################################################################################
## open-ubound:  Do we generate open ubounds correctly?

#first on warlpiri ubounds, are we correctly generating open ubounds?  Start
#doubly-closed end input.
uresult = Ubound(neg_sss(Unum{0,0}), pos_sss(Unum{0,0}))
@test open_ubound(zero(Unum{0,0}), one(Unum{0,0})) == pos_sss(Unum{0,0})
@test open_ubound(neg_one(Unum{0,0}), one(Unum{0,0})) == uresult
#half-open inputs
@test open_ubound(neg_sss(Unum{0,0}), one(Unum{0,0})) == uresult
@test open_ubound(neg_one(Unum{0,0}), pos_sss(Unum{0,0})) == uresult
#open inputs
@test open_ubound(neg_sss(Unum{0,0}), pos_sss(Unum{0,0})) == uresult
#in unum{1,1} test oddly overlapping ubounds. This is a ubound pair that looks
#as follows:
# (a)
# ( b )
# and should appropriately generate b as the ubound.
olu_b = Unum{1,1}(z16, z16, o16, z64, o64)
olu_a = Unum{1,1}(o16, z16, o16, z64, o64)
println(olu_b)
println(olu_a)
#println(open_ubound(olu_a, olu_b))
println(Unums.ubound_resolve(Ubound(olu_a, olu_b)))
@test open_ubound(olu_a, olu_b) == olu_b
=#

#testing throwing the development-safety flag.
@devmode_off

@restore_devmode
