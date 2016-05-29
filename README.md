README
------

This is a pure Julia implementation of the unum prototype created by John Gustafson.

This implementation is a bitwise, binary implementation, intended as a software
approximation of what hardware unums might look like.  One benefit of using
Julia is that the advanced type system makes selecting the Unum environment
easy and, cosmetically, identical to the presentation in "The End of Error"

Using Unums
-----------

The Unum{4,6} type is an effective container for Float64, and the Unum{3,5} type
Is an effective container for Float32.

  one = convert(Unum{4,6}, 1.0)
  two = convert(Unum{4,6}, 2.0)

You can use the "calculate" feature to calculate a Unum as a bigfloat.  Future
versions will have better support for presenting Unums.

  calculate(one + two) #==> 3.0

You can't mix calculations of unums in mixed environments.

  one32 = convert(Unum{3,5}, 1.0f)
  calculate(one32 + two) #==> argument error

You can also use the @glayer macro to pre-allocate space for bulk data
operations.  This may result in improved operation performance

  array1[idx] = convert(Unum{4,6}, rand(10000))
  array1[idx] = convert(Unum{4,6}, rand(10000))
  array1[idx] = convert(Unum{4,6}, rand(10000))

  result = Utype[10000]

  for idx = 1:10000
    result[idx] = @glayer array1[idx] + array2[idx] * array3[idx]
  end

Under the hood
--------------

The representation is not an exact bitwise replica of the unum spec as outlined
in "The End of Error" and deviates in the following ways:

1) instead of having a global environment setting which determines fsizesize and
esizesize, the unum data carry in its type information fsizesize and esizesize.
Using Julia's multiple dispatch features, the respective operations for this
"environment" are compiled on the fly and are generated as needed for the program.

2) instead of carrying the unum as a string of bits with variable length, the
components of the unum are stored as members of a structure.  In particular,
esize and fsize are stored as unsigned 16-bit integers, exponent is an unsigned
integer, fraction is a variable length 64-bit unsigned integer array, and sign
and ubit are bitmapped into a single 'flags' 16-bit unsigned integer member.

2a) 'fraction' is a left-padded number.  This greatly simplifies the multiplication
operation in the emulated system.

2b) other positions in the 'flags' variable are reserved for 'g-layer' flags
that may come in handy in the future.

3) esizesize is restricted to 6, fsizesize is restricted to 16.  (in TEoE, the
  restrictions are 4, and 11, respectively - (p 349).)

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

Using unumjl
------------



unumjl was created by Isaac Yonemoto on behalf of Rex Computing

this work was funded by DARPA, Proposal D151-004-0070
