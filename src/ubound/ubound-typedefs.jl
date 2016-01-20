abstract Ubound{ESS,FSS} <: Utype

function __check_UboundSmall{ESS, FSS}(lower::UnumSmall{ESS,FSS}, upper::UnumSmall{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

type UboundSmall{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumSmall{ESS,FSS}
  upper::UnumSmall{ESS,FSS}
  @dev_check function UboundSmall(lower, upper)
    new(lower, upper)
  end
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

function __check_UboundLarge{ESS,FSS}(lower::UnumLarge{ESS,FSS}, upper::UnumLarge{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

type UboundLarge{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumLarge{ESS,FSS}
  upper::UnumLarge{ESS,FSS}
  @dev_check function UboundLarge(lower::UnumLarge{ESS,FSS}, upper::UnumLarge{ESS,FSS})
    new(lower, upper)
  end
end

function call{ESS,FSS}(::Type{Ubound{ESS,FSS}}, x::UnumLarge{ESS,FSS}, y::UnumLarge{ESS,FSS})
  UboundLarge{ESS,FSS}(UnumLarge{ESS,FSS}(x), UnumLarge{ESS,FSS}(y))
end

export Ubound
