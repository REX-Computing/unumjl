#unum-hlayer.jl - human layer things in the unum library.

#modify the show() directive so that a text display of both unum types outputs
#as a "Unum" object and hides the underlying "UnumSmall"/"UnumLarge" distinction.
#
#N.B. typeof() will correctly identify the Unums.UnumSmall and Unums.UnumLarge
#types.
@universal function Base.show(io::IO, x::Unum)

  name = options[:longform] ? ((FSS < 6) ? "UnumLarge" : "UnumSmall") : "Unum"

  #we want to be able to represent having g-layer flags as part of this.
  gflags = (x.flags & (~UNUM_FLAG_MASK))
  #for nan, let's also show the noisy nan bit.
  isnan(x) && (gflags |= (x.flags & UNUM_SIGN_MASK))
  gflagstring = (gflags == 0) ? "" : @sprintf ", 0x%04X" gflags
  is_pos_inf(x) && (print(io, "inf($name{$ESS,$FSS}$gflagstring)"); return)
  is_pos_mmr(x) && (print(io, "mmr($name{$ESS,$FSS}$gflagstring)"); return)
  is_pos_sss(x) && (print(io, "sss($name{$ESS,$FSS}$gflagstring)"); return)
  is_neg_inf(x) && (print(io, "-inf($name{$ESS,$FSS}$gflagstring)"); return)
  is_neg_mmr(x) && (print(io, "-mmr($name{$ESS,$FSS}$gflagstring)"); return)
  is_neg_sss(x) && (print(io, "-sss($name{$ESS,$FSS}$gflagstring)"); return)
  is_zero(x)    && (print(io, "zero($name{$ESS,$FSS})"); return)
  isnan(x)      && (print(io,"nan($name{$ESS,$FSS}$gflagstring)");return)

  fsize_string = @sprintf "0x%04X" x.fsize
  esize_string = @sprintf "0x%04X" x.esize
  flags_string = @sprintf "0x%04X" x.flags

  (FSS < 7) ? :(fraction_string = @sprintf "0x%016X" x.fraction) : :(fraction_string = string(x.fraction.a))
  exponent_string = @sprintf "0x%016X" x.exponent
  print(io, "$name{$ESS,$FSS}($fsize_string, $esize_string, $flags_string, $fraction_string, $exponent_string)")
end

@universal function Base.show(io::IO, T::Type{Unum})
  #strips the Large or Small suffix when displaying this type.
  if options[:longform]
    if FSS > 7
      print(io, "UnumLarge{$ESS, $FSS}")
    else
      print(io, "UnumSmall{$ESS, $FSS}")
    end
  end
    print(io, "Unum{$ESS,$FSS}")
  end
end

@universal function Base.bits(x::Unum, space::ASCIIString = "")
  res = string((x.flags & 0b10) >> 1,       space,
         bits(x.exponent)[64 - x.esize:64], space,
         bits(x.fraction)[1:(x.fsize + 1)], space,
         x.flags & 0b1)
  ESS > 0 && (res = string(res, space, bits(x.esize)[17-ESS:16]))
  FSS > 0 && (res = string(res, space, bits(x.fsize)[17-FSS:16]))
  res
end
#=
doc"""
`prettyprint` prints out a Unum in a pretty fashion.  Copy/pasting the output
will create something that is pretty-parseable.
"""
@unum function prettyprint(x::Unum)

  print_with_color(:blue, "Unum{$ESS,$FSS}:")

  is_pos_inf(x) && (print_with_color(:green, "inf");  println(); return)
  is_pos_mmr(x) && (print_with_color(:green, "mmr");  println(); return)
  is_pos_sss(x) && (print_with_color(:green, "sss");  println(); return)
  is_neg_inf(x) && (print_with_color(:green, "-inf"); println(); return)
  is_neg_mmr(x) && (print_with_color(:green, "-mmr"); println(); return)
  is_neg_sss(x) && (print_with_color(:green, "-sss"); println(); return)
  is_nan(x)     && (print_with_color(:red, "NaN");  println(); return)
  is_zero(x)    && (print_with_color(:white, "0.0");  println(); return)

  subnormal_value = is_exp_zero(x) ? 1 : 0
  exponent_value = subnormal_value + decode_exp(x)


  print('"', (x.flags & UNUM_SIGN_MASK == 0) ? "" : "-")
  print(1 - subnormal_value, "." , bits(x.fraction)[1:x.fsize + 1])
  (x.flags & UNUM_UBIT_MASK == 0) ? "" : print_with_color(:green, "⋯")
  print_with_color(:red, "b")
  print_with_color(:yellow, string("×2^", exponent_value))
  println('"')
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

################################################################################
# parsing prettyprint
type b0; end
type b1; end
export b0, b1

type __udata
  exponent::Int
  floatrep::Integer
  flags::UInt16
  subnormal::Bool
end

import Base.-

function Base.colon{ESS,FSS}(::Type{Unum{ESS,FSS}}, u::__udata)
  println("generating for $u")
end

function -(f::Function)
 #special functions
  f == sss && return neg_sss
  f == mmr && return neg_mmr
  f == inf && return neg_inf
  throw(MethodError())
end

function Base.colon{ESS,FSS}(::Type{Unum{ESS,FSS}}, f::Function)
  f == sss && return sss(Unum{ESS,FSS})
  f == mmr && return mmr(Unum{ESS,FSS})
  f == inf && return inf(Unum{ESS,FSS})
  f == neg_sss && return neg_sss(Unum{ESS,FSS})
  f == neg_mmr && return neg_mmr(Unum{ESS,FSS})
  f == neg_inf && return neg_inf(Unum{ESS,FSS})
  f == nan && return nan(Unum{ESS,FSS})
end

Base.colon{ESS,FSS}(::Type{Unum{ESS,FSS}}, x::Float64) = convert(Unum{ESS,FSS}, x)

################################################################################
# unum string parsing
function Base.colon{ESS,FSS}(::Type{Unum{ESS,FSS}}, s::AbstractString)
  println("parsing the prettyprint string $s")
  #first there should be a numerical section.  Scan for this.

  #then scan for the presence or not of the UBIT identifier

  #next check if this is a binary or decimal representation.

  #next pull out the exponent
end
=#
