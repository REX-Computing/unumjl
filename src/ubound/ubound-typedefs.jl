abstract Ubound{ESS,FSS} <: Utype

type UboundSmall{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumSmall{ESS,FSS}
  upper::UnumSmall{ESS,FSS}
end

function call{ESS,FSS}(::Type{Ubound{ESS,FSS}}, x::UnumSmall{ESS,FSS}, y::UnumSmall{ESS,FSS})
  UboundSmall{ESS,FSS}(x, y)
end

type UboundLarge{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumLarge{ESS,FSS}
  upper::UnumLarge{ESS,FSS}
end

function call{ESS,FSS}(::Type{Ubound{ESS,FSS}}, x::UnumLarge{ESS,FSS}, y::UnumLarge{ESS,FSS})
  UboundLarge{ESS,FSS}(x, y)
end

export Ubound
