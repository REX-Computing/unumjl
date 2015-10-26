#ubound-properties.jl

is_mmr(b::Ubound) = is_mmr(b.lowbound) || is_mmr(b.highbound)
is_ssn(b::Ubound) = is_ssn(b.lowbound) || is_ssn(b.highbound)
is_inf(b::Ubound) = is_inf(b.lowbound) || is_inf(b.highbound)
is_allreal(b::Ubound) = (is_mmr(b.lowbound) || is_inf(b.lowbound)) && (is_mmr(b.highbound) || is_inf(b.highbound))

#generally speaking, builtin constructs should not generate this
#situation, but we present it here for completeness purposes.
is_nan(b::Ubound) = is_nan(b.lowbound) || is_nan(b.highbound)

export is_mmr, is_ssn, is_nan
