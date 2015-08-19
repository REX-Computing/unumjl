#unum-typefunctions.jl

#functions that operate on a unum type and retrieve certain properties.

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
export fsizesize

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
export esizesize

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
