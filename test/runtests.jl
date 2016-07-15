using Unums
using Base.Test

@unumbers

include("./test-infrastructure.jl")
include("./test-operations.jl")
include("./test-warlpiri.jl")

#=
import Unums: inner_exact!, inner_ulp!, outer_exact!, outer_ulp!

UT = Unum{3, 4}

left_neginf =   Ubound(neg_inf(UT), UT(-1))
left_negmmr_b = Ubound(neg_mmr(UT), UT(-1))
left_negmmr_u = neg_mmr(UT)
left_exact =    Ubound(UT(-2), UT(-1))
left_ulp =      Ubound(inner_ulp!(UT(-2)), UT(-1))
left_posinf =   inf(UT)

right_neginf =   neg_inf(UT)
right_ulp =      Ubound(UT(1), inner_ulp!(UT(2)))
right_exact =    Ubound(UT(1), UT(2))
right_posmmr_u = mmr(UT)
right_posmmr_b = Ubound(UT(1), mmr(UT))
right_posinf =   Ubound(UT(1), inf(UT))

#testing special ubound multiplication (NB: p. 130, TEoE)
left_zero_exact = Ubound(UT(0), UT(1))
left_zero_ulp_b = Ubound(sss(UT), UT(1))
left_zero_ulp_u = sss(UT)
left_pos_exact  = Ubound(UT(1), UT(2))
left_pos_ulp    = Ubound(outer_ulp!(UT(1)), UT(2))

r = left_zero_ulp_u * left_pos_exact

println(r)
describe(r)
=#
