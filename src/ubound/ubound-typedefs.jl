#unum-ubound.jl
@generated function __check_Ubound{ESS,FSS}(ESSp, FSSp, lower::Unum{ESS,FSS}, upper::Unum{ESS,FSS})
  if (ESS == 0) && (FSS == 0)
    (lower > upper) && throw(ArgumentError("ubound built backwards: $(bits(a)) > $(bits(b))"))
  else
    (lower > upper) && throw(ArgumentError("ubound built backwards: $(bits(a, " ")) > $(bits(b, " "))"))
  end
end

#basic ubound type, which contains two unums, as well as some properties of ubounds

immutable Ubound{ESS,FSS} <: Utype
  lower::Unum{ESS,FSS}
  upper::Unum{ESS,FSS}

  @dev_check ESS FSS function Ubound(a, b)
    new(a, b)
  end
end
#springboard off of the inner constructor type to get this to work.  Yes, inner
#constructors in julia are a little bit confusing.
Ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = Ubound{ESS,FSS}(a,b)

export Ubound
