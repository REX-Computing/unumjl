#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#gravity.jl

#2-dimensional gravity simulation to show the limits of floating point arithmetic.

type Body{T <: Real}
  pos::Vector{T}
  vel::Vector{T}
  mass::T
end

#just use units where the gravitational constant is 1.

sqr(x::Float32) = x^2
sqr(x::Float64) = x^2
sqr(x::BigFloat) = x^2

#subjects object a to the gravitational influence of object b.
#note that only a is changed.

#gravitational constant.
Gc_std = 6.674e-11 #N m^2 kg^-2 = m^3 s^-2 kg^-1
#rescale distance to 10^9 m (1 AU = ~150 units)
# = 6.674e-38 d^3 s^-2 kg^-1
#rescale time to hours
# = 8.650e-31 d^3 h^-2 kg^-1
#rescale mass to 10^24 kg (1Me = 6.0 Mu)
# = 8.650e-7 d^3 h^-2 Mu-1
Gc = 8.650e-7

function gravity!{T}(a::Body{T}, b::Body{T})
  #calculate the displacement vector:
  disp = b.pos - a.pos
  sdisp = map(sqrt, sum(map(sqr, disp)))
  a.vel += Gc * disp * (b.mass / (sdisp) ^ 3)
  nothing
end

#executes the passage of time on object a.
function time!{T}(a::Body{T})
  a.pos += a.vel
  nothing
end

function adjust_system!{T}(a::Vector{Body{T}})
  total_mass = mapreduce((b) -> b.mass, + , zero(T), a)
  #number one, set the center of mass to be at the origin.
  delta_p::Vector{T} = mapreduce((b) -> b.pos * b.mass, +, zero(T), a) / total_mass
  map!((b)-> Body(b.pos - delta_p, b.vel, b.mass), a)
  #number two, set the frame of reference so that net momentum is zero.
  delta_v::Vector{T} = mapreduce((b) -> b.vel * b.mass, +, zero(T), a) / total_mass
  map!((b)-> Body(b.pos, b.vel - delta_v, b.mass), a)
  nothing
end

#applies gravity to a system s.
function apply_gravity!{T}(s::Array{Body{T}})
  l = length(s)
  for idx = 1:l
    for jdx = 1:l
      (idx != jdx) && gravity!(s[idx], s[jdx])
    end
  end
  nothing
end

function apply_time!{T}(s::Array{Body{T}})
  for idx = 1:length(s)
    time!(s[idx])
  end
end

#speed of earth:  ~ 150 d * 3.14 * 2 / 360 / 24

star = Body{Float64}([0.0,0.0], [0.0, 0.0], 1998000)
planet = Body{Float64}([0.0, -150.0], [0.11, 0.0], 6)

system = Body{Float64}[star, planet]
adjust_system!(system)


for idx=1:1000
  for idx = 1:100_000
    apply_gravity!(system)
    apply_time!(system)
  end
  println(system[2].pos[1], " " , system[2].pos[2], " r: ", sqrt(sum(map(sqr,system[2].pos))))
end
