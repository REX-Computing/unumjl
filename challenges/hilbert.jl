#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#hilbert.jl
#tests inverting a hilbert matrix.  All of the entries *should* be integers.

vtypes = [Float16, Float32, Float64, BigFloat]

#generate a hilbert matrix
function hilbert(T::Type, n)
  [1 / (convert(T, x + y - 1)) for x=1:n, y=1:n]
end

for T in vtypes
  for i in 1:10
    h = hilbert(T, i)

    invh = h^(-1)

    println("hilbert matrix $(i) upper corner in $(T) should be $(i ^ 2) but is: $(invh[1,1])")
  end
end
