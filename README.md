How to use the Julia Unum library (0.1):
========================================

1. install julia.
  1. instructions for download and files are available at: http://julialang.org/downloads/
2. unzip the unum package and execute julia in the directory.
3. at the prompt, type:
  ```
  include(“unum.jl”); using Unums
  ```
  1.  alternatively, use these commands as the first lines of a script and execute the script by typing julia SCRIPT_FILENAME at your command line.

You may now use unums.  To convert floating points or integers to unums, use the convert function.  Note that the conversion currently assumes that floating points represent exact values, even if the human-input value cannot be exact.

```
julia> Unum{3,4}(4.3)
Unum{3,4}(0x0000000000000003, 0x1333000000000000, 0x0001, 0x0001, 0x000F)
julia> Unum{4,6}(4.3)
Unum{4,6}(0x0000000000000401, 0x1333333333333000, 0x0000, 0x000A, 0x0033)
```

To retrieve the unum value, as a human-readable form, I recommend the describe()
function which converts Unums and Ubounds to human-readable format.  In the future,
this input format will be natively parseable in julia to generate the appropriate
unum.

```
julia> describe(Unum{3,4}(0x0000000000000003, 0x1333000000000000, 0x0001, 0x0001, 0x000F))
Unum{3,4}(4.29998779296875 op → 4.300048828125 op)
```

You can alternatively type in the specification directly into the Unum constructor.  
The parts of a unum the unum constructor are as follows:  

5. exponent (64-bit unsigned float)
4. fraction (64-bit unsigned float or array of 64-bit unsigned floats)
3. flags (16-bit unsigned float, 2’s bit: sign, 1’s bit: ubit)
2. esize (16-bit unsigned float)
1. fsize (16-bit unsigned float)



Julia generally has support for special functions which construct important constants, and the Unum library implements these.
```
julia> describe(zero(Unum{3,4}))
Unum{3,4}(0.0 ex)
julia> describe(one(Unum{3,4}))
Unum{3,4}(1.0 ex)
julia> describe(inf(Unum{3,4}))
Unum{3,4}(∞ ex)
julia> describe(nan(Unum{3,4}))
Unum{3,4}(NaN)

```

The standard mathematical operators are overloaded to allow easy calculation with Unums.

```
julia> x = Unum{3,4}(4.3)
Unum{3,4}(0x0000000000000003, 0x1333000000000000, 0x0001, 0x0001, 0x000F)
julia> y = one(Unum{3,4})
Unum{3,4}(0x0000000000000001, 0x0000000000000000, 0x0000, 0x0001, 0x0000)
julia> x + y
Unum{3,4}(0x0000000000000003, 0x5333000000000000, 0x0001, 0x0001, 0x000F)
julia> describe(x + y)
Unum{3,4}(5.29998779296875 op → 5.300048828125 op)

julia> x = one(Unum{3,4})
Unum{3,4}(0x0000000000000001, 0x0000000000000000, 0x0000, 0x0001, 0x0000)
julia> y = Unum{3,4}(3)
Unum{3,4}(0x0000000000000001, 0x8000000000000000, 0x0000, 0x0000, 0x0000)
julia> x / y
Unum{3,4}(0x0000000000000001, 0x5555000000000000, 0x0001, 0x0002, 0x000F)
julia> describe(x / y)
Unum{3,4}(0.3333320617675781 op → 0.33333587646484375 op)

julia> x = one(Unum{4,7})
Unum{4,7}(0x0000000000000001, UInt64[0x0000000000000000,0x0000000000000000], 0x0000, 0x0001, 0x0000)
julia> y = Unum{4,7}(3)
Unum{4,7}(0x0000000000000001, UInt64[0x8000000000000000,0x0000000000000000], 0x0000, 0x0000, 0x0001)
julia> x / y
Unum{4,7}(0x0000000000000001, UInt64[0x5555555555555555,0x5555555555555555], 0x0001, 0x0002, 0x007F)
julia> describe(x / y)
Unum{4,7}(3.333333333333333333333333333333333333330884386769120234358398465547453654837878e-01 op → 3.333333333333333333333333333333333333338231226461759531283203068905092690324244e-01 op)

```

unumjl was created by Isaac Yonemoto on behalf of [REX Computing Inc.](http://rexcomputing.com)
this work was supported in part by DARPA Contract D15PC00135 awarded to REX Computing, Inc.
