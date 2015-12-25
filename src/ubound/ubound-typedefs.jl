type Ubound{ESS,FSS} <: Utype
  lower::Unum{ESS,FSS}
  upper::Unum{ESS,FSS}
end
export Ubound
