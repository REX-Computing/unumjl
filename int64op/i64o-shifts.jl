#i64o-shifts.jl

#bitshifting operations on superints
#iterative leftshift and rightshift operations on Array SuperInts

lsh(a::Uint64, b::Integer) = a << b
#destructive version which clobbers the existing verion
function lsh!(a::Array{Uint64,1},b::Integer)
  #calculate how many cells apart our two ints shall be.
  celldiff = b >> 6
  #calculate how much we have to shift
  shift = b % 64

  #THIS IS NOT FUNCTIONAL
  #as a courtesy, generate a new array so we don't clobber the old one.
  l = length(a)
  for (idx = l:-1:2)
    (idx - celldiff < 2) && break
    #leftshift it.
    res[idx] = a[idx - celldiff] << shift
    res[idx] |= a[idx - celldiff - 1] >> (64 - shift)
  end
  #then leftshift the last one.
  res[1 + celldiff] = a[1] << shift
  res
end

#protective version which doesn't clobber the existing data.
function lsh(a::Array{Uint64, 1}, b::Integer)
  res = supercopy(a)
  lsh!(res)
  res
end

rsh(a::Uint64, b::Integer) = a >> b
function rsh(a::Array{Uint64, 1}, b::Integer)
  #how many cells apart is our shift
  celldiff = (b >> 6)
  #and how many slots we need to shift
  shift = b % 64
  #as a courtesy, generate a new array so we don't clobber the old one.
  l = length(a)
  res = zeros(Uint64, l)
  for (idx = 1:l - 1)
    (idx + celldiff + 1> l) && break
    #rightshift it.
    res[idx] = a[idx + celldiff] >> shift
    res[idx] |= a[idx + celldiff + 1] << (64 - shift)
  end
  #complete the last one - it's possible that the last one is not there
  (l - celldiff != 0) && (res[l - celldiff] = a[l] >> shift)
  res
end
