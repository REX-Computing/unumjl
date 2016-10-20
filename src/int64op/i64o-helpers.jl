#i64o-helpers.jl
#various utility functions that operate on ArrayNums as well as metaprogramming
#macros to help duplicate functions for both standard 64-bit integers and
#arraynums.

doc"""
`Unums.max_fsize(::Int64)` retrieves the maximum possible fsize value based on
the FSS value.
"""
max_fsize(FSS::Int64) = to16((1 << FSS) - 1)

#two helper functions to enable fracproc.
function __ffcall(s::Symbol, inner_block, tname, p...)
  fracname = Symbol("frac_", s, "!")
  #outer_curly is the curly variadic notation for the function name.
  outer_curly = Expr(:curly)
  append!(outer_curly.args, [fracname, :ESS, :FSS])
  #build up the outer call, which is the representation for the full function definition
  outer_call = Expr(:call)
  append!(outer_call.args, [outer_curly, :(x::$tname{ESS,FSS}), p...])
  #build up the outer block, which is the actual code.
  outer_block = Expr(:block)
  push!(outer_block.args, inner_block)
  #build up the full outer function, which merges the call and the block.
  outer_function = Expr(:function)
  push!(outer_function.args, outer_call)
  push!(outer_function.args, outer_block)
  outer_function
end

function __smallexpr(s::Symbol, p...)
  #build up the inner call mechanism
  inner_call = Expr(:call)
  inner_call.args = [s, :(x.fraction), p...]
  :(x.fraction = $inner_call; x)
end

function __largeexpr(s::Symbol, p...)
  bangsym = Symbol(s, "!")
  inner_call = Expr(:call)
  inner_call.args = [bangsym, :(x.fraction), p...]
  :($inner_call; x)
end

doc"""
`Unums.@fracproc(fn)` generates two functions that takes Unum{ESS,FSS} and executes
fn on the fraction part of the unum, if FSS < 7.  if FSS >= 7 then it executes
fn! on the fraction part of the unum.
"""
macro fracproc(name, params...)
  fracname = Symbol("frac_", name, "!")
  bangname = Symbol(name, "!")
  smallexpr = __smallexpr(name, params...)
  largeexpr = __largeexpr(name, params...)
  smallcall = __ffcall(name, smallexpr, :UnumSmall, params...)
  largecall = __ffcall(name, largeexpr, :UnumLarge, params...)
  esc(quote
    Base.@__doc__ $smallcall
    $largecall
  end)
end
