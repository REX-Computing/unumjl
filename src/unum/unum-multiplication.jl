#unum-multiplication.jl
#does multiplication for unums.

doc"""
  `mul!(::Unum, ::Unum, ::Gnum)` takes two unums and
  multiplies them, storing the result in the third, g-layer.  A reference to
  the result gnum is returned.
"""
function mul!{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS}, c::Gnum{ESS,FSS})
  put_unum!(b, c)
  set_g_flags!(a)
  mul!(a, c)
end

import Base.*
doc"""
  `*(x::Unum, y::Unum)` multiplies two unums, by creating a temporary gnum
  and returning the output form.
"""
function *{ESS,FSS}(x::Unum{ESS,FSS}, y::Unum{ESS,FSS})
  temp = zero(Gnum{ESS,FSS})
  mul!(x, y, temp)
  #return the result as the appropriate data type.
  emit_data(temp)
end
