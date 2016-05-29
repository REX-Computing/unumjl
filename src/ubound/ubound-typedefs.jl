abstract Ubound{ESS,FSS} <: Real

function __check_UboundSmall{ESS, FSS}(_ESS, _FSS, lower::UnumSmall{ESS,FSS}, upper::UnumSmall{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

@dev_check type UboundSmall{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumSmall{ESS,FSS}
  upper::UnumSmall{ESS,FSS}
end

function call{ESS,FSS}(::Type{Ubound{ESS,FSS}}, x::UnumSmall{ESS,FSS}, y::UnumSmall{ESS,FSS})
  UboundSmall{ESS,FSS}(UnumSmall{ESS,FSS}(x), UnumSmall{ESS,FSS}(y))
end

#an empty constructor defaults to the extended real line.
@generated function call{ESS,FSS}(::Type{Ubound{ESS,FSS}})
  if FSS < 7
    :(UboundSmall{ESS,FSS}(neg_inf(Unum{ESS,FSS}), pos_inf(Unum{ESS,FSS})))
  else
    :(UboundLarge{ESS,FSS}(neg_inf(Unum{ESS,FSS}), pos_inf(Unum{ESS,FSS})))
  end
end

function __check_UboundLarge{ESS,FSS}(_ESS, _FSS, lower::UnumLarge{ESS,FSS}, upper::UnumLarge{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

@dev_check type UboundLarge{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumLarge{ESS,FSS}
  upper::UnumLarge{ESS,FSS}
end

function call{ESS,FSS}(::Type{Ubound{ESS,FSS}}, x::UnumLarge{ESS,FSS}, y::UnumLarge{ESS,FSS})
  UboundLarge{ESS,FSS}(UnumLarge{ESS,FSS}(x), UnumLarge{ESS,FSS}(y))
end

export Ubound
