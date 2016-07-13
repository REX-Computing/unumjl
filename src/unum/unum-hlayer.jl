#unum-hlayer.jl - human layer things in the unum library.

#modify the show() directive so that a text display of both unum types outputs
#as a "Unum" object and hides the underlying "UnumSmall"/"UnumLarge" distinction.
#
#N.B. typeof() will correctly identify the Unums.UnumSmall and Unums.UnumLarge
#types.

@universal function Base.show(io::IO, x::Unum)

  @typenames

  #we want to be able to represent having g-layer flags as part of this.
  gflags = (x.flags & (~UNUM_FLAG_MASK))
  #for nan, let's also show the noisy nan bit.
  isnan(x) && (gflags |= (x.flags & UNUM_SIGN_MASK))
  gflagstring = (gflags == 0) ? "" : @sprintf ", 0x%04X" gflags
  is_pos_inf(x) && (print(io, "inf($uname{$ESS,$FSS}$gflagstring)"); return)
  is_pos_mmr(x) && (print(io, "mmr($uname{$ESS,$FSS}$gflagstring)"); return)
  is_pos_sss(x) && (print(io, "sss($uname{$ESS,$FSS}$gflagstring)"); return)
  is_neg_inf(x) && (print(io, "-inf($uname{$ESS,$FSS}$gflagstring)"); return)
  is_neg_mmr(x) && (print(io, "-mmr($uname{$ESS,$FSS}$gflagstring)"); return)
  is_neg_sss(x) && (print(io, "-sss($uname{$ESS,$FSS}$gflagstring)"); return)
  is_zero(x)    && (print(io, "zero($uname{$ESS,$FSS})"); return)
  isnan(x)      && (print(io,"nan($uname{$ESS,$FSS}$gflagstring)");return)

  fsize_string = @sprintf "0x%04X" x.fsize
  esize_string = @sprintf "0x%04X" x.esize
  flags_string = @sprintf "0x%04X" x.flags

  (FSS < 7) ? (fraction_string = @sprintf "0x%016X" x.fraction) : fraction_string = string(x.fraction.a)
  exponent_string = @sprintf "0x%016X" x.exponent
  print(io, "$uname{$ESS,$FSS}($exponent_string, $fraction_string, $flags_string, $esize_string, $fsize_string)")
end

@universal function Base.show(io::IO, T::Type{Unum})
  #strips the Large or Small suffix when displaying this type.
  @typenames
  print(io, "$uname{$ESS,$FSS}")
end
function Base.show{ESS,FSS}(io::IO, T::Type{Unum{ESS,FSS}})
  @typenames
  print(io, "$uname{$ESS,$FSS}")
end
function Base.show(io::IO, T::Type{Unum})
  print(io, "Unum")
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

___textual{ESS,FSS}(v::UnumSmall{ESS,FSS}) = (ESS > 3) ? calculate(v) : Float64(v)
___textual{ESS}(v::UnumSmall{ESS,6}) = calculate(v)
___textual{ESS,FSS}(v::UnumLarge{ESS,FSS}) = calculate(v)

@universal function __textual(v::Unum)
  is_neg_inf(v) && return "-∞"
  is_pos_inf(v) && return "∞"
  ___textual(v)
end

@universal function describe(v::Unum)
  print("Unum{$ESS,$FSS}(")
  if is_exact(v)
    print(__textual(v))
    print(" ex")
  else
    print(__textual(glb(v)))
    print(" op → ")
    print(__textual(lub(v)))
    print(" op")
  end
  print(")")
  println()
end

@universal function describe(v::Ubound)
  print("Ubound{$ESS,$FSS}(")
  if is_exact(v.lower)
    print(__textual(v.lower))
    print(" ex")
  else
    print(__textual(glb(v.lower)))
    print(" op")
  end
  print(" → ")
  if is_exact(v.upper)
    print(__textual(v.upper))
    print(" ex")
  else
    print(__textual(lub(v.upper)))
    print(" op")
  end
  print(")")
  println()
end
export describe


doc"""
  `ℜ` is used to generate special sets of real numbers in prettyprint directives.

  * `Unum{4,6}(ℜ) == Ubound(neg_mmr(Unum{4,6}), pos_mmr(Unum{4,6}))`
  * `Unum{4,6}(ℜ(∘)) == Ubound(neg_inf(Unum{4,6}), pos_inf(Unum{4,6}))`
"""
type ℜ; end

doc"""
  `ℜ⁺` is used to generate special sets of real numbers in prettyprint directives.

  * `Unum{4,6}(ℜ⁺) == Ubound(zero(Unum{4,6}), pos_mmr(Unum{4,6}))`
  * `Unum{4,6}(ℜ⁺(*)) == Ubound(pos_sss(Unum{4,6}), pos_mmr(Unum{4,6}))`
  * `Unum{4,6}(ℜ⁺(∘)) == Ubound(zero(Unum{4,6}), pos_inf(Unum{4,6}))`
"""
type ℜ⁺; end  #positive real numbers

doc"""
  `ℜ⁻` is used to generate special sets of real numbers in prettyprint directives.

  * `Unum{4,6}(ℜ⁻) == Ubound(neg_mmr(Unum{4,6}), zero(Unum{4,6}))`
  * `Unum{4,6}(ℜ⁻(*)) == Ubound(neg_mmr(Unum{4,6}), neg_sss(Unum{4,6}))`
  * `Unum{4,6}(ℜ⁻(∘)) == Ubound(neg_inf(Unum{4,6}), zero(Unum{4,6}))`
"""
type ℜ⁻; end
type ∘; end

Base.call(::Type{ℜ}, ::Type{∘}) = :_rextended
Base.call(::Type{ℜ⁺}, f::Function) = (f == (*)) ? :_rposstar : nothing
Base.call(::Type{ℜ⁻}, f::Function) = (f == (*)) ? :_rnegstar : nothing
Base.call(::Type{ℜ⁺}, ::Type{∘}) = :_rposext
Base.call(::Type{ℜ⁻}, ::Type{∘}) = :_rnegext

export ℜ, ℜ⁺, ℜ⁻, ∘
