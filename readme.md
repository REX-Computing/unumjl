README
------

This is a pure Julia implementation of the unum prototype created by John Gustafson.

This implementation is a bitwise, binary implementation, intended as a first-stage
look at what hardware unums might look like.  The representation is not an exact
bitwise replica of the unum spec as outlined in "The End of Error" and deviates
in the following ways:

1. instead of having a global environment setting which determines fsizesize and
esizesize, the unum data carry in its type information fsizesize and esizesize.
Using Julia's multiple dispatch features, the respective operations for this
"environment" are compiled on the fly and are generated as needed for the program.
2. instead of carrying the unum as a string of bits with variable length, the
components of the unum are stored as members of a structure.  In particular,
esize and fsize are stored as unsigned 16-bit integers, exponent is an unsigned
integer, fraction is a variable length 64-bit unsigned integer array, and sign
and ubit are bitmapped into a single 'flags' 16-bit unsigned integer member.
  1. 'fraction' is a left-padded number.  This greatly simplifies the multiplication operation in the emulated system.
  2. other positions in the 'flags' variable are reserved for 'g-layer' flags
that may come in handy in the future.
3.  esizesize is restricted to 6, fsizesize is restricted to 16.  (in TEoE, the restrictions are 4, and 11, respectively - (p 349).)

what this implementation does NOT do:

It isn't a complete bitwise hardware simulation.  Elementary integer operations
are implemented directly, for efficiency purposes, actual hardware should use
"essentially these" as manifestation.

The functions avoid side-effects to respect parallelism.  A future version might
implement "modular calculation units" with pre-allocated memory that more closely
emulates static computational requirements for hardware (this will be the strategy
for the C version) - but doing so will explicitly not be parallel unless each
process can be instructed to allocate its own calculation unit.

Motivation:
The motivation for implementing this in julia is two-fold:  Exploration and
confirmation of the operating character of the bitwise operations.  Secondly,
these functions will be implemented in C, and that will enable "shimming" of
the various C functions for verification purposes, ultimately leading to a fast
C library which even more closely emulates the processes that hardware will
implement.

How to use the Julia Unum library (0.1):
========================================

install julia.  instructions for download and files are available at: http://julialang.org/downloads/
unzip the unum package and execute julia in the directory.
at the prompt, type: 

```
include(“unum.jl”)
using Unums
```

alternatively, use these commands as the first lines of a script and execute the script by typing julia PATH_TO_SCRIPT at your command line.


You may now use unums.  To convert floating points or integers to unums, use the convert function, e.g.:
```
convert(Unum{4,6}, 4.3)
> Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003)
```

You can alternatively type in the specification directly into the Unum constructor.  The parts of a unum the unum constructor are as follows:  fsize (16-bit unsigned float), esize (16-bit unsigned float), flags (16-bit unsigned float, 2’s bit: sign, 1’s bit: ubit), fraction (64-bit unsigned float or array of 64-bit unsigned floats), exponent (64-bit unsigned float).  e.g.:

```
Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003)
> Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003)
```

To retrieve the unum value, as a human-readable form, I recommend the calculate() function which converts the unum to BigFloat, which is then displayed by Julia, e.g.  Note that calculate doesn’t take into account the uncertainty bit:

```
calculate(Unum{4,6}(0x0033, 0x0001, 0x0000, 0x1333333333333000, 0x0000000000000003))
> 4.3
```

Julia generally has support for special functions which construct frequently used values, and the Unum library implements these.

```
zero(Unum{4,6})
> Unum{4,6}(0x0000, 0x0000, 0x0000, 0x0000000000000000, 0x0000000000000000)
one(Unum{4,6})
> Unum{4,6}(0x0000, 0x0001, 0x0000, 0x0000000000000000, 0x0000000000000001)
inf(Unum{4,6})
> Unum{4,6}(0x0000, 0x0001, 0x0000, 0x0000000000000000, 0x0000000000000001)
nan(Unum{4,6})
> Unum{4,6}(0x0000, 0x0001, 0x0000, 0x0000000000000000, 0x0000000000000001)
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
