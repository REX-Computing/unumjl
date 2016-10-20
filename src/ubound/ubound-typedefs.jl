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

function __check_UboundSmall{ESS, FSS}(_ESS, _FSS, lower::UnumSmall{ESS,FSS}, upper::UnumSmall{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

@dev_check type UboundSmall{ESS,FSS} <: Ubound{ESS,FSS}
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

function __check_UboundLarge{ESS,FSS}(_ESS, _FSS, lower::UnumLarge{ESS,FSS}, upper::UnumLarge{ESS,FSS})
  (lower < upper) || throw(ArgumentError("in a Ubound, lower must be smaller than upper"))
end

@dev_check type UboundLarge{ESS,FSS} <: Ubound{ESS,FSS}
  lower::UnumLarge{ESS,FSS}
  upper::UnumLarge{ESS,FSS}
end

doc"""
`Unums.__ub_check(left, right)` performs a check on parameters passed to a ubound constructor:
the left hand must be strictly less than the right hand side.
"""
@universal __ub_check(lower::Unum, upper::Unum) = (lower < upper) || throw(ArgumentError("attempted to build an invalid ubound."))

################################################################################
## Ubound constructors that take other ubounds as arguments.
if options[:devmode]
  @universal (::Type{Ubound{ESS,FSS}})(lower::Ubound, upper::Unum)   = __ub_check(lower.upper, upper)       && B(copy(lower.lower), upper)
  @universal (::Type{Ubound{ESS,FSS}})(lower::Unum,   upper::Ubound) = __ub_check(lower,       upper.lower) && B(lower, copy(upper.upper))
  @universal (::Type{Ubound{ESS,FSS}})(lower::Ubound, upper::Ubound) = __ub_check(lower.lower, upper.lower) && __ub_check(lower.upper, upper.upper) && B(copy(lower.lower), copy(upper.upper))
  @universal (::Type{Ubound{ESS,FSS}})(bound::Ubound) = __ub_check(bound.lower, bound.upper) && B(copy(bound.lower), copy(bound.upper))
else
  @universal (::Type{Ubound{ESS,FSS}})(lower::Ubound, upper::Unum)   = B(copy(lower.lower), upper)
  @universal (::Type{Ubound{ESS,FSS}})(lower::Unum,   upper::Ubound) = B(lower, copy(upper.upper))
  @universal (::Type{Ubound{ESS,FSS}})(lower::Ubound, upper::Ubound) = B(copy(lower.lower), copy(upper.upper))
  @universal (::Type{Ubound{ESS,FSS}})(bound::Ubound) = B(copy(bound.lower), copy(bound.upper))
end

#to make Ubound construction easier, you don't have to specify the {ESS,FSS} pair when calling it.
(::Type{Ubound}){ESS,FSS}(lower::Unum{ESS,FSS}, upper::Unum{ESS,FSS}) = Ubound{ESS,FSS}(lower, upper)

doc"""
  `ubound(::Unum, ::Unum)`
  `ubound(::Ubound, ::Unum)`
  `ubound(::Unum, ::Ubound)`
  `ubound(::Ubound, ::Ubound)`
  `ubound(::Ubound)`

  safely creates ubounds using the outer hull of the passed parameters - checks
  will be performed to make sure the parameters are ordered correctly.  This
  constructor also copies naked unums, so the ubound does not take ownership
  of the passed parameter.
"""
@universal ubound(lower::Unum, upper::Unum)     = (options[:devmode] ||  __ub_check(lower, upper); Ubound{ESS,FSS}(copy(lower), copy(upper)))
@universal ubound(lower::Ubound, upper::Unum)   = (options[:devmode] ||  __ub_check(lower.upper, upper); Ubound{ESS,FSS}(lower, copy(upper)))
@universal ubound(lower::Unum,   upper::Ubound) = (options[:devmode] ||  __ub_check(lower, upper.lower); Ubound{ESS,FSS}(copy(lower), upper))
@universal ubound(lower::Ubound, upper::Ubound) = (options[:devmode] || (__ub_check(lower.upper, upper) && __ub_check(lower.upper, upper)); Ubound{ESS,FSS}(lower, upper))
@universal ubound(bound::Ubound) = (options[:devmode] || __ub_check(bound.lower, bound.upper); Ubound{ESS,FSS}(bound))
export Ubound, ubound

@universal Base.copy(x::Ubound) = B(copy(x.lower), copy(x.upper))
