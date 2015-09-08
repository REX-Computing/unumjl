README
------

This is a pure Julia implementation of the unum prototype created by John Gustafson.

This implementation is a bitwise, binary implementation, intended as a first-stage
look at what hardware unums might look like.  The representation is not an exact
bitwise replica of the unum spec as outlined in "The End of Error" and deviates
in the following ways:

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

Motivation:
The motivation for implementing this in julia is two-fold:  Exploration and
confirmation of the operating character of the bitwise operations.  Secondly,
these functions will be implemented in C, and that will enable "shimming" of
the various C functions for verification purposes, ultimately leading to a fast
C library which even more closely emulates the processes that hardware will
implement.
