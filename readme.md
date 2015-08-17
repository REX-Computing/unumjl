README
------

Julia support for byte padded unums.

byte padded unums are a bit different from the description in the book "unum",
but are largely inspired by them.  The unum format is as follows:

A BB...BB (1)CC...CC D E...E F...F <G,H>

Description of components.
A:        sign bit, 1 = "-", 0 = "+"
BB...BB:  exponent, values denormalized such that 2^(length(B)) = 2^(length(B) - 1)
CC...CC:  fraction
D:        uncertainty bit
E...E:    length of the exponent, in bits
F...F:    length of the fraction, in bits
<G,H>:    environment variables setting the length (in bits) of the unum

byte-padded unums look like this:
BB...BB (1)CC...CC AD E...E F...F <G,H>

The most notable difference is that the sign bit and the uncertainty bit are
stored as the 0th and 1st lsb in the "C" value.  Secondly, sections B, C, E, and F
are in multiples of 8 bits.  Thirdly, section C is aligned against the left of
the word.
