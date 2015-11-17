#unum-typefunctions.jl

###NB PREPARE THIS FOR DEPRECATION


#=
#functions that operate on a unum type and retrieve certain properties.
#note that type constants come from unum-constants.jl

#JULIA TYPING UTILITIES
#extract parameters from an Unum.
function fsizesize(T::Type)
  if (T <: Unum)
    T.parameters[2]
  else
    throw(ArgumentError("fsizesize only applies to unum types"))
  end
end
function fsizesize(x::Unum)
  typeof(x).parameters[2]
end
function esizesize(T::Type)
  if (T <: Unum)
    T.parameters[1]
  else
    throw(ArgumentError("esizesize only applies to unum types"))
  end
end
function esizesize(x::Unum)
  typeof(x).parameters[1]
end
export fsizesize, esizesize

max_fsize{ESS,FSS}(::Type{Unum{ESS,FSS}}) = max_fsize(FSS)
max_esize{ESS,FSS}(::Type{Unum{ESS,FSS}}) = max_esize(ESS)

#a function that tells you how many bits a unum can take up in 'compressed form'
function maxubits(T::Type)
  if T <: Unum
    fss = fsizesize(T)
    ess = esizesize(T)
    2 + 2^fss + 2^ess + fss + ess
  else
    throw(ArgumentError("maxubits only operates on unums"))
  end
end
export maxubits

#these are for creating another dispatch for julia's standard typemin and typemax.
#the pos_inf and neg_inf functions themselves are in unum-constants.jl
import Base.typemax
import Base.typemin
typemax{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = pos_inf(T)
typemin{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = neg_inf(T)
export typemin, typemin

maxreal{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = pos_big_exact(T)
minreal{ESS,FSS}(T::Type{Unum{ESS,FSS}}) = min_big_exact(T)
export maxreal, minreal

#machine epsilon
import Base.eps
#find the distance to the next unum after the number one.
function eps{ESS,FSS}(T::Type{Unum{ESS,FSS}})

end
#find the next unum after any given number.
#conveniently also is the width of the ubound adjacent, represented there.
function eps{ESS,FSS}(x::Unum{ESS,FSS})
  #check to see if we're zero
  is_zero(x) && return pos_small_exact(Unum{ESS,FSS})
  if (is_exp_zero(x))
    if (x.esize == max_esize(ESS))
      #in the case it's subnormal and not resolved, replace it with a resolved subnormal.
      return eps(Unum{ESS,FSS})
    else
      x = __resolve_subnormal(x)
    end
    #double-check if it's still subnormal, in which case, drop the normal machine epsilon.
    is_exp_zero(x) && return pos_small_exact(Unum{ESS,FSS})
  end
  #two cases.  The first is if the exponent is really low and our only option is
  #to express the machine epsilon as a subnormal number.  To figure this out, is
  #we need to find the location of the farthest bit.  This is the current exponent
  #plus the fraction size.
  bit_order::Int16 = decode_exp(x) - max_fsize(x) - 1
  if bit_order < min_exponent(FSS)
    disp::UInt16 = min_exponent(FSS) - bit_order - 1
    Unum{ESS,FSS}(disp, max_esize(ESS), z16, __bit_from_top(disp + 1, __frac_cells(FSS)), z64)
  else
    (esize, exponent) = encode_exp(bit_order)
    Unum{ESS,FSS}(z16, esize, z16, z64, exponent)
  end
end
export eps

#maximum, lossless integers
import Base.maxintfloat
function maxintfloat{ESS,FSS}(::Type{Unum{ESS,FSS}})
end
export maxintfloat
=#
