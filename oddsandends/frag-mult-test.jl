#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#frag-mult-test.jl
#test fragmented multiplication

function frag_mult(a::Array{UInt64,1}, b::Array{UInt64,1})
  #note that frag_mult fails for absurdly high length integer arrays.
  length(a) != length(b) && throw(ArgumentError("mismatched arrays"))

  #take these two UInt64 arrays and reinterpret them as UInt32 arrays
  a_32 = reinterpret(UInt32, a)
  b_32 = reinterpret(UInt32, b)

  scratchpad = zeros(UInt32, length(a) * 4)
  carries    = zeros(UInt32, length(a) * 4)

  for idx = 1:length(a_32)
    for jdx = 1:length(b_32)
      #multiply the two values.
      multres::UInt64 = a_32[idx] * b_32[jdx]
      #bin these into a high word and a lwo word
      multresbins = reinterpret(UInt32, [multres])
      #add the low word to the scratchpad
      scratchpad[idx + jdx - 1] += multresbins[1]
      #save the carry, if need be.
      (scratchpad[idx + jdx - 1] < multresbins[1]) && (carries[idx + jdx] += 1)
      #add the high word to the scratchpad
      scratchpad[idx + jdx] += multresbins[2]
      #save the carry, if need be.
      (scratchpad[idx + jdx] < multresbins[2]) && (carries[idx + jdx + 1] += 1)
    end
  end
  #go through and resolve the carries.
  for idx = 1:length(carries)
    scratchpad[idx] += carries[idx]
    (scratchpad[idx] < carries[idx]) && (carries[idx + 1] += 1)
  end
  reinterpret(UInt64, scratchpad)
end

function calculate(a::Array{UInt64,1})
  sum = big(0)
  for idx = 1:length(a)
    sum += big(a[idx]) << (64 * (idx - 1))
  end
  sum
end

function test_mults(cells::Integer)
  x = rand(UInt64, cells)
  y = rand(UInt64, cells)

  x_big = calculate(x)
  y_big = calculate(y)

  #calculate using fragment multiplication
  res_frag = calculate(frag_mult(x,y))
  res_big = x_big * y_big

  println(res_frag)
  println(res_big)
end

#test that fragment multiplication in general works.
test_mults(1)
test_mults(2)
test_mults(4)
test_mults(8)

#next up:  truncated fragment multiplication.
function trunc_frag_mult(a::Array{UInt64,1}, b::Array{UInt64,1})
  #note that frag_mult fails for absurdly high length integer arrays.
  length(a) != length(b) && throw(ArgumentError("mismatched arrays"))

  #take these two UInt64 arrays and reinterpret them as UInt32 arrays
  a_32 = reinterpret(UInt32, a)
  b_32 = reinterpret(UInt32, b)
  l = length(a_32)

  scratchpad = zeros(UInt32, l + 1)
  carries    = zeros(UInt32, l)

  #first indexsum is length(a_32)
  indexsum = l
  for (aidx = 1:(indexsum - 1))
    temp_res::UInt64 = a_32[aidx] * b_32[indexsum - aidx]
    temp_res_high::UInt32 = (temp_res >> 32)
    scratchpad[1] += temp_res_high
    (scratchpad[1] < temp_res_high) && (carries[1] += 1)
  end
  #now proceed with the rest of the additions.
  for aidx = 1:l
    for bidx = (l + 1 - aidx):l
      temp_res = a_32[aidx] * b_32[bidx]
      temp_res_bins = reinterpret(UInt32, [temp_res])
      temp_res_low::UInt32 = temp_res
      temp_res_high = (temp_res >> 32)

      scratchindex = aidx + bidx - l

      scratchpad[scratchindex] += temp_res_low
      (temp_res_low > scratchpad[scratchindex]) && (carries[scratchindex] += 1)

      scratchpad[scratchindex + 1] += temp_res_high
      (temp_res_high > scratchpad[scratchindex + 1]) && (carries[scratchindex + 1] += 1)
    end
  end

  #go through and resolve the carries.
  for idx = 1:length(carries) - 1
    scratchpad[idx + 1] += carries[idx]
    (scratchpad[idx + 1] < carries[idx]) && (carries[idx + 1] += 1)
  end
  reinterpret(UInt64, scratchpad[2:end])
end


function test_truncs(cells::Integer)
  x = rand(UInt64, cells)
  y = rand(UInt64, cells)

  z = frag_mult(x, y)[cells + 1:2 *cells]
  w = trunc_frag_mult(x, y)

  println(z)
  println(w)
end

test_truncs(1)
test_truncs(2)
test_truncs(4)
test_truncs(8)
