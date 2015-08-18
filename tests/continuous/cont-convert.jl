#cont-convert.jl
#continuous conversion tests on conversions

include("unum-continuous.jl")

#performs a conversion wherin we try every possible bit permutation of the unum
#and then run the following steps:
# 1) random float
# 2) convert to unum
# 3) direct calculate float from unum
# 4) check to make sure 1 & 3 are the same
# 4) convert back to float from unum
# 5) check to make sure 4 & 1 are the same
