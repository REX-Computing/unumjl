#tools.jl - a few tools which make unum work much smoother...  To be reassigned
#in the directory structure

doc"""
the `@gen_code` macro rejigs the standard julia `@generate` macro so that at the
end the function expects a `code` expression variable that can be created and
automatically extended using the `@code` macro.
"""
macro gen_code(f)
  #make sure this macro precedes a function definition.
  isa(f, Expr) || error("gen_code macro must precede a function definition")
  (f.head == :function) || error("gen_code macro must precede a function definition")

  #automatically generate a 'code-creation' statement at the head of the function.
  unshift!(f.args[2].args, :(code = :(nothing)))
  #insert the code release statement at the tail of the function.
  push!(f.args[2].args, :(code))

  #return the escaped function to the parser so that it generates the new function.
  ##next, wrap the function f inside of the @generated macro and escape it
  esc(:(@generated $f))
end

#a helper function that makes the parsing process much cleaner.
function __append_code(a, b)
  return :($a; $b)
end

doc"""
the `@code` macro is used in conjunction to put a line of code (or a quote) onto
the growing `code` variable that is expected by the `@gen_code` macro.
"""
macro code(e)
  isa(e, Expr) || error("can't generate code from non-expressions")
  #since code variable has already been created, instead append it to the previous code statement.
  return esc(:(code = __append_code(code, $e)))
end

#fname extracts the function name from the expression
function fname(ex::Expr)
  ex.args[1].args[1]
end
#vfunc generates a type-parameter variadic function head.
function vfunc(fn)
  :($fn{ESS,FSS})
end

if options[:devmode]
  to16(n::Int64) = UInt16(n)
else
  to16(n::Int64) = UInt16(reinterpret(UInt64, n) & 0x0000_0000_0000_FFFF)
end
doc"""
  `Unums.to16(::Int64)` converts a signed Int64 value to an unsigned Int16.
  Normally one would do this by doing a direct conversion using call(Int16, ...)
  however, this potentially throws inexact errors, so we will craftily hint to
  LLVM that we are not worried about this possibility, except in dev mode.
"""
to16

doc"""
  the `@universal` macro is prepended to a function defined with parameters that
  are generic Unum types (Unum, Ubound, Gnum), and generates two functions,
  with each of the \*Small{ESS,FSS} and \*Large{ESS,FSS} suffixes.
"""
#creates a universal function f that operates across all types of unums
macro universal(f)
  if (f.head == :(=))
    (f.args[1].head == :call) || throw(ArgumentError("@universal macro must operate on a function"))
  elseif (f.head == :function)
    nothing  #we're good.
  else
    throw(ArgumentError("@universal macro must operate on a function"))
  end

  #copy f into two function definitions, fsmall and flarge
  fsmall = copy(f)
  flarge = copy(f)

  #extract the functionname and append the {ESS,FSS} signature onto the functionname
  functionname = fname(f)
  functioncall = vfunc(functionname)

  fsmall.args[1].args[1] = functioncall
  flarge.args[1].args[1] = functioncall

  #next work with the parameters
  parameters = f.args[1].args

  stypedefs = quote
    G = GnumSmall{ESS,FSS}
    B = UboundSmall{ESS,FSS}
    U = UnumSmall{ESS,FSS}
  end

  ltypedefs = quote
    G = GnumLarge{ESS,FSS}
    B = UboundLarge{ESS,FSS}
    U = UnumLarge{ESS,FSS}
  end

  #append these type definitions onto fsmall and flarge.
  unshift!(fsmall.args[2].args, stypedefs)
  unshift!(flarge.args[2].args, ltypedefs)

  for idx = 2:length(parameters)
    if (isa(parameters[idx], Expr)
         && (parameters[idx].head == :(::)))
      utypeparam = parameters[idx].args[2]
      if (utypeparam in [:Unum, :Ubound, :Gnum])
        stype = symbol(utypeparam, :Small)
        ltype = symbol(utypeparam, :Large)
        fsmall.args[1].args[idx].args[2] = :($stype{ESS,FSS})
        flarge.args[1].args[idx].args[2] = :($ltype{ESS,FSS})
      elseif isa(utypeparam, Expr)
        if (utypeparam.head == :curly) && (utypeparam.args[1] == :Type) && (utypeparam.args[2] in [:Unum, :Ubound, :Gnum])
          stype = symbol(utypeparam.args[2], :Small)
          ltype = symbol(utypeparam.args[2], :Large)
          fsmall.args[1].args[idx].args[2].args[2] = :($stype{ESS,FSS})
          flarge.args[1].args[idx].args[2].args[2] = :($ltype{ESS,FSS})
        end
      end
    end
  end

  return esc(quote
    Base.@__doc__ $fsmall
    $flarge
  end)
end

################################################################################
# unsigned integer shorthands

#sixteen bit numbers
const z16 = zero(UInt16)
const o16 = one(UInt16)
const f16 = UInt16(0xFFFF)

#64 bit numbers
const z64 = zero(UInt64)
const o64 = one(UInt64)
const t64 = 0x8000_0000_0000_0000               #top bit
const f64 = 0xFFFF_FFFF_FFFF_FFFF               #full bits
