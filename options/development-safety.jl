#options/development-safety.jl

#development environment safety checks include (somewhat) expensive constructor
#testing which ensure validity of unum and ubound creation.  These are replaced
#by a blank function in the non-development situation.  Currently, and in all
#development releases, this option defaults to "true", for production releases,
#this will default to "false".

const __IS_UNUM_DEV = true

__ds_set = function(o::__Unum_Option)
  global __check_block_unum_dev = __check_block_unum
  global __check_block_ubound_dev = __check_block_ubound
  global __check_block_ubound_lowerbound_dev = __check_block_ubound_lowerbound
  global __check_block_ubound_upperbound_dev = __check_block_ubound_upperbound
  o.status = true
end

__ds_unset = function(o::__Unum_Option)
  global __check_block_unum_dev = __check_block_unum_pass
  global __check_block_ubound_dev = __check_block_ubound_pass
  global __check_block_ubound_lowerbound_dev = __check_block_ubound_pass
  global __check_block_ubound_upperbound_dev = __check_block_ubound_pass
  o.status = false
end

################################################################################
## UNUM CHECKING SAFETY

function __check_block_unum(ESS::Integer, FSS::Integer, fsize::Uint16, esize::Uint16, fraction::SuperInt, exponent::Uint64)
  fsize < (1 << FSS)              || throw(ArgumentError("fsize $(fsize) too big for FSS $(FSS)"))
  esize < (1 << ESS)              || throw(ArgumentError("esize $(esize) too big for ESS $(ESS)"))

  #when you have esize == 63 ALL THE VALUES ARE VALID, but bitshift op will do something strange.
  ((esize == 63) || exponent < (1 << (esize + 1))) || throw(ArgumentError("exponent $(exponent) too big for esize $(esize)"))
  length(fraction) == __frac_cells(FSS) || throw(ArgumentError("size mismatch between supplied fraction array $(length(fraction)) and expected $(__frac_cells(FSS))"))
  nothing
end

__check_block_unum_pass(ESS::Integer, FSS::Integer, fsize::Uint16, esize::Uint16, fraction::SuperInt, exponent::Uint64) = nothing

################################################################################
## UBOUND CHECKING SAFETY


function __check_block_ubound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  (a > b) && throw(ArgumentError("ubound built has bad unum order: $(bits(a, " ")) > $(bits(b, " "))"))
end

__check_block_ubound_lowerbound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = __check_block_ubound(lower_bound(a), b)
__check_block_ubound_upperbound{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = __check_block_ubound(a, upper_bound(b))

__check_block_ubound_pass{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}) = nothing


################################################################################
#register this option
__uopt_dss = __Unum_Option(__ds_set, __ds_unset, __IS_UNUM_DEV)
__IS_UNUM_DEV ? __ds_set(__uopt_dss) : __ds_unset(__uopt_dss)
__UNUM_OPTIONS["development-safety"] = __uopt_dss
