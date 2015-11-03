#profiling speed differences between exponentiation and bitshifting.

const count = 1000000

#enclose in a function body because in julia there are no constant type globals.
function testy()

println("UInt64 1<<3 $(1<<3)")
x::UInt64 = 1
tic()
for(i=1:count)
  x << 3
end
toc()

println("undeclared UInt16 1<<3 $(1<<3)")
z = UInt16(1)
tic()
for(i=1:count)
  z << 3
end
toc()

println("UInt16 1<<3 $(1<<3)")
y::UInt16 = 1
tic()
for(i=1:count)
  y << 3
end
toc()

println("UInt16 2^3 $(2^3)")
q::UInt16 = 2
tic()
for(i=1:count)
  q^3
end
toc()
println("----")

end

#do it three times in case there's something wierd going on with the JIT.
testy()
testy()
testy()

#18 august 2015
#results run on Laptop (Core3 2 Ghz x 2)

#UInt64 1<<3 8
#elapsed time: 1.094e-6 seconds
#undeclared UInt16 1<<3 8
#elapsed time: 1.232e-6 seconds
#UInt16 1<<3 8
#elapsed time: 2.53e-7 seconds
#UInt16 2^3 8
#elapsed time: 0.019976645 seconds
#----
#UInt64 1<<3 8
#elapsed time: 5.39e-7 seconds
#undeclared UInt16 1<<3 8
#elapsed time: 2.75e-7 seconds
#UInt16 1<<3 8
#elapsed time: 2.34e-7 seconds
#UInt16 2^3 8
#elapsed time: 0.020264097 seconds
#----
#UInt64 1<<3 8
#elapsed time: 6.19e-7 seconds
#undeclared UInt16 1<<3 8
#elapsed time: 2.33e-7 seconds
#UInt16 1<<3 8
#elapsed time: 2.35e-7 seconds
#UInt16 2^3 8
#elapsed time: 0.019941948 seconds
#----

#results:  It is a good idea to give the JIT compiler some hints as to what
#you're about to do.  Using UInt16 is much better than using UInt64, bitshifting
#is WAY better than exponentiation.  When profiling, it's a good idea to run
#multiple times, because it seems julia caches its compiled results.
