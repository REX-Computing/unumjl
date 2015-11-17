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
  ##next, wrap the function f inside of the @generated macro.
  e = :(@generated $f)
  return Expr(:escape, e)
end

#a helper function that makes the parsing process much cleaner.
function __append_code(a, b)
  return :($a; $b)
end

doc"""
the `@code` macro is used in conjunction to put a line of code (or a quote) onto
the growing `code` variable that is expected by the `@code_gen` macro.   If this
is the first `@code` invocation in the function, it will automatically create the
`code` variable.
"""
macro code(e)
  isa(e, Expr) || error("can't generate code from non-expressions")
  #since code variable has already been created, instead append it to the previous code statement.
  return Expr(:escape, :(code = __append_code(code, $e)))
end
