#unit-ubound.jl
#test that ubound constructors work

#check to see that the safe ubound constructor fails on various invalid constructions.
@test_throws ArgumentError ubound(one(Unum{0,0}), zero(Unum{0,0}))
@test_throws ArgumentError ubound(one(Unum{0,0}), neg_one(Unum{0,0}))
@test_throws ArgumentError ubound(one(Unum{0,0}), neg_one(Unum{0,0}))

z16 = zero(Uint16)
o16 = one(Uint16)
z64 = zero(Uint64)
o64 = one(Uint64)
t64 = 0x8000_0000_0000_0000

wtwo = Unum{0,0}(z16, z16, z16, z64, o64)
#check to see that the ubound constructors are okay.
@test_throws ArgumentError ubound(ubound(zero(Unum{0,0}), wtwo), one(Unum{0,0}))
#and conversely we have a problem in the other direction
@test_throws ArgumentError ubound(one(Unum{0,0}), ubound(zero(Unum{0,0}), wtwo))
#and check that strange, overlapping ubounds are not ok.
wnsome = Unum{0,0}(z16, z16, uint16(3), uint64(0), uint64(0))
@test_throws ArgumentError ubound(ubound(wnsome, zero(Unum{0,0})), ubound(neg_one(Unum{0,0}), wtwo))

################################################################################
## open-ubound-helper:  A short function which returns the open interval version
## of a bounding unum for a ubound.

# first test warlpiri one as a lower bound should yield walpiri some.
@test Unums.__open_ubound_helper(one(Unum{0,0}), true) == Unum{0,0}(z16, z16, o16, t64, z64)
# as an upper bound should yield walpiri few
println(Unums.__open_ubound_helper(one(Unum{0,0}), false))
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


#testing throwing the development-safety flag.
Unums.unset_option("development-safety")

Unums.set_option("development-safety")
