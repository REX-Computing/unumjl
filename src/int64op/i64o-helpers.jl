doc"""
`Unums.max_fsize(::Int64)` retrieves the maximum possible fsize value based on
the FSS value.
"""
max_fsize(FSS::Int64) = UInt16((1 << FSS) - 1)

#two helper functions to enable fracfunc.
function __ffcall(s::Symbol, inner_block, tname, p...)
  fracname = symbol("frac_", s, "!")
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
  :(x.fraction = $inner_call)
end

function __largeexpr(s::Symbol, p...)
  bangsym = symbol(s, "!")
  inner_call = Expr(:call)
  inner_call.args = [bangsym, :(x.fraction), p...]
  inner_call
end

doc"""
`Unums.@fracfunc(fn)` generates two functions that takes Unum{ESS,FSS} and executes
fn on the fraction part of the unum, if FSS < 7.  if FSS >= 7 then it executes
fn! on the fraction part of the unum.
"""
macro fracfunc(name, params...)
  fracname = symbol("frac_", name, "!")
  bangname = symbol(name, "!")
  smallexpr = __smallexpr(name, params...)
  largeexpr = __largeexpr(name, params...)
  smallcall = __ffcall(name, smallexpr, :UnumSmall, params...)
  largecall = __ffcall(name, largeexpr, :UnumLarge, params...)
  esc(quote
    $smallcall
    $largecall
  end)
end
