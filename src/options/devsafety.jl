doc"""
constant `Unums.__DEV_MODE` is a global developer-mode variable which enables compile-time
optimization of Unum by removing certain safety checks.
"""
const __DEV_MODE = true

doc"""
variable `Unums.__DEV_CHECK` is a run-time variable which can be used to temporarly
disable safety checks in favor of Unum performance, but is naturally overridden
by `__DEV_MODE`.  functions incorporating checks will still incur a minor
performance penalty at the head of their execution.
"""
global __DEV_CHECK = true

doc"""
`__set_dev_check()` sets the `__DEV_CHECK` variable to true, this is necessary
because julia doesn't permit setting variables in other modules.
"""
__set_dev_check() = (global __DEV_CHECK = true; nothing)

doc"""
`__unset_dev_check()` sets the `__DEV_CHECK` variable to false, this is necessary
because julia doesn't permit setting variables in other modules.
"""
__unset_dev_check() = (global __DEV_CHECK = false; nothing)

doc"""
`__dev_check_state()` returns the state of the `__DEV_CHECK` variable, this is
necessary because julia doesn't permit setting variables in other modules.
"""
__dev_check_state() = __DEV_CHECK

function __extract_function_string(fvar)
  #for variadic functions, the function name parameter appears as part of an
  #implicit untyped array.  This takes care of this.
  isa(fvar, Symbol) && return string(fvar)
  if isa(fvar, Expr) && (fvar.head == :curly)
    return string(fvar.args[1])
  end
  error("malformed function head.")
end

doc"""
the `@dev_check` macro injects a conditional check that sees if `__DEV_MODE` and
`__DEV_CHECK` have been set.  If both are set, then it inserts a line of code
that expects a companion function with symbol `__check_[functionname]`.  This
function is passed the same parameters as the parent function and is expected
to throw an error if parameter terms are violated.

For type constructors it may be necessary to pass variadic type parameters.
Use `@dev_check [vParams...] function...` in this situation.  The variadic
parameters will be passed to the function before the standard function parameters.
"""
macro dev_check(ips...)
  #the function definition should be the last item in the list.
  f = last(ips)
  #we may also want to include some variadic parameters in the function definition.
  variadics = ips[1:end-1]
  #make sure this macro precedes a function definition.
  isa(f, Expr) || error("checkable macro must precede a function definition")
  (f.head == :function) || error("checkable macro must precede a function definition")

  #prepend a __check_ prefix to the function name.
  #do a little bit of syntactic sugar to fix functions that already start with __
  fnstring = __extract_function_string(f.args[1].args[1])
  fnstring = ismatch(r"__.*", fnstring) ? fnstring[3:end] : fnstring
  checkcall = string("__check_", fnstring)
  #generate the parameters string
  params = join(variadics, ", ")
  fparams = join(f.args[1].args[2:end], ", ")
  params = isempty(variadics) ? fparams : string(params, ", ", fparams)
  #generate the line of code to be executed, pass it to parse.
  b2 = parse(string("__DEV_MODE && __DEV_CHECK && $checkcall($params)"))
  #inject the faux line number and the generated code into the ast.
  unshift!(f.args[2].args, b2)
  #return the escaped function to the parser so that it generates the new function.
  return Expr(:escape, f)
end

#necessary to fix get @test into the proper scope.
import Base.Test.@test
import Base.Test.@test_throws

macro unum_dev_switch(code)
  quote
    if Unums.__DEV_MODE
      #unset the development environment
      dev_check = Unums.__dev_check_state()

      $code

      dev_check && Unums.__set_dev_check()
    end
  end
end

macro unum_dev_on()
  quote
    Unums.__set_dev_check()
    @test Unums.__dev_check_state()
  end
end

macro unum_dev_off()
  quote
    Unums.__unset_dev_check()
    @test !Unums.__dev_check_state()
  end
end

export @unum_dev_switch, @unum_dev_on, @unum_dev_off

nothing
