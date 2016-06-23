#devsafety.jl - options and related macros that deal with developer mode safety
#checks.

const __LOADTIME_DEVMODE = options[:devmode]

doc"""
  `@devmode_on` initiates a section of code where developer checking is guaranteed to be "on".
  This code is not executed if developer mode was off at loadtime.
"""
macro devmode_on(expr)
  if __LOADTIME_DEVMODE

    #add this to the front
    unshift!(expr.args, quote
      cache = Unums.options[:devmode]
      Unums.options[:devmode] = true
    end)

    #add this to the end
    push!(expr.args, quote
      Unums.options[:devmode] = cache
    end)

    esc(expr)
  else
    :()
  end
end

doc"""
  `@devmode_off` initiates a section of code where developer checking is guaranteed to
  "off".
"""
macro devmode_off(expr)
  if __LOADTIME_DEVMODE

    #add this to the front
    unshift!(expr.args, quote
      cache = Unums.options[:devmode]
      Unums.options[:devmode] = false
    end)

    #add this to the end
    push!(expr.args, quote
      Unums.options[:devmode] = cache
    end)

    esc(expr)
  else
    :()
  end
end

export @devmode_on, @devmode_off

################################################################################
# @dev_check macro which uses reflection to automatically execute a function
# parameters integrity check before certain functions.

function __extract_function_string(fvar)
  #for variadic functions, the function name parameter appears as part of an
  #implicit untyped array.  This takes care of this.
  isa(fvar, Symbol) && return string(fvar)
  if isa(fvar, Expr) && (fvar.head == :curly)
    return string(fvar.args[1])
  end
  error("malformed function head.")
end

#strips the variable name off the expression, if it's just a symbol we return it
#if it's more, then we
function getvariable(e)
  isa(e, Symbol) && return e
  if isa(e, Expr)
    e.head == :(::) && return e.args[1]
  end
end

doc"""
the `@dev_check` macro injects a conditional check that sees if
`options[:devmode]` is set.  If it is, `@dev_check` inserts a line of code
that expects a companion function with symbol `__check_[functionname]`.  This
function is passed the same parameters as the parent function and is expected
to throw an error if parameter preconditions are violated.

For types it may be necessary to check the parameters passed to the constructor.
The type-variadic parameters will be passed to the check function immediately in
front of the type parameters.
"""
macro dev_check(expr)
  #bail with an unaltered expression if we haven't set the developer mode.
  options[:devmode] || return expr
  #make sure this macro precedes a function definition.
  isa(expr, Expr) || ArgumentError("checkable macro must precede a function or type definition")
  if (expr.head == :function)
    #prepend a __check_ prefix to the function name.
    #do a little bit of syntactic sugar to fix functions that already start with __
    fnstring = string("__check_", __extract_function_string(expr.args[1].args[1]))
    fparams = join(map(getvariable, expr.args[1].args[2:end]), ", ")
    #generate the line of code to be executed, pass it to parse.
    b2 = parse("$fnstring($fparams)")
    #inject the faux line number and the generated code into the ast.
    unshift!(expr.args[2].args, b2)
    #return the escaped function to the parser so that it generates the new function.

    return esc(expr)
  elseif (expr.head == :type)
    #what to do if dev_check is appied to a type statement.
    typesig = expr.args[2]    #extract the type signature
    typemembers = filter((e) -> (e.head != :line), expr.args[3].args)  #extract the type members, with typing info
    typevars = map((e) -> (e.args[1]), typemembers)                    #a list of type variables, without typing info

    #type signature might be a complex expression or it might be a single symbol.
    if isa(typesig, Expr)
      if typesig.head == :curly
        typename = typesig.args[1]
        varparams = typesig.args[2:end]
      elseif typesig.head == :<:
        typename = typesig.args[1].args[1]
        varparams = typesig.args[1].args[2:end]
      else
        throw(ArgumentError("malformed type expression passed to @dev_check"))
      end
    else
      typename = typesig
      varparams = []
    end

    constructor = Expr(:function)
    callexp = Expr(:call)
    push!(callexp.args, typename)
    append!(callexp.args, typemembers)

    #assemble the call to the check function
    checkname = symbol("__check_", typename)
    checkcall = Expr(:call)
    push!(checkcall.args, checkname)
    append!(checkcall.args, varparams)  #first add the variadic parameters
    append!(checkcall.args, typevars)   #then add the the type parameters

    #create the check expression which is dependent on the global options variable
    check_expr = :(options[:devmode] && $checkcall)

    #assemble the call to the stealth "new" constructor.
    newcall = Expr(:call)
    push!(newcall.args, :new)
    append!(newcall.args, typevars)

    #assemble fnblock
    fnblock = Expr(:block)
    push!(fnblock.args, check_expr)
    push!(fnblock.args, newcall)

    #assemble the substitute constructor.
    push!(constructor.args, callexp)
    push!(constructor.args, fnblock)

    #append the substitute constructor onto the end of the type definition
    push!(expr.args[3].args, constructor)

    return esc(expr)
  else
    ArgumentError("checkable macro must precede a function or type definition")
  end
end

doc"""
  `Unums.@devmode(expr)` makes the expression disappear if we're not in developer mode.
"""
macro devmode(expr)
  if options[:devmode]
    expr
  else
    :()
  end
end
