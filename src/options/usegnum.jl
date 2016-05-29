#usegnum.jl creates a @bind_operation macro which binds unum and gnum operations
#to their respective operations depending on whether or not the :usegnum option
#is set.

doc"""
  `@bind_operation` uses julia's multiple dispatch capability to bind standard
  binary numerical operations to standard "word" functions.  For example, the
  macro:

    @bind_operation + add

  will generate functions mapping all relevant + combinations to the add_create
  function or the add! functions (which release gnums), if :use_gnum is specified,
  otherwise, mapping + to the simple "add" function
"""
macro bind_operation(op, fsymbol)
  gsymbol = symbol(fsymbol, "!")
  gcreate = symbol(fsymbol, "_create")
  if options[:usegnum]
    quote
      @universal $op(a::Unum,   b::Unum)   = $gcreate(a, b)
      @universal $op(a::Unum,   b::Ubound) = $gcreate(a, b)
      @universal $op(a::Ubound, b::Unum)   = $gcreate(a, b)
      @universal $op(a::Ubound, b::Ubound) = $gcreate(a, b)

      @universal $op(a::Unum,   b::Gnum)   = $gsymbol(a, b)
      @universal $op(a::Ubound, b::Gnum)   = $gsymbol(a, b)
      @universal $op(a::Gnum,   b::Unum)   = $gsymbol(a, b)
      @universal $op(a::Gnum,   b::Ubound) = $gsymbol(a, b)
      @universal $op(a::Gnum,   b::Gnum)   = $gsymbol(a, b)
    end
  else
    quote
      @universal $op(a::Unum, b::Unum)     = $fsymbol(a, b)
      @universal $op(a::Unum, b::Ubound)   = $fsymbol(a, b)
      @universal $op(a::Unum, b::Ubound)   = $fsymbol(a, b)
      @universal $op(a::Ubound, b::Ubound) = $fsymbol(a, b)
    end
  end
end
