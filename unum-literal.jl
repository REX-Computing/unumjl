#unum-macro.jl
#=
#creates a macro for inputting unums in a convenient fashion.
macro unum(prefix, parts...)
  environment_known::Bool = false
  #for now, set {4,6} as a default environment.
  ess::Integer = 4
  fss::Integer = 6
  uexpr::Expr
  #figure out the environment
  if prefix.head == :cell1d
    if (length(prefix.args) == 1)
      (prefix.args[1] != :auto) && throw(ParseError("invalid environment prefix"))
    else
      (length(prefix.args) > 2) && throw(ParseError("invalid environment prefix"))
      (length(prefix.args) == 2) && ((!isinteger(prefix.args[1])) || (!isinteger(prefix.args[2]))) && throw(ParseError("invalid environment prefix"))
      ess = prefix.args[1]
      fss = prefix.args[2]
      (ess > 6) && throw(ParseError("esizesize > 6 not currently supported"))
      (fss > 16) && throw(ParseError("fsizesize > 16 not currently supported"))
      environment_known = true
    end
    isempty(parts) && throw(ParseError("unum value missing"))
    uexpr = parts[1]
  else
    uexpr = prefix
  end
  isempty(uexpr) && return
  Meta.show_sexpr(parts)
end
=#

#dummy functions which will be used to set unum properties
↓() = nothing
⋯() = nothing
exact() = nothing
ulp() = nothing
export exact, ulp, ↓, ⋯

function __f2ubit(c::Function)
  ((c == ↓) || (c == exact)) && return z16
  ((c == ⋯) || (c == ulp)) && return UNUM_UBIT_MASK
  throw(ParseError("invalid ubit identifier supplied in unum definition"))
end

#alternative fallback, not using a macro
type __unum_shim
  ESS::Integer
  FSS::Integer
  val::Float64
  ubit::Uint16
end

colon(a::Array{Any,1}, b::Float64, c::Function) = __unum_shim(a[1], a[2], b, __f2ubit(c))
function colon(a::__unum_shim, b::Integer, c::Integer)
  x = convert(Unum{a.ESS, a.FSS}, a.val)
  unum(Unum{a.ESS, a.FSS}, uint16(c), uint16(b), (x.flags & UNUM_SIGN_MASK) | a.ubit, x.fraction, x.exponent)
end
