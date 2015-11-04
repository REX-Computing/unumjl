#options/disable-development-safety.jl

Unums.__check_unum_param_dev(ESS::Integer, FSS::Integer, fsize::UInt16, esize::UInt16, fraction, exponent::UInt64) = nothing
Unums.__check_ubound_param_dev{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = nothing
Unums.__check_ubound_param_upperbound_dev{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = nothing
Unums.__check_ubound_param_lowerbound_dev{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = nothing
