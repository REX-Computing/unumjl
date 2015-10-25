#i64o-shifts.jl

#bitshifting operations on superints
#iterative leftshift and rightshift operations on Array SuperInts

lsh(a::Uint64, b::Integer) = a << b
#destructive version which clobbers the existing verion
function lsh!(a::Array{Uint64,1},b::Integer)
  #kick it back to right shift if it's negative
  (b < 0) && (rsh!(a, -b); return)
  l::Integer = length(a)
  #calculate how many cells apart our two ints shall be.
  celldiff::Integer = b >> 6
  #calculate how much we have to shift
  shift::Integer = b % 64
  countershift::Integer = 64 - shift
  #a calculation buffer.
  calcbuffer::Uint64 = zero(Uint64)
  ex_idx::Integer = 1 + celldiff

  for idx = 1:l-celldiff
    calcbuffer = a[ex_idx] << shift
    a[idx] = calcbuffer
    #terminating condition is that we've found the end.
    ex_idx == l && break
    ex_idx += 1
    a[idx] |= a[ex_idx] >> countershift
  end
  #fill out the last cells as zero.
  for idx = (1:celldiff)
    a[l - idx + 1] = zero(Uint64)
  end
  nothing
end
#protective version which doesn't clobber the existing data.
function lsh(a::Array{Uint64, 1}, b::Integer)
  res = copy(a)
  lsh!(res, b)
  res
end

rsh(a::Uint64, b::Integer) = a >> b
function rsh!(a::Array{Uint64, 1}, b::Integer)
  #kick it back to left shift in case we input a negative number.
  (b < 0) && (lsh!(a, -b); return)
  l::Integer = length(a)
  #calculate how many cells apart our two ints shall be.
  celldiff::Integer = b >> 6
  #calculate how much we have to shift
  shift::Integer = b % 64
  countershift::Integer = 64 - shift
  #a calculation buffer.
  calcbuffer::Uint64 = zero(Uint64)
  ex_idx = l - celldiff

  for idx = l:-1:1
    calcbuffer = a[ex_idx] >> shift
    a[idx] = calcbuffer
    #terminating condition is that we've found the end.
    (ex_idx == 1) && break
    ex_idx -= 1
    a[idx] |= a[ex_idx] << countershift
  end

  for idx = 1:(celldiff)
    a[idx] = zero(Uint64)
  end

  nothing
end

function rsh(a::Array{Uint64}, b::Integer)
  res = copy(a)
  rsh!(res, b)
  res
end
