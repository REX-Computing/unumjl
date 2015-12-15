
doc"""
  `Unums.Gnum{ESS,FSS}` is an internal type structure that's not exposed to
  the global scope.  It represents the g-layer from the "End of Error".  Some
  of the status flags are stored in the flags parameter of the 'lower' term.

  Fast calculations will get sent to the Gnum Type.
"""
abstract Gnum{ESS, FSS} <: Utype

type Gnum_Small{ESS,FSS} <: Gnum{ESS,FSS}
  lower_fsize::UInt16
  lower_esize::UInt16
  lower_flags::UInt16
  lower_fraction::UInt64
  lower_exponent::UInt64
  ######################
  upper_fsize::UInt16
  upper_esize::UInt16
  upper_flags::UInt16
  upper_fraction::UInt64
  upper_exponent::UInt64
end

type Gnum_Large{ESS,FSS} <: Gnum{ESS,FSS}
  lower_fsize::UInt16
  lower_esize::UInt16
  lower_flags::UInt16
  lower_fraction::ArrayNum{FSS}
  lower_exponent::UInt64
  ######################
  upper_fsize::UInt16
  upper_esize::UInt16
  upper_flags::UInt16
  upper_fraction::ArrayNum{FSS}
  upper_exponent::UInt64
end

#two g-layer flags that only apply to the "lower" slots.
#throws a bit saying that this gnum only contains one unum.
GNUM_SBIT_MASK = 0x8000
#throws a bit saying this number is NaN
GNUM_NAN_MASK  = 0x4000

#g-layer flags that apply to both "lower" and "higher" slots.
GNUM_INF_MASK  = 0x0800
GNUM_MMR_MASK  = 0x0400
GNUM_SSS_MASK  = 0x0200
GNUM_ZERO_MASK = 0x0100
