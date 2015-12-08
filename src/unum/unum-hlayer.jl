#unum-hlayer.jl - human layer things in the unum library.

#modify the show() directive so that a text display of both unum types outputs
#as a "Unum" object and hides the underlying "UnumSmall"/"UnumLarge" distinction.
#
#N.B. typeof() will correctly identify the Unums.UnumSmall and Unums.UnumLarge
#types.

function Base.show{ESS,FSS}(io::IO, x::UnumSmall{ESS,FSS})

  is_pos_inf(x) && (print(io, "inf(Unum{$ESS,$FSS})"); return)
  is_pos_mmr(x) && (print(io, "mmr(Unum{$ESS,$FSS})"); return)
  is_pos_sss(x) && (print(io, "sss(Unum{$ESS,$FSS})"); return)
  is_neg_inf(x) && (print(io, "neg_inf(Unum{$ESS,$FSS})"); return)
  is_neg_mmr(x) && (print(io, "neg_mmr(Unum{$ESS,$FSS})"); return)
  is_neg_sss(x) && (print(io, "neg_sss(Unum{$ESS,$FSS})"); return)
  isnan(x)      && (print(io,"nan(Unum{$ESS,$FSS})");return)

  fsize_string = @sprintf "0x%04X" x.fsize
  esize_string = @sprintf "0x%04X" x.esize
  flags_string = @sprintf "0x%04X" x.flags
  fraction_string = @sprintf "0x%016X" x.fraction
  exponent_string = @sprintf "0x%016X" x.exponent
  print(io, "Unum{$ESS,$FSS}($fsize_string, $esize_string, $flags_string, $fraction_string, $exponent_string)")
end

function Base.show{ESS,FSS}(io::IO, x::UnumLarge{ESS,FSS})

  is_pos_inf(x) && (print(io, "inf(Unum{$ESS,$FSS})"); return)
  is_pos_mmr(x) && (print(io, "mmr(Unum{$ESS,$FSS})"); return)
  is_pos_sss(x) && (print(io, "sss(Unum{$ESS,$FSS})"); return)
  is_neg_inf(x) && (print(io, "neg_inf(Unum{$ESS,$FSS})"); return)
  is_neg_mmr(x) && (print(io, "neg_mmr(Unum{$ESS,$FSS})"); return)
  is_neg_sss(x) && (print(io, "neg_sss(Unum{$ESS,$FSS})"); return)
  isnan(x)      && (print(io,"nan(Unum{$ESS,$FSS})");return)

  fsize_string = @sprintf "0x%04X" x.fsize
  esize_string = @sprintf "0x%04X" x.esize
  flags_string = @sprintf "0x%04X" x.flags
  fraction_string = string(x.fraction.a)
  exponent_string = @sprintf "0x%016X" x.exponent
  print(io, "Unum{$ESS,$FSS}($fsize_string, $esize_string, $flags_string, $fraction_string, $exponent_string)")
end

function Base.show{ESS,FSS}(io::IO, ::Type{Unum{ESS,FSS}})
  #strip "Unums" off the front of displaying this type.
  print(io, "Unum{$ESS,$FSS}")
end

function Base.bits{ESS,FSS}(x::Unum{ESS,FSS}, space::ASCIIString = "")
  res = string((x.flags & 0b10) >> 1,       space,
         bits(x.exponent)[64 - x.esize:64], space,
         bits(x.fraction)[1:(x.fsize + 1)], space,
         x.flags & 0b1)
  ESS > 0 && (res = string(res, space, bits(x.esize)[17-ESS:16]))
  FSS > 0 && (res = string(res, space, bits(x.fsize)[17-ESS:16]))
  res
end

################################################################################
#default environment settings
#default environment, defaults to Unum{4,6} -
const UNUM_ENVIRONMENT = [4, 6]
doc"""
`Unums.environment` outputs the current environment as the appropriate Unum type
"""
function environment()
  Unum{UNUM_ENVIRONMENT[1], UNUM_ENVIRONMENT[2]}
end

abstract ubit_coersion_symbol

doc"""
`⇥` triggers the generation of a unum, as a part of the conversion, it coerces a
floating point preceding it to be exact and throws a warning if it shouldn't be
exact.

Ex. usage:
  4.5⇥ == Unum{4,6}(<insert value here>)
  4.6⇥ == Unum{4,6}(<insert value here>), with a warning.
"""
type ⇥ <: ubit_coersion_symbol; end

doc"""
`⋯` triggers the generation of a unum, as a part of the conversion, it coerces a
floating point preceding it to be inexact.

Ex. usage:
  4.5⋯ == Unum{4,6}(<insert value here>)
  4.6⋯ == Unum{4,6}(<insert value here>)
"""
type ⋯ <: ubit_coersion_symbol; end

doc"""
`exact` triggers the generation of a unum, as a part of the conversion, it coerces a
floating point preceding it to be exact and throws a warning if it shouldn't be
exact.

Ex. usage:
  4.5(exact) == Unum{4,6}(<insert value here>)
  4.6(exact) == Unum{4,6}(<insert value here>), with a warning.
"""
typealias exact ⇥

doc"""
`ulp` triggers the generation of a unum, as a part of the conversion, it coerces a
floating point preceding it to be inexact.

Ex. usage:
  4.5(ulp) == Unum{4,6}(<insert value here>)
  4.6(ulp) == Unum{4,6}(<insert value here>)
"""
typealias ulp ⋯

doc"""
`auto` triggers the generation of a unum with automatic detection of ubit based
on the literal representation.  NB: This could cast high-precision exact values
as ulps.

Ex. usage:
  4.5(ulp) == Unum{4,6}(<insert value here>)
  4.6(ulp) == Unum{4,6}(<insert value here>)
"""
type auto <: ubit_coersion_symbol; end

doc"""
`repeat` triggers the generation of a inexact unum that is equivalent to a decimal
literal with repeating digits

Ex. usage:
  0.3(rpt{1}) == Unum{4,6}(<insert value here>)
"""
type rpt{DIGITS} <: ubit_coersion_symbol; end
export exact, ulp, auto, rpt, ⇥, ⋯

doc"""
the `@unum` macro triggers the following float literal to be parsed and interpreted as a
unum literal with automatic ulp detection.

Ex. usage:
  `@unum 4.5` == Unum{4,5}(<insert value here>)
"""
macro unum(param)
  (isa(param, Float64)) && return param
  throw(ArgumentError("the @unum macro must be passed a float literal"))
end
export @unum

import Base.*
function *(x::AbstractFloat, ::Type{⇥})
  println("creates an exact unum for value $x")
  nothing
end

function *(x::AbstractFloat, ::Type{⋯})
  println("creates an inexact unum for value $x")
  nothing
end

function *(x::AbstractFloat, ::Type{auto})
  println("creates a autodetected unum for value $x")
  nothing
end

function *{DIGITS}(x::AbstractFloat, ::Type{rpt{DIGITS}})
  println("creates a repeating decimal with value $x")
  nothing
end
export *
