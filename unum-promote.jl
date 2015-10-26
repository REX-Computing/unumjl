#Copyright (c) 2015 Rex Computing and Isaac Yonemoto
#see LICENSE.txt
#this work was supported in part by DARPA Contract D15PC00135
#unum-promote.jl

#implements a "promotion" function.  This converts a Unum of a particular environment
#and promotes it to a unum of one successive environment.

function promote_ess{ESS,FSS}(x::Unum{ESS,FSS})
  T = Unum{ESS + 1, FSS}
  B = Ubound{ESS + 1, FSS}
  is_pos_inf(x) && return pos_inf(T)
  is_neg_inf(x) && return neg_inf(T)
  is_pos_mmr(x) && return B(unum_unsafe(T, x.fsize, x.esize, x.flags, x.fraction, x.exponent), pos_mmr(T))
  is_neg_mmr(x) && return B(neg_mmr(T), unum_unsafe(T, x.fsize, x.esize, x.flags, x.fraction, x.exponent))
  is_pos_sss(x) && return B(pos_sss(T), unum_unsafe(T, x.fsize, x.esize, x.flags, x.fraction, x.exponent))
  is_neg_sss(x) && return B(unum_unsafe(T, x.fsize, x.esize, x.flags, x.fraction, x.exponent), neg_sss(T))

  unum_unsafe(T, x.fsize, x.esize, x.flags, x.fraction, x.exponent)
end

#promote_ess with evaluation of the binary function when observing the mmr and sss.
function promote_ess{ESS,FSS}(bf, x::Unum{ESS,FSS})
  T = Unum{ESS + 1, FSS}
  B = Ubound{ESS + 1, FSS}
  is_pos_inf(x) && return pos_inf(T)
  is_neg_inf(x) && return neg_inf(T)
  is_pos_mmr(x) && return expwalk(bf, ESS+1, FSS, max_exponent(ESS), max_exponent(ESS+1), z16)
  is_neg_mmr(x) && return expwalk(bf, ESS+1, FSS, max_exponent(ESS), max_exponent(ESS+1), UNUM_SIGN_MASK)

  is_pos_sss(x) && return [expwalk(bf, ESS+1, FSS, min_exponent(ESS + 1), min_exponent(ESS), z16),            subnormalwalk(bf, ESS+1, FSS, z16)]
  is_neg_sss(x) && return [expwalk(bf, ESS+1, FSS, min_exponent(ESS + 1), min_exponent(ESS), UNUM_SIGN_MASK), subnormalwalk(bf, ESS+1, FSS, UNUM_SIGN_MASK)]
  testval = unum_unsafe(T, x.fsize, x.esize, x.flags, x.fraction, x.exponent)
  bf(testval) ? [testval] : []
end

function promote_fss{ESS,FSS}(x::Unum{ESS,FSS})
  T = Unum{ESS, FSS + 1}
  is_pos_inf(x) && return pos_inf(T)
  is_neg_inf(x) && return neg_inf(T)
  unum_unsafe(T, x.fsize, x.esize, x.flags, x.fraction, x.exponent)
end
