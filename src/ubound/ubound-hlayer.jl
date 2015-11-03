function describe{ESS,FSS}(b::Ubound{ESS,FSS}, s=" ")
  highval = is_ulp(b.highbound) ? next_exact(b.highbound) : b.highbound
  hightext = is_pos_mmr(b.highbound) ? "mmr{$ESS, $FSS}" : string(calculate(highval))
  hightext = is_pos_sss(b.highbound) ? "sss{$ESS, $FSS}" : hightext
  hightext = is_neg_sss(b.highbound) ? "-sss{$ESS, $FSS}" : hightext
  lowval = is_ulp(b.lowbound) ? prev_exact(b.lowbound) : b.lowbound
  lowtext = is_neg_mmr(b.lowbound) ? "-mmr{$ESS, $FSS}" : string(calculate(lowval))
  lowtext = is_pos_sss(b.lowbound) ? "sss{$ESS, $FSS}" : lowtext
  lowtext = is_neg_sss(b.lowbound) ? "-sss{$ESS, $FSS}" : lowtext
  string("$(bits(b.lowbound, s)) -> $(bits(b.highbound, s)) (aka ", lowtext, " -> ", hightext ," )")
end

import Base.bits
bits(b::Ubound) = describe(b, "")
export bits
