doc"""
  `Ubound{ESS,FSS}` creates a ubound, which represents an interval on the real line
  which cannot be expressed using a single unum.  Several constructors are available:

  `Ubound{ESS,FSS}(::Ubound)` copies the ubound.

  `Ubound{ESS,FSS}(left::Unum, right::Unum)`
  `Ubound{ESS,FSS}(left::Ubound, right::Unum)`
  `Ubound{ESS,FSS}(left::Unum, right::Ubound)`
  `Ubound{ESS,FSS}(left::Ubound, right::Ubound)`

  create a Ubound with the unums representing the outer hull of the two values.
  Left must be strictly less than right.

  In all cases  Ubound-passed parameters will copy their unums, but unum passed
  parameters will become "owned" by the Ubound.

  These constructors are unsafe when options[:devmode] is unset.  Guaranteed safe
  constructors are provided using the equivalent ubound() functions, these constructors
  will copy their passed unums.
"""
abstract Ubound{ESS,FSS} <: Real

type UboundSmall{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumSmall{ESS,FSS}
  upper::UnumSmall{ESS,FSS}
end

#overload the call dispatches for naked ubound types.
@universal function (::Type{Ubound{ESS,FSS}})(x::Unum, y::Unum)
  B(x, y)
end
#an empty constructor defaults to the extended real line.
function (::Type{Ubound{ESS,FSS}}){ESS,FSS}()
  if FSS < 7
    UboundSmall{ESS,FSS}(neg_inf(UnumSmall{ESS,FSS}), pos_inf(UnumSmall{ESS,FSS}))
  else
    UboundLarge{ESS,FSS}(neg_inf(UnumLarge{ESS,FSS}), pos_inf(UnumLarge{ESS,FSS}))
  end
end

type UboundLarge{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumLarge{ESS,FSS}
  upper::UnumLarge{ESS,FSS}
end

#to make Ubound construction easier, you don't have to specify the {ESS,FSS} pair when calling it.
(::Type{Ubound}){ESS,FSS}(lower::Unum{ESS,FSS}, upper::Unum{ESS,FSS}) = Ubound{ESS,FSS}(lower, upper)

@universal Base.copy(x::Ubound) = B(copy(x.lower), copy(x.upper))

export Ubound
