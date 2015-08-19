#fracwords-speed.jl
#testing the speed of various ways of doing fracwords

const count = 1000000

function fracwords(n::Uint16)
  n < 6 ? 1 : (1 << (n - 6))
end

#enclose in a function body because in julia there are no constant type globals.
function testy(n::Uint16)
println("int(ceil(2^n / 64)): $(int(ceil(2^n/64)))")
tic()
for(i=1:count)
  int(ceil(2^n/64))
end
toc()

println("fracwords(n): $(fracwords(n))")
tic()
  fracwords(n)
toc()

println("direct (1 << (n - 6)): $((1 << (n-6)) + 1)")
tic()
  (1 << (n - 6)) + 1
toc()

println("----")
end

testy(uint16(1))
testy(uint16(1))
testy(uint16(1))
testy(uint16(0))
testy(uint16(7))
testy(uint16(10))

#18 august 2015
#results run on Laptop (Core3 2 Ghz x 2)

#int(ceil(2^n / 64)): 1
#elapsed time: 0.01436043 seconds
#fracwords(n): 1
#elapsed time: 1.034e-6 seconds
#direct (1 << (n - 6)): 1
#elapsed time: 3.24e-7 seconds
#----
#int(ceil(2^n / 64)): 1
#elapsed time: 0.014367216 seconds
#fracwords(n): 1
#elapsed time: 2.96e-7 seconds
#direct (1 << (n - 6)): 1
#elapsed time: 2.41e-7 seconds
#----
#int(ceil(2^n / 64)): 1
#elapsed time: 0.014457885 seconds
#fracwords(n): 1
#elapsed time: 3.38e-7 seconds
#direct (1 << (n - 6)): 1
#elapsed time: 2.13e-7 seconds
#----
#int(ceil(2^n / 64)): 1
#elapsed time: 0.014419658 seconds
#fracwords(n): 1
#elapsed time: 2.34e-7 seconds
#direct (1 << (n - 6)): 1
#elapsed time: 2.11e-7 seconds
#----
#int(ceil(2^n / 64)): 2
#elapsed time: 0.02310422 seconds
#fracwords(n): 2
#elapsed time: 1.061e-6 seconds
#direct (1 << (n - 6)): 3
#elapsed time: 2.44e-7 seconds
#----
#int(ceil(2^n / 64)): 16
#elapsed time: 0.020369992 seconds
#fracwords(n): 16
#elapsed time: 2.21e-7 seconds
#direct (1 << (n - 6)): 17
#elapsed time: 2.2e-7 seconds
#----


#results:  Addind an extra function call seems to not really make a difference,
#while making it far less likely something wonky will happen.  Additionally,
#an extra conditional for small numbers gives the correct answers, so...  Use that.
