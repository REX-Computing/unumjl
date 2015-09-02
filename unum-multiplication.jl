#unum-multiplication.jl
#does multiplication for unums.

function *{ESS,FSS}(a::Unum{ESS,FSS}, b::Unum{ESS,FSS})
  #count how many uints go into the unum.
  #we can break this up into two cases, and maybe merge them later.
  #remember, a and b must have the same environment.
  if length(a.fraction) == 1
    __simple_mult(a, b)
  else
    __poly_mult(a, b)
  end
end


# how to do multiplication?  Just chunk your 64-bit block into two 32-bit
# segments and do multiplication on those.
#
# Ah Al
# Bh Bl  -> AhBh (AhBl + BhAl) AlBl
#
# This should only require 2 Uint64s.  But, also remember that we have a
# 'phantom one' in front of potentially both segments, so we'll throw in a third
# Uint64 in front to handle that.

__M32 = 2^32 - 1

# chunk_mult handles simply the chunked multiply of two int64s
function __chunk_mult(a::Uint64, b::Uint64)
  #chunk into high and low segments
  al = a & __M32
  ah = (a >> 32) & __M32
  bl = b & __M32
  bh = (b >> 32) & __M32
  #calculate all four components of the segment.
  seg3_64 = al * bl
  seg2a_64 = ah * bl
  seg2b_64 = al * bh
  seg1_64 = ah * bh
  #create a scratchpad
  scratchpad = zeros(Uint32, 4)
  scratchpad[1] = uint32(seg3_64)
  #the middle gets complicated
  seg2f_64 = seg2b_64 + seg2a_64 + (seg3_64 >> 32)  #add the 'carry' from seg3 to the first part of seg2
  #this should never exceed int64_max, but it can come close.  so we'll need another carry bit
  seg1_64 += (seg2f_64 < seg2b_64) ? 0x100000000 : 0
  scratchpad[2] = uint32(seg2f_64)
  seg3f_64 = seg1_64 + (seg2f_64 >> 32)
  scratchpad[3] = uint32(seg3f_64)
  scratchpad[4] = uint32(seg3f_64 >> 32)
  #reinterpret the scratchpad as an array of uint64
  reinterpret(Uint64, scratchpad)
end

function __simple_mult{ESS, FSS}(a::Unum{ESS,FSS},b::Unum{ESS,FSS})
  #figure out the sign.  Xor does the trick.
  flags = (a.flags & SIGN_MASK) $ (b.flags & SIGN_MASK)
  #run a chunk_mult on the a and b fractions
  chunkproduct = __chunk_mult(a.fraction, b.fraction)
  #next, steal the carried add function from addition.  We're going to need
  #to re-add the fractions back due to algebra with the phantom bit.
  #
  # i.e.: (1 + a)(1 + b) = 1 + a + b + ab
  # => initial carry + a.fraction + b.fraction + chunkproduct
  #
  fraction = chunkproduct[2]
  (carry, fraction) = __carried_add(1, fraction, a.fraction)
  (carry, fraction) = __carried_add(carry, fraction, b.fraction)
  #our fraction is now just chunkproduct[2]
  #carry may be as high as three!  So we must shift as necessary.
  (fraction, shift, check) = __shift_after_add(carry, fraction)
  #for now, just throw fsize as the blah blah blah.
  fsize = 64 - lsb(fraction)
  fsize = uint16(min(fsize, 2^FSS) - 1)
  #the exponent is just the sum of the two exponents.
  (esize, exponent) = encode_exp(decode_exp(a) + decode_exp(b) + shift)
  #deal with ubit later.
  Unum{ESS,FSS}(fsize, esize, flags, fraction, exponent)
end
