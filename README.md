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
convert(Unum{4,6}, 4.3)
> Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003)
```

To retrieve the unum value, as a human-readable form, I recommend the calculate() function which converts the unum to BigFloat, which is then displayed by Julia.  Note that calculate doesn’t take into account the uncertainty bit:

```
calculate(Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003))
> 4.3
```

You can alternatively type in the specification directly into the Unum constructor.  
The parts of a unum the unum constructor are as follows:  

1. fsize (16-bit unsigned float)
2. esize (16-bit unsigned float)
3. flags (16-bit unsigned float, 2’s bit: sign, 1’s bit: ubit)
4. fraction (64-bit unsigned float or array of 64-bit unsigned floats)
5. exponent (64-bit unsigned float)

```
x = Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003)
> Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003)
calculate(x)
> 4.3
```


Julia generally has support for special functions which construct important values, and the Unum library implements these.

```
zero(Unum{4,6})
> Unum{4,6}(0x0000, 0x0000, 0x0000, 0x0000000000000000, 0x0000000000000000)
one(Unum{4,6})
> Unum{4,6}(0x0000, 0x0001, 0x0000, 0x0000000000000000, 0x0000000000000001)
inf(Unum{4,6})
> Unum{4,6}(0x003F, 0x000F, 0x0000, 0xFFFFFFFFFFFFFFFF, 0x000000000000FFFF)
nan(Unum{4,6})
> Unum{4,6}(0x003F, 0x000F, 0x0001, 0xFFFFFFFFFFFFFFFF, 0x000000000000FFFF)
```

The standard mathematical operators are overloaded to allow easy calculation with Unums.

```
x = convert(Unum{4,6}, 4.3)
> Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003)
y = one(Unum{4,6})
> Unum{4,6}(0x0000, 0x0001, 0x0000, 0x0000000000000000, 0x0000000000000001)
x + y
> Unum{4,6}(0x0033, 0x0001, 0x0000, 0x5333333333333000, 0x0000000000000003)
calculate(x + y)
> 5.3
```

unumjl was created by Isaac Yonemoto on behalf of [REX Computing Inc.](http://rexcomputing.com)
this work was supported in part by DARPA Contract D15PC00135 awarded to REX Computing, Inc.
