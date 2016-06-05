abstract Ubound{ESS,FSS} <: Real

function __check_UboundSmall{ESS, FSS}(_ESS, _FSS, lower::UnumSmall{ESS,FSS}, upper::UnumSmall{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

@dev_check type UboundSmall{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumSmall{ESS,FSS}
  upper::UnumSmall{ESS,FSS}
end

#overload the call dispatches for naked ubound types.
@universal function call(T::Type{Ubound{ESS,FSS}}, x::Unum, y::Unum)
  B(x, y)
end

#an empty constructor defaults to the extended real line.
function call{ESS,FSS}(::Type{Ubound{ESS,FSS}})
  if FSS < 7
    UboundSmall{ESS,FSS}(neg_inf(UnumSmall{ESS,FSS}), pos_inf(UnumSmall{ESS,FSS}))
  else
    UboundLarge{ESS,FSS}(neg_inf(UnumLarge{ESS,FSS}), pos_inf(UnumLarge{ESS,FSS}))
  end
end

function __check_UboundLarge{ESS,FSS}(_ESS, _FSS, lower::UnumLarge{ESS,FSS}, upper::UnumLarge{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

@dev_check type UboundLarge{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumLarge{ESS,FSS}
  upper::UnumLarge{ESS,FSS}
end

export Ubound
