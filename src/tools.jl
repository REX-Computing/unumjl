#tools.jl - non-unicode operators which make unum work much smoother

doc"""
`gen_code` rejigs the standard julia `@generate` macro so that it creates a `code`
expression variable that can be extended using the `@code` macro.  At the end of
the function it automatically outputs the result.
"""
macro gen_code(f)
  #make sure this macro precedes a function definition.
  isa(f, Expr) || error("gen_code macro must precede a function definition")
  (f.head == :function) || error("gen_code macro must precede a function definition")

  ##first, tool around and modify the interior of the function f.

  #prepend creation of the code variable to the beginning of the function
  unshift!(f.args[2].args, :(code = :nothing))
  #push returning the code variable to the end of the function
  push!(f.args[2].args, :(code))
  #return the escaped function to the parser so that it generates the new function.

  ##next, wrap the function f inside of the @generated macro.
  e = :(@generated $f)
  return Expr(:escape, e)
end

function __append_code(a, b)
  return :($a; $b)
end

doc"""
`code` the code macro is used to put a line of code (or a quote) onto the growing
gen_code function.
"""
macro code(e)
  isa(e, Expr) || error("can't generate code from non-expressions")
  return Expr(:escape, :(code = __append_code(code, $e)))
end
