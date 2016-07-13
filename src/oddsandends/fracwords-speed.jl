#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#fracwords-speed.jl
#testing the speed of various ways of doing fracwords

const count = 10000000

function fracwords(n::UInt16)
  n < 6 ? 1 : (1 << (n - 6))
end

#enclose in a function body because in julia there are no constant type globals.
function testy(n::UInt16)
println("int(ceil(2^n / 64)): $(int(ceil(2^n/64)))")
res = 0
tic()
for(i=1:count)
  res = int(ceil(2^n/64))
end
toc()
#println forces julia to use the result and not compile it away.
println(res)

println("fracwords(n): $(fracwords(n))")
tic()
for(i=1:count)
  res = fracwords(n)
end
toc()
println(res)

println("direct n > 6 ? 1 : (1 << (n - 6)): $((1 << (n-6)) + 1)")
tic()
for(i=1:count)
  res = n < 6 ? 1: (1 << (n - 6))
end
toc()
println(res)

println("----")
end

testy(UInt16(1))
testy(UInt16(1))
testy(UInt16(1))
testy(UInt16(0))
testy(UInt16(7))
testy(UInt16(10))

#20 august 2015
#fixed code, ran again.  Note that about 10x more runs are being done now.
#results run on Laptop (Core3 2 Ghz x 2)

#int(ceil(2^n / 64)): 1
#elapsed time: 0.145344527 seconds
#1
#fracwords(n): 1
#elapsed time: 0.004367947 seconds
#1
#direct (1 << (n - 6)): 1
#elapsed time: 0.004367371 seconds
#1
#----
#int(ceil(2^n / 64)): 1
#elapsed time: 0.145334126 seconds
#1
#fracwords(n): 1
#elapsed time: 0.004361422 seconds
#1
#direct (1 << (n - 6)): 1
#elapsed time: 0.004363537 seconds
#1
#----
#int(ceil(2^n / 64)): 1
#elapsed time: 0.145350655 seconds
#1
#fracwords(n): 1
#elapsed time: 0.004363412 seconds
#1
#direct (1 << (n - 6)): 1
#elapsed time: 0.004392828 seconds
#1
#----
#int(ceil(2^n / 64)): 1
#elapsed time: 0.14566474 seconds
#1
#fracwords(n): 1
#elapsed time: 0.004361116 seconds
#1
#direct (1 << (n - 6)): 1
#elapsed time: 0.004361952 seconds
#1
#----
#int(ceil(2^n / 64)): 2
#elapsed time: 0.229761836 seconds
#2
#fracwords(n): 2
#elapsed time: 0.004361318 seconds
#2
#direct (1 << (n - 6)): 3
#elapsed time: 0.004363907 seconds
#2
#----
#int(ceil(2^n / 64)): 16
#elapsed time: 0.203764237 seconds
#16
#fracwords(n): 16
#elapsed time: 0.00436676 seconds
#16
#direct (1 << (n - 6)): 17
#elapsed time: 0.00436218 seconds
#16
#----

#results:  Addind an extra function call seems to not really make a difference,
#while making it far less likely something wonky will happen.  Additionally,
#an extra conditional for small numbers gives the correct answers, so...  Use that.
