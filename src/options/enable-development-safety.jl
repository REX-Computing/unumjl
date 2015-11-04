#options/disable-development-safety.jl
#include this file to disable development safety.

Unums.__check_unum_param_dev(ESS::Integer, FSS::Integer, fsize::UInt16, esize::UInt16, fraction, exponent::UInt64) =
  Unums.__check_unum_param(ESS, FSS, fsize, esize, fraction, exponent)

Unums.__check_ubound_param_dev{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) =
  Unums.__check_ubound_param(a, b)

Unums.__check_ubound_param_upperbound_dev{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) =
  Unums.__check_ubound_param_upperbound(a, b)

Unums.__check_ubound_param_lowerbound_dev{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) =
  Unums.__check_ubound_param_lowerbound(a, b)

Unums.__check_frac_trim_dev(l::Int, fsize::UInt16) =
  Unums.__check_frac_trim(l, fsize)
