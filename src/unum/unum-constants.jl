#unum-onezero.jl
#implements the one and zero functions for unums.

#SOME MATHEMATICAL CONSTANTS
Base.zero{ESS,FSS}(::Type{UnumSmall{ESS,FSS}}) = UnumSmall{ESS,FSS}(z64, z64, z16, z16, z16)
Base.zero{ESS,FSS}(::Type{UnumLarge{ESS,FSS}}) = UnumLarge{ESS,FSS}(z64, zero(ArrayNum{FSS}), z16, z16, z16)
@generated function Base.zero{ESS,FSS}(::Type{Unum{ESS,FSS}})
  if FSS < 7
    :(UnumSmall{ESS,FSS}(z64, z64, z16, z16, z16))
  else
    :(UnumLarge{ESS,FSS}(z64, zero(ArrayNum{FSS}), z16, z16, z16))
  end
end
@universal Base.zero(x::Unum) = zero(typeof(x))

doc"""
  the `zero!` function forcibly converts an existing unum to zero.  You can pass
  a flag that sets the sign or ubit, but it defaults to positive/not a ubit.
"""
@universal function zero!(x::Unum, flags::UInt16 = z16)
  x.fsize = z16
  x.esize = z16
  x.flags = flags
  x.exponent = z64
  frac_zero!(x)
end
export zero!

function Base.one{ESS,FSS}(::Type{UnumSmall{ESS,FSS}})
  if ESS == 0
    UnumSmall{ESS,FSS}(z64, t64, z16, z16, z16)
  else
    UnumSmall{ESS,FSS}(o64, z64, z16, o16, z16)
  end
end
function Base.one{ESS,FSS}(::Type{UnumLarge{ESS,FSS}})
  if ESS == 0
    UnumLarge{ESS,FSS}(z64, top(ArrayNum{FSS}), z16, z16, z16)
  else
    UnumLarge{ESS,FSS}(o64, zero(ArrayNum{FSS}), z16, o16, z16)
  end
end
Base.one{ESS,FSS}(::Type{Unum{ESS,FSS}}) = (FSS < 7) ? Base.one(UnumSmall{ESS,FSS}) : Base.one(UnumLarge{ESS,FSS})
@universal Base.one(x::Unum) = one(typeof(x))

pos_one{ESS,FSS}(::Type{Unum{ESS,FSS}}) = FSS < 7 ? one(UnumSmall{ESS,FSS}) : one(UnumLarge{ESS,FSS})
@universal pos_one(t::Type{Unum}) = one(t)
pos_one{ESS,FSS}(x::Unum{ESS,FSS}) = one(Unum{ESS,FSS})
@universal pos_one(x::Unum) = one(typeof(x))

neg_one{ESS,FSS}(::Type{Unum{ESS,FSS}}) = FSS < 7 ? uflag!(one(UnumSmall{ESS,FSS}), UNUM_SIGN_MASK) : uflag!(one(UnumLarge{ESS,FSS}), UNUM_SIGN_MASK)
@universal neg_one(t::Type{Unum}) = uflag!(one(t), UNUM_SIGN_MASK)
neg_one{ESS,FSS}(x::Unum{ESS,FSS}) = uflag!(one(Unum{ESS,FSS}), UNUM_SIGN_MASK)
@universal neg_one(x::Unum) = uflag!(one(typeof(x)))
export pos_one, neg_one

################################################################################
#infs and nans look quite similar, so we'll create a generated function that
#combines the code for both.
@universal function __infnanset!(x::Unum, flags::UInt16)
  x.fsize = max_fsize(FSS)
  x.esize = max_esize(ESS)
  x.flags = flags
  x.exponent = max_biased_exponent(ESS)
  frac_all!(x)
  (FSS < 7) && frac_trim!(x, x.fsize)
  return x
end

################################################################################

doc"""
  the `nan!` function forcibly turns a unum variable into nan.
"""
@universal nan!(x::Unum, signmask::UInt16 = z16) = __infnanset!(x, UNUM_UBIT_MASK | signmask)
Base.nan{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask::UInt16 = z16) = (FSS < 7) ? nan!(zero(UnumSmall{ESS,FSS})) : nan!(zero(UnumLarge{ESS,FSS}))
@universal Base.nan(t::Type{Unum}, signmask::UInt16 = z16) = nan!(zero(t))

################################################################################

Base.inf{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask::UInt16 = z16) = (FSS < 7) ? __infnanset!(zero(UnumSmall{ESS,FSS}), signmask) : __infnanset!(zero(UnumLarge{ESS,FSS}), signmask)
@universal Base.inf(t::Type{Unum}, signmask::UInt16 = z16) = __infnanset!(zero(t), signmask)
doc"""
  `pos_inf` generates an explicitly positive infinite value of the chosen type.
"""
pos_inf{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = inf(T)
@universal pos_inf(T::Type{Unum}) = inf(T)

doc"""
  `neg_inf` generates an explicitly negative infinite value of the chosen type.
"""
neg_inf{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = inf(T, UNUM_SIGN_MASK)
@universal neg_inf(T::Type{Unum}) = inf(T, UNUM_SIGN_MASK)

doc"""
  the `inf!` function forcibly turns a unum variable into inf of the chosen type...
"""
@universal inf!(x::Unum, signmask::UInt16 = z16) = __infnanset!(x, signmask)

doc"""
  the `pos_inf!` function forcibly turns a unum variable into positive infinity...
"""
@universal pos_inf!(x::Unum, signmask::UInt16) = __infnanset!(x)

doc"""
  the `neg_inf!` function forcibly turns a unum variable into negative infinity...
"""
@universal neg_inf!(x::Unum, signmask::UInt16) = __infnanset!(x, UNUM_SIGN_MASK)
export pos_inf, neg_inf, inf!, pos_inf!, neg_inf!


################################################################################
# mmr and big_exact look very similar, so we'll combine the code to generate them
# here.
@universal function __mmr_bigexact_set!(x::Unum, flags::UInt16)
  x.fsize = max_fsize(FSS)
  x.esize = max_esize(ESS)
  x.flags = flags
  x.exponent = max_biased_exponent(ESS)

  if (FSS == 0)
    x.fraction = z64
  else
    frac_mask_top!(x, x.fsize - o16)
  end

  return x
end

#mmr and bigexact - "more than maxreal" and "biggest exact number".
mmr{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask::UInt16 = z16) = __mmr_bigexact_set!(zero(Unum{ESS,FSS}), signmask | UNUM_UBIT_MASK)
@universal mmr(T::Type{Unum}, signmask::UInt16 = z16) = __mmr_bigexact_set!(zero(T), signmask | UNUM_UBIT_MASK)
@universal mmr!(x::Unum, signmask::UInt16 = z16) = __mmr_bigexact_set!(x, signmask | UNUM_UBIT_MASK)

pos_mmr{ESS,FSS}(::Type{Unum{ESS,FSS}}) = mmr(Unum{ESS,FSS})
neg_mmr{ESS,FSS}(::Type{Unum{ESS,FSS}}) = mmr(Unum{ESS,FSS}, UNUM_SIGN_MASK)
@universal pos_mmr(T::Type{Unum}) = mmr(T)
@universal neg_mmr(T::Type{Unum}) = mmr(T, UNUM_SIGN_MASK)
@universal pos_mmr!(x::Unum) = __mmr_bigexact_set!(x, UNUM_UBIT_MASK)
@universal neg_mmr!(x::Unum) = __mmr_bigexact_set!(x, UNUM_SIGN_MASK | UNUM_UBIT_MASK)

big_exact{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask = z16) = __mmr_bigexact_set!(zero(Unum{ESS,FSS}), signmask & (~UNUM_UBIT_MASK))
@universal big_exact(T::Type{Unum}, signmask::UInt16 = z16) = __mmr_bigexact_set!(zero(T), signmask & (~UNUM_UBIT_MASK))
@universal big_exact!(x::Unum, signmask::UInt16 = z16) = __mmr_bigexact_set!(x, signmask & (~UNUM_UBIT_MASK))

pos_big_exact{ESS,FSS}(::Type{Unum{ESS,FSS}}) = big_exact(Unum{ESS,FSS})
neg_big_exact{ESS,FSS}(::Type{Unum{ESS,FSS}}) = big_exact(Unum{ESS,FSS}, UNUM_SIGN_MASK)
@universal pos_big_exact(T::Type{Unum}) = big_exact(T)
@universal neg_big_exact(T::Type{Unum}) = big_exact(T, UNUM_SIGN_MASK)
@universal pos_big_exact!(x::Unum) = __mmr_bigexact_set!(x)
@universal neg_big_exact!(x::Unum) = __mmr_bigexact_set!(x, UNUM_SIGN_MASK)
export mmr, mmr!, pos_mmr, neg_mmr, pos_mmr!, neg_mmr!, big_exact, big_exact!, pos_big_exact, neg_big_exact, pos_big_exact!, neg_big_exact!

################################################################################
# smaller than small subnormal cannot reuse code from zero because the esize and
# fsize parameters have to be maxed out.

@universal function sss!(x::Unum, flags::UInt16 = z16)
  x.fsize = max_fsize(FSS)
  x.esize = max_esize(ESS)
  x.flags = flags | UNUM_UBIT_MASK
  x.exponent = z64
  frac_zero!(x)
  return x
end

sss{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask::UInt16 = z16) = sss!(zero(Unum{ESS,FSS}), signmask)
@universal sss(T::Type{Unum}, signmask::UInt16 = z16) = sss!(zero(T), signmask)

pos_sss{ESS,FSS}(::Type{Unum{ESS,FSS}}) = sss(Unum{ESS,FSS})
neg_sss{ESS,FSS}(::Type{Unum{ESS,FSS}}) = sss(Unum{ESS,FSS}, UNUM_SIGN_MASK)
@universal pos_sss(T::Type{Unum}) = sss(T)
@universal neg_sss(T::Type{Unum}) = sss(T, UNUM_SIGN_MASK)
@universal pos_sss!(x::Unum) = sss!(x)
@universal neg_sss!(x::Unum) = sss!(x, UNUM_SIGN_MASK)
export sss, sss!, pos_sss, neg_sss, pos_sss!, neg_sss!

################################################################################
# small_exact is tricky because it generates a very unique signature.
@universal function __set_small_exact!(x::Unum, flags::UInt16 = z16)
  x.fsize = max_fsize(FSS)
  x.esize = max_esize(ESS)
  x.flags = flags & (~UNUM_UBIT_MASK)
  x.exponent = z64

  if FSS < 7
    x.fraction = bottom_bit(x.fsize)
  else
    bottom_bit!(x.fraction)
  end

  return x
end

function small_exact{ESS,FSS}(::Type{Unum{ESS,FSS}}, signmask = z16)
  x = zero(Unum{ESS,FSS})
  __set_small_exact!(x, signmask)
end
small_exact!{ESS,FSS}(x::Unum{ESS,FSS}, flags::UInt16) = __set_small_exact!(x, flags)

pos_small_exact{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = small_exact(T)
neg_small_exact{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = small_exact(T, UNUM_SIGN_MASK)

pos_small_exact!{ESS,FSS}(x::Unum{ESS,FSS}) = small_exact!(x)
neg_small_exact!{ESS,FSS}(x::Unum{ESS,FSS}) = small_exact!(x, UNUM_SIGN_MASK)
export small_exact, small_exact!, pos_small_exact, neg_small_exact, pos_small_exact!, neg_small_exact!
