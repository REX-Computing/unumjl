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

  unum_unsafe(Unum{T, x.fsize, x.esize, x.flags, x.fraction, x.exponent)
end

function promote_fss{ESS,FSS}(x::Unum{ESS,FSS})
  T = Unum{ESS, FSS + 1}
  is_pos_inf(x) && return pos_inf(T)
  is_neg_inf(x) && return neg_inf(T)
  unum_unsafe(Unum{ESS,FSS + 1}, x.fsize, x.esize, x.flags, x.fraction, x.exponent)
end
