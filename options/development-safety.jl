#options/development-safety.jl

#development environment safety checks include (somewhat) expensive constructor
#testing which ensure validity of unum and ubound creation.  These are replaced
#by a blank function in the non-development situation.  Currently, and in all
#development releases, this option defaults to "true", for production releases,
#this will default to "false".

const __IS_UNUM_DEV = true

__ds_set = function(o::__Unum_Option)
  global __check_block_unum = __check_block_unum_dev
  o.status = true
end

__ds_unset = function(o::__Unum_Option)
  global __check_block_unum = __check_block_unum_pass
  o.status = false
end

function __check_block_unum_dev(ESS::Integer, FSS::Integer, fsize::Uint16, esize::Uint16, fraction::Uint64, exponent::Uint64)
  fsize < (1 << FSS)              || throw(ArgumentError("fsize $(fsize) too big for FSS $(FSS)"))
  esize < (1 << ESS)              || throw(ArgumentError("esize $(esize) too big for ESS $(ESS)"))

  #when you have esize == 63 ALL THE VALUES ARE VALID, but bitshift op will do something strange.
  ((esize == 63) || exponent < (1 << (esize + 1))) || throw(ArgumentError("exponent $(exponent) too big for esize $(esize)"))
  length(fraction) == __frac_cells(FSS) || throw(ArgumentError("size mismatch between supplied fraction array $(length(fraction)) and expected $(__frac_cells(FSS))"))
end

function __check_block_unum_pass(ESS::Integer, FSS::Integer, fsize::Uint16, esize::Uint16, fraction::Uint64, exponent::Uint64)
end

################################################################################
#register this option
__uopt_dss = __Unum_Option(__ds_set, __ds_unset, __IS_UNUM_DEV)
__IS_UNUM_DEV ? __ds_set(__uopt_dss) : __ds_unset(__uopt_dss)
__UNUM_OPTIONS["development-safety"] = __uopt_dss
