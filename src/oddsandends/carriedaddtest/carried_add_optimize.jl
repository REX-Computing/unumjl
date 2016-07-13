# Copyright (c) 2015 Rex Computing and Isaac Yonemoto"
# see LICENSE.txt
# this work was supported in part by DARPA Contract D15PC00135

#an i64array made for fsizesize.  Helps multiple dispatch and generated functions
#optimize for certain complex array operations.

__cell_length(FSS) = 1 << (FSS - 6)

type I64Array{FSS}
  a::Array{UInt64,1}
  function I64Array(a::Array{UInt64,1})
    FSS < 7 && throw(ArgumentError("invalid FSS == $FSS < 7"))
    _al = __cell_length(FSS)
    length(a) != _al && throw(ArgumentError("invalid array length, should be $_al != $(length(a))"))
    new(a)
  end
end

Base.rand{FSS}(::Type{I64Array{FSS}}) = I64Array{FSS}(rand(UInt64, __cell_length(FSS)))

#performs a carried add on an unsigned integer array, the old-fashioned way.
function __carried_add_dumb(carry::UInt64, v1::I64Array, v2::I64Array)
  #first perform a direct sum on the integer arrays
  res = v1.a + v2.a
  #iterate downward from the least significant word
  for idx = length(v1.a):-1:2
    #if it looks like it's lower than it should be, then make it okay.
    @inbounds (res[idx] <= v1.a[idx]) && (res[idx - 1] += 1)
  end
  #add the last word with a carry.
  @inbounds carry += res[1] < v1.a[1] ? 0 : 1
  (carry, res)
end

#performs a carried add on an unsigned integer array, using type dispatch
function __carried_add_td{FSS}(carry::UInt64, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)
  res = v1.a + v2.a
  for idx = l:-1:2
    @inbounds (res[idx] <= v1.a[idx]) && (res[idx - 1] += 1)
  end
  @inbounds carry += res[1] < v1.a[1] ? 0 : 1
  (carry, res)
end

#performs a carried add on an unsigned integer array, using a generated function
@generated function __carried_add_gn{FSS}(carry::UInt64, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)

  loop = :()
  for idx = l:-1:2
    loop = :($loop; @inbounds (res[$idx] <= v1.a[$idx]) && (res[$idx - 1] += 1))
  end

  quote
    res = v1.a + v2.a

    $loop

    @inbounds carry += (res[1] < v1.a[1]) ? 0 : 1
    (carry, res)
  end
end

#doubly unroll this guy
@generated function __carried_add_du{FSS}(carry::UInt64, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)
  ex = :(res = zeros(UInt64, $l))
  for idx = l:-1:1
    ex = :($ex; @inbounds res[$idx] = v1.a[$idx] + v2.a[$idx])
  end
  for idx = l:-1:2
    ex = :($ex; @inbounds (res[$idx] <= v1.a[$idx]) && (res[$idx - 1] += 1))
  end
  ex = :($ex; @inbounds carry += res[1] < v1.a[1] ? 0 : 1)
  return :($ex; (carry, res))
end

const PREALLOC_ARRAY = zeros(UInt64, 32)

@generated function __carried_add_dupa{FSS}(carry::UInt64, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)
  ex = :(@simd for idx = 1:$l
           @inbounds PREALLOC_ARRAY[idx] = v1.a[idx] + v2.a[idx]
         end)
  for idx = l:-1:2
    ex = :($ex; @inbounds (PREALLOC_ARRAY[$idx] <= v1.a[$idx]) && (PREALLOC_ARRAY[$idx - 1] += 1))
  end
  ex = :($ex; @inbounds carry += PREALLOC_ARRAY[1] < v1.a[1] ? 0 : 1)
  return :($ex; (carry, slice(PREALLOC_ARRAY, 1:$l)))
end

@generated function __carried_add_res{FSS}(carry::UInt64, res::I64Array{FSS}, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)
  loop = :()
  for idx = l:-1:2
    loop = :($loop; @inbounds (res.a[$idx] <= v1.a[$idx]) && (res.a[$idx - 1] += 1))
  end

  quote
    res.a = v1.a + v2.a

    $loop

    @inbounds carry += (res.a[1] < v1.a[1]) ? 0 : 1
    carry
  end
end

@generated function __carried_add_res2{FSS}(carry::UInt64, res::I64Array{FSS}, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)

  loop1 = :()
  for idx = l:-1:1
    loop1 = :($loop1; @inbounds res.a[$idx] = v1.a[$idx] + v2.a[$idx] )
  end

  loop2 = :()
  for idx = l:-1:2
    loop2 = :($loop2; @inbounds (res.a[$idx] <= v1.a[$idx]) && (res.a[$idx - 1] += 1))
  end

  quote
    $loop1

    $loop2

    @inbounds (res.a[1] < v1.a[1]) && (carry += 1)
    carry
  end
end

@generated function __carried_add_lahf{FSS}(carry::UInt64, res::I64Array{FSS}, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)

  loop1 = :()
  for idx = l:-1:1
    loop1 = :($loop1; @inbounds carry = ccall( (:carried_add_lahf, "./bin/libcarry.so"), UInt64, (UInt64, Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}),
      carry,
      pointer(res.a, $idx),
      pointer(v1.a, $idx),
      pointer(v2.a, $idx)))
  end

  loop1
end

@generated function __carried_add_jnc{FSS}(carry::UInt64, res::I64Array{FSS}, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)

  loop1 = :()
  for idx = l:-1:1
    loop1 = :($loop1; @inbounds carry = ccall( (:carried_add_jnc, "./bin/libcarry.so"), UInt64, (UInt64, Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}),
      carry,
      pointer(res.a, $idx),
      pointer(v1.a, $idx),
      pointer(v2.a, $idx)))
  end

  loop1
end

@generated function __carried_add_loop{FSS}(carry::UInt64, res::I64Array{FSS}, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)

  quote
    ccall((:carried_add_loop2, "./bin/libcarry.so"), UInt64, (UInt64, Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}, Int64),
    carry,
    pointer(res.a, $l),
    pointer(v1.a, $l),
    pointer(v2.a, $l),
    $l)
  end
end

@generated function __carried_add_asm_gen{FSS}(carry::UInt64, res::I64Array{FSS}, v1::I64Array{FSS}, v2::I64Array{FSS})
  l = __cell_length(FSS)
  fnname = string("carried_add_", FSS)

  quote
    ccall(($(fnname), "./bin/libcarry.so"), UInt64, (UInt64, Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}),
    carry,
    pointer(res.a, $l),
    pointer(v1.a, $l),
    pointer(v2.a, $l))
  end
end


const mFSS = 11

a = rand(I64Array{mFSS})
b = rand(I64Array{mFSS})

answer = __carried_add_dumb(zero(UInt64), a, b)[2]
answer != __carried_add_td(zero(UInt64), a, b)[2] && println("error, td")
answer != __carried_add_gn(zero(UInt64), a, b)[2] && println("error, gn")
answer != __carried_add_du(zero(UInt64), a, b)[2] && println("error, du")
answer != __carried_add_dupa(zero(UInt64), a, b)[2] && println("error, dupa")

res = I64Array{mFSS}(zeros(UInt64, __cell_length(mFSS)))
__carried_add_lahf(zero(UInt64), res, a, b)
answer != res.a && println("error, lahf")

res = I64Array{mFSS}(zeros(UInt64, __cell_length(mFSS)))
__carried_add_jnc(zero(UInt64), res, a, b)
answer != res.a && println("error, jnc")

res = I64Array{mFSS}(zeros(UInt64, __cell_length(mFSS)))
__carried_add_loop(zero(UInt64), res, a, b)
answer != res.a && println("error, loop")

res = I64Array{mFSS}(zeros(UInt64, __cell_length(mFSS)))
__carried_add_asm_gen(zero(UInt64), res, a, b)
answer != res.a && println("error, asmgen")

const count = 1000000
const alist = I64Array{mFSS}[rand(I64Array{mFSS}) for idx = 1:count]
const blist = I64Array{mFSS}[rand(I64Array{mFSS}) for idx = 1:count]

function testfn(f)
  z = zero(UInt64)
  for idx = 1:count
    (carry, r) = f(z, alist[idx], blist[idx])
  end
end

function testfncache(f)
  z = zero(UInt64)
  res = I64Array{mFSS}(zeros(UInt64,__cell_length(mFSS)))
  for idx = 1:count
    carry = f(z, res, alist[idx], blist[idx])
  end
end

const GLOBAL_RES = I64Array{mFSS}(zeros(UInt64,__cell_length(mFSS)))
function testfnglobal(f)
  z = zero(UInt64)
  for idx = 1:count
    carry = f(z, GLOBAL_RES, alist[idx], blist[idx])
  end
end

println("----")
println("warning:  results may suffer compiler penalty")
@time testfn(__carried_add_dumb)
@time testfn(__carried_add_td)
@time testfn(__carried_add_gn)
@time testfn(__carried_add_du)
@time testfn(__carried_add_dupa)
@time testfncache(__carried_add_res)
@time testfnglobal(__carried_add_res)
@time testfncache(__carried_add_res2)
@time testfnglobal(__carried_add_res2)
@time testfncache(__carried_add_lahf)
@time testfnglobal(__carried_add_lahf)
@time testfncache(__carried_add_jnc)
@time testfnglobal(__carried_add_jnc)
@time testfncache(__carried_add_loop)
@time testfnglobal(__carried_add_loop)
@time testfncache(__carried_add_asm_gen)
@time testfnglobal(__carried_add_asm_gen)

println("\n----")
println("post-JITted")
print("dumb carried add                    ")
@time testfn(__carried_add_dumb)
print("with semi-smart type dispatch       ")
@time testfn(__carried_add_td)
print("as a generated fn with unrolling    ")
@time testfn(__carried_add_gn)
print("doubly-unrolled generated funtion   ")
@time testfn(__carried_add_du)
print("doubly-unrolled, dumb preallocation ")
@time testfn(__carried_add_dupa)
println("\nsingle unroll function call preallocation")
print("local                               ")
@time testfncache(__carried_add_res)
print("global                              ")
@time testfnglobal(__carried_add_res)
println("\ndouble unroll function call preallocation")
print("local                               ")
@time testfncache(__carried_add_res2)
print("global                              ")
@time testfnglobal(__carried_add_res2)
println("\nusing unrolled assembly (lahf)")
print("local                               ")
@time testfnglobal(__carried_add_lahf)
print("global                              ")
@time testfnglobal(__carried_add_lahf)
println("\nusing unrolled assembly (jnc)")
print("local                               ")
@time testfnglobal(__carried_add_jnc)
print("global                              ")
@time testfnglobal(__carried_add_jnc)
println("\nusing c-looped assembly (lahf)")
print("local                               ")
@time testfnglobal(__carried_add_loop)
print("global                              ")
@time testfnglobal(__carried_add_loop)
println("\nusing python-unrolled assembly")
print("local                               ")
@time testfnglobal(__carried_add_asm_gen)
print("global                              ")
@time testfnglobal(__carried_add_asm_gen)
