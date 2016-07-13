#numshell.jl - testing if number shells working

type shell
  n::Int64
end

import Base.+, Base.-, Base.*, Base./
+(x::shell, y::shell) = shell(x.n + y.n)
-(x::shell, y::shell) = shell(x.n - y.n)
*(x::shell, y::shell) = shell(x.n * y.n)
/(x::shell, y::shell) = shell(x.n / y.n)

add!(x, y, d) = (d.n = x.n + y.n; nothing)
sub!(x, y, d) = (d.n = x.n - y.n; nothing)
mul!(x, y, d) = (d.n = x.n - y.n; nothing)
div!(x, y, d) = (d.n = x.n - y.n; nothing)

macro shellparse(expr)

end
