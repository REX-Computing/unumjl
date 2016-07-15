#unit-boundstesting.jl
#testing that the endpoint bounds from unums conforms to the mathematical
#expectation
UT = Unum{3,5}

import Unums: inner_exact!, inner_ulp!, outer_exact!, outer_ulp!

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

#testing special ubound addition (NB: p. 113, TEoE).
#TOP TABLE
#top row, left to right.
@test left_neginf + left_neginf   == Ubound(neg_inf(UT), UT(-2))                #[-∞, -1] + [-∞, -1]  == [-∞, -2]
@test left_neginf + left_negmmr_b == Ubound(neg_inf(UT), UT(-2))                #[-∞, -1] + (-∞, -1]  == [-∞, -2]
@test left_neginf + left_negmmr_u == Ubound(neg_inf(UT), neg_mmr(UT))           #[-∞, -1] + (-∞, nmr) == [-∞, nmr)
@test left_neginf + left_exact    == Ubound(neg_inf(UT), UT(-2))                #[-∞, -1] + [-2, -1]  == [-∞, -2]
@test left_neginf + left_ulp      == Ubound(neg_inf(UT), UT(-2))                #[-∞, -1] + (-2, -1]  == [-∞, -2]
@test isequal(left_neginf + left_posinf, nan(UT))                               #[-∞, -1] + ∞  == NaN
#second row (ubound), left to right
@test left_negmmr_b + left_neginf   == Ubound(neg_inf(UT), UT(-2))              #(-∞, -1] + [-∞, -1]  == [-∞, -2]
@test left_negmmr_b + left_negmmr_b == Ubound(neg_mmr(UT), UT(-2))              #(-∞, -1] + (-∞, -1]  == (-∞, -2]
@test left_negmmr_b + left_negmmr_u == neg_mmr(UT)                              #(-∞, -1] + (-∞, nmr) == (-∞, nmr)
@test left_negmmr_b + left_exact    == Ubound(neg_mmr(UT), UT(-2))              #(-∞, -1] + [-2, -1]  == (-∞, -2]
@test left_negmmr_b + left_ulp      == Ubound(neg_mmr(UT), UT(-2))              #(-∞, -1] + (-2, -1]  == (-∞, -2]
@test left_negmmr_b + left_posinf   == pos_inf(UT)                              #(-∞, -1] + ∞  == ∞
#second row (unum), left to right
@test left_negmmr_u + left_neginf   == Ubound(neg_inf(UT), neg_mmr(UT))         #(-∞, nmr) + [-∞, -1]  == [-∞, nmr)
@test left_negmmr_u + left_negmmr_b == neg_mmr(UT)                              #(-∞, nmr) + (-∞, -1]  == (-∞, nmr)
@test left_negmmr_u + left_negmmr_u == neg_mmr(UT)                              #(-∞, nmr) + (-∞, nmr) == (-∞, nmr)
@test left_negmmr_u + left_exact    == neg_mmr(UT)                              #(-∞, nmr) + [-2, -1]  == (-∞, nmr)
@test left_negmmr_u + left_ulp      == neg_mmr(UT)                              #(-∞, nmr) + (-2, -1]  == (-∞, nmr)
@test left_negmmr_u + left_posinf   == pos_inf(UT)                              #(-∞, nmr) + ∞  == ∞
#third row, left to right
@test left_exact + left_neginf   == Ubound(neg_inf(UT), UT(-2))                 #[-2, -1] + [-∞, -1]  == [-∞, -2]
@test left_exact + left_negmmr_b == Ubound(neg_mmr(UT), UT(-2))                 #[-2, -1] + (-∞, -1]  == (-∞, -2]
@test left_exact + left_negmmr_u == neg_mmr(UT)                                 #[-2, -1] + (-∞, nmr) == (-∞, nmr)
@test left_exact + left_exact    == Ubound(UT(-4), UT(-2))                      #[-2, -1] + [-2, -1]  == [-4, -2]
@test left_exact + left_ulp      == Ubound(inner_ulp!(UT(-4)), UT(-2))          #[-2, -1] + (-2, -1]  == (-4, -2]
@test left_exact + left_posinf   == pos_inf(UT)                                 #[-2, -1] + ∞  == ∞
#fourth row, left to right
@test left_ulp + left_neginf   == Ubound(neg_inf(UT), UT(-2))                   #(-2, -1] + [-∞, -1]  == [-∞, -2]
@test left_ulp + left_negmmr_b == Ubound(neg_mmr(UT), UT(-2))                   #(-2, -1] + (-∞, -1]  == (-∞, -2]
@test left_ulp + left_negmmr_u == neg_mmr(UT)                                   #(-2, -1] + (-∞, nmr) == (-∞, nmr)
@test left_ulp + left_exact    == Ubound(inner_ulp!(UT(-4)), UT(-2))            #(-2, -1] + [-2, -1]  == (-4, -2]
@test left_ulp + left_ulp      == Ubound(inner_ulp!(UT(-4)), UT(-2))            #(-2, -1] + (-2, -1]  == (-4, -2]
@test left_ulp + left_posinf   == pos_inf(UT)                                   #(-2, -1] + ∞  == ∞
#fifth row, left to right
@test isequal(left_posinf + left_neginf, nan(UT))                               #∞ + [-∞, -1]  == NaN
@test left_posinf + left_negmmr_b == pos_inf(UT)                                #∞ + (-∞, -1]  == ∞
@test left_posinf + left_negmmr_u == pos_inf(UT)                                #∞ + (-∞, nmr) == ∞
@test left_posinf + left_exact    == pos_inf(UT)                                #∞ + [-2, -1]  == ∞
@test left_posinf + left_ulp      == pos_inf(UT)                                #∞ + (-2, -1]  == ∞
@test left_posinf + left_posinf   == pos_inf(UT)                                #∞ + ∞  == ∞

#BOTTOM TABLE
#top row, left to right.
@test right_neginf + right_neginf   == neg_inf(UT)                              #-∞ + -∞      == -∞
@test right_neginf + right_ulp      == neg_inf(UT)                              #-∞ + [1, 2)  == -∞
@test right_neginf + right_exact    == neg_inf(UT)                              #-∞ + [1, 2]  == -∞
@test right_neginf + right_posmmr_u == neg_inf(UT)                              #-∞ + (mr, ∞) == -∞
@test right_neginf + right_posmmr_b == neg_inf(UT)                              #-∞ + [1, ∞]  == -∞
@test isequal(right_neginf + right_posinf, nan(UT))                             #-∞ + ∞       == NaN
#second row, left to right.
@test right_ulp + right_neginf   == neg_inf(UT)                                 #[1, 2) + -∞      == -∞
@test right_ulp + right_ulp      == Ubound(UT(2), inner_ulp!(UT(4)))            #[1, 2) + [1, 2)  == [2, 4)
@test right_ulp + right_exact    == Ubound(UT(2), inner_ulp!(UT(4)))            #[1, 2) + [1, 2]  == [2, 4)
@test right_ulp + right_posmmr_u == pos_mmr(UT)                                 #[1, 2) + (mr, ∞) == (mr, ∞)
@test right_ulp + right_posmmr_b == Ubound(UT(2), pos_mmr(UT))                  #[1, 2) + [1, ∞)  == [2, ∞)
@test right_ulp + right_posinf   == Ubound(UT(2), pos_inf(UT))                  #[1, 2) + [1 ,∞]  == [2, ∞]
#third row, left to right.
@test right_exact + right_neginf   == neg_inf(UT)                               #[1, 2] + -∞      == -∞
@test right_exact + right_ulp      == Ubound(UT(2), inner_ulp!(UT(4)))          #[1, 2] + [1, 2)  == [2, 4)
@test right_exact + right_exact    == Ubound(UT(2), UT(4))                      #[1, 2] + [1, 2]  == [2, 4]
@test right_exact + right_posmmr_u == pos_mmr(UT)                               #[1, 2] + (mr, ∞) == (mr, ∞)
@test right_exact + right_posmmr_b == Ubound(UT(2), pos_mmr(UT))                #[1, 2] + [1, ∞)  == [2, ∞)
@test right_exact + right_posinf   == Ubound(UT(2), pos_inf(UT))                #[1, 2] + [1 ,∞]  == [2, ∞]
#fourth row (unum), left to right.
@test right_posmmr_u + right_neginf   == neg_inf(UT)                            #(mr, ∞) + -∞      == -∞
@test right_posmmr_u + right_ulp      == pos_mmr(UT)                            #(mr, ∞) + [1, 2)  == (mr, ∞)
@test right_posmmr_u + right_exact    == pos_mmr(UT)                            #(mr, ∞) + [1, 2]  == (mr, ∞)
@test right_posmmr_u + right_posmmr_u == pos_mmr(UT)                            #(mr, ∞) + (mr, ∞) == (mr, ∞)
@test right_posmmr_u + right_posmmr_b == pos_mmr(UT)                            #(mr, ∞) + [1, ∞)  == (mr, ∞)
@test right_posmmr_u + right_posinf   == Ubound(pos_mmr(UT), pos_inf(UT))       #(mr, ∞) + [1 ,∞]  == (mr, ∞]
#fourth row (ubound), left to right.
@test right_posmmr_b + right_neginf   == neg_inf(UT)                            #[1, ∞) + -∞      == -∞
@test right_posmmr_b + right_ulp      == Ubound(UT(2), pos_mmr(UT))             #[1, ∞) + [1, 2)  == [2, ∞)
@test right_posmmr_b + right_exact    == Ubound(UT(2), pos_mmr(UT))             #[1, ∞) + [1, 2]  == [2, ∞)
@test right_posmmr_b + right_posmmr_u == pos_mmr(UT)                            #[1, ∞) + (mr, ∞) == (mr, ∞)
@test right_posmmr_b + right_posmmr_b == Ubound(UT(2), pos_mmr(UT))             #[1, ∞) + [1, ∞)  == [2, ∞)
@test right_posmmr_b + right_posinf   == Ubound(UT(2), pos_inf(UT))             #[1, ∞) + [1 ,∞]  == [2, ∞]
#fifth row, left to right.
@test isequal(right_posinf + right_neginf, nan(UT))                             #[1, ∞] + -∞      == NaN
@test right_posinf + right_ulp      == Ubound(UT(2), pos_inf(UT))               #[1, ∞] + [1, 2)  == [2, ∞]
@test right_posinf + right_exact    == Ubound(UT(2), pos_inf(UT))               #[1, ∞] + [1, 2]  == [2, ∞]
@test right_posinf + right_posmmr_u == Ubound(pos_mmr(UT), pos_inf(UT))         #[1, ∞] + (mr, ∞) == (mr, ∞]
@test right_posinf + right_posmmr_b == Ubound(UT(2), pos_inf(UT))               #[1, ∞] + [1, ∞)  == [2, ∞]
@test right_posinf + right_posinf   == Ubound(UT(2), pos_inf(UT))               #[1, ∞] + [1, ∞]  == [2, ∞]

#testing special ubound multiplication (NB: p. 130, TEoE)
left_zero_exact = Ubound(UT(0), UT(1))
left_zero_ulp_b = Ubound(sss(UT), UT(1))
left_zero_ulp_u = sss(UT)
left_pos_exact  = Ubound(UT(1), UT(2))
left_pos_ulp    = Ubound(outer_ulp!(UT(1)), UT(2))

right_zero = zero(UT)
#TOP TABLE
#top row, left to right.
@test left_zero_exact * left_zero_exact == Ubound(UT(0), UT(1))                 #[0, 1] * [0, 1]   == [0, 1]
@test left_zero_exact * left_zero_ulp_b == Ubound(UT(0), UT(1))                 #[0, 1] * (0, 1]   == [0, 1]
@test left_zero_exact * left_zero_ulp_u == Ubound(UT(0), sss(UT))               #[0, 1] * (0, ssn) == [0, ssn)
@test left_zero_exact * left_pos_exact  == Ubound(UT(0), UT(2))                 #[0, 1] * [1, 2]   == [0, 2]
@test left_zero_exact * left_pos_ulp    == Ubound(UT(0), UT(2))                 #[0, 1] * (1, 2]   == [0, 2]
@test isequal(left_zero_exact * left_posinf, nan(UT))                           #[0, 1] * ∞        == NaN
#second row (ubound), left to right.
@test left_zero_ulp_b * left_zero_exact == Ubound(UT(0), UT(1))                 #(0, 1] * [0, 1]   == [0, 1]
@test left_zero_ulp_b * left_zero_ulp_b == Ubound(sss(UT), UT(1))               #(0, 1] * (0, 1]   == (0, 1]
@test left_zero_ulp_b * left_zero_ulp_u == sss(UT)                              #(0, 1] * (0, ssn) == (0, ssn)
@test left_zero_ulp_b * left_pos_exact  == Ubound(sss(UT), UT(2))               #(0, 1] * [1, 2]   == (0, 2]
@test left_zero_ulp_b * left_pos_ulp    == Ubound(sss(UT), UT(2))               #(0, 1] * (1, 2]   == (0, 2]
@test left_zero_ulp_b * left_posinf     == inf(UT)                              #(0, 1] * ∞        == ∞
#second row (unum), left to right.
ssn2 = Unum{3,5}(z64, z64, o16, 0x0007, 0x001e)
@test left_zero_ulp_u * left_zero_exact == Ubound(UT(0), sss(UT))               #(0, ssn) * [0, 1]   == [0, ssn)
@test left_zero_ulp_u * left_zero_ulp_b == sss(UT)                              #(0, ssn) * (0, 1]   == (0, ssn)
@test left_zero_ulp_u * left_zero_ulp_u == sss(UT)                              #(0, ssn) * (0, ssn) == (0, ssn)
@test left_zero_ulp_u * left_pos_exact  == ssn2                                 #(0, ssn) * [1, 2]   == (0, 2*ssn)
@test left_zero_ulp_u * left_pos_ulp    == ssn2                                 #(0, ssn) * (1, 2]   == (0, 2*ssn)
@test left_zero_ulp_u * left_posinf     == inf(UT)                              #(0, ssn) * ∞        == ∞
#third row, left to right.
@test left_pos_exact * left_zero_exact == Ubound(UT(0), UT(2))                  #[1, 2] * [0, 1]   == [0, 2]
@test left_pos_exact * left_zero_ulp_b == Ubound(sss(UT), UT(2))                #[1, 2] * (0, 1]   == (0, 2]
@test left_pos_exact * left_zero_ulp_u == ssn2                                  #[1, 2] * (0, ssn) == (0, 2 * ssn)
@test left_pos_exact * left_pos_exact  == Ubound(UT(1), UT(4))                  #[1, 2] * [1, 2]   == [1, 4]
@test left_pos_exact * left_pos_ulp    == Ubound(outer_ulp!(UT(1)), UT(4))      #[1, 2] * (1, 2]   == (1, 4]
@test left_pos_exact * left_posinf     == inf(UT)                               #[1, 2] * ∞        == ∞
#fourth row, left to right.
@test left_pos_ulp * left_zero_exact == Ubound(UT(0), UT(2))                    #(1, 2] * [0, 1]   == [0, 2]
@test left_pos_ulp * left_zero_ulp_b == Ubound(sss(UT), UT(2))                  #(1, 2] * (0, 1]   == (0, 2]
@test left_pos_ulp * left_zero_ulp_u == ssn2                                    #(1, 2] * (0, ssn) == (0, 2* ssn)
@test left_pos_ulp * left_pos_exact  == Ubound(outer_ulp!(UT(1)), UT(4))        #(1, 2] * [1, 2]   == (1, 4]
@test left_pos_ulp * left_pos_ulp    == Ubound(outer_ulp!(UT(1)), UT(4))        #(1, 2] * (1, 2]   == (1, 4]
@test left_pos_ulp * left_posinf     == inf(UT)                                 #(1, 2] * ∞        == ∞
#fifth row, left to right.
@test left_posinf * left_zero_exact == Ubound(UT(0), UT(2))                     #∞ * [0, 1]   == NaN
@test left_posinf * left_zero_ulp_b == Ubound(sss(UT), UT(2))                   #∞ * (0, 1]   == ∞
@test left_posinf * left_zero_ulp_u == sss(UT)                                  #∞ * (0, ssn) == ∞
@test left_posinf * left_pos_exact  == Ubound(outer_ulp!(UT(1)), UT(4))         #∞ * [1, 2]   == ∞
@test left_posinf * left_pos_ulp    == Ubound(outer_ulp!(UT(1)), UT(4))         #∞ * (1, 2]   == ∞
@test left_posinf * left_posinf     == inf(UT)                                  #∞ * ∞        == ∞

#BOTTOM TABLE
#top row, left to right.


#testing special ubound division (NB: p. 138, TEoE)
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
