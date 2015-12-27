Base.bits(b::Ubound) = string("$(bits(b.lower)) -> $(bits(b.upper))")

function Base.show{ESS,FSS}(io::IO, x::Ubound{ESS,FSS})
  print(io, "Ubound{$ESS,$FSS}($(x.lower), $(x.upper))")
end
