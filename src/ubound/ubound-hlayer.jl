Base.bits(b::Ubound) = string("$(bits(b.lower)) -> $(bits(b.upper))")

function Base.show{ESS,FSS}(io::IO, x::Ubound{ESS,FSS})
  @typenames
  
  print(io, "$bname{$ESS,$FSS}($(x.lower), $(x.upper))")
end
