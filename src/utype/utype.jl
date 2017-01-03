#utype is a boxing value that boxes in the unum types.  This is useful for high-level
#operations on unums, until we complete building gnums.

type Utype{ESS,FSS} <: AbstractFloat
  val::Union{UnumSmall{ESS,FSS}, UnumLarge{ESS,FSS}, UboundSmall{ESS,FSS}, UboundLarge{ESS,FSS}}
end

typealias IEEEFloat Union{Float16, Float32, Float64}

#convert and constructor types
(::Utype{ESS,FSS}){ESS,FSS}(x::IEEEFloat)                   = (FSS < 7) ? Utype{ESS,FSS}(UnumSmall{ESS,FSS}(x)) : Utype{ESS,FSS}(UnumLarge{ESS,FSS}(x))
Base.convert{ESS,FSS}(::Type{Utype{ESS,FSS}}, x::IEEEFloat) = (FSS < 7) ? Utype{ESS,FSS}(UnumSmall{ESS,FSS}(x)) : Utype{ESS,FSS}(UnumLarge{ESS,FSS}(x))
(::Utype{ESS,FSS}){ESS,FSS}(x::Integer)                     = (FSS < 7) ? Utype{ESS,FSS}(UnumSmall{ESS,FSS}(x)) : Utype{ESS,FSS}(UnumLarge{ESS,FSS}(x))
Base.convert{ESS,FSS}(::Type{Utype{ESS,FSS}}, x::Integer)   = (FSS < 7) ? Utype{ESS,FSS}(UnumSmall{ESS,FSS}(x)) : Utype{ESS,FSS}(UnumLarge{ESS,FSS}(x))

#specifically wrapping Unum and Ubound types
Base.convert{ESS,FSS}(::Type{Utype{ESS,FSS}}, x::Unum{ESS,FSS})   = Utype{ESS,FSS}(x)
Base.convert{ESS,FSS}(::Type{Utype{ESS,FSS}}, x::Ubound{ESS,FSS}) = Utype{ESS,FSS}(x)
#specifically calling the naked Utype constructor for existing thingamabobs.
Base.convert{ESS,FSS}(::Type{Utype}, x::Unum{ESS,FSS})   = Utype{ESS,FSS}(x)
Base.convert{ESS,FSS}(::Type{Utype}, x::Ubound{ESS,FSS}) = Utype{ESS,FSS}(x)
(::Utype){ESS,FSS}(x::Unum{ESS,FSS})   = Utype{ESS,FSS}(x)
(::Utype){ESS,FSS}(x::Ubound{ESS,FSS}) = Utype{ESS,FSS}(x)

#setting promotions.
promote_rule{ESS,FSS, T <: Integer}(::Type{Utype{ESS,FSS}}, ::Type{T})      = Utype{ESS,FSS}
promote_rule{ESS,FSS, T <: IEEEFloat}(::Type{Utype{ESS,FSS}}, ::Type{T})    = Utype{ESS,FSS}
promote_rule{ESS,FSS}(::Type{Utype{ESS,FSS}}, ::Type{UnumSmall{ESS,FSS}})   = Utype{ESS,FSS}
promote_rule{ESS,FSS}(::Type{Utype{ESS,FSS}}, ::Type{UnumLarge{ESS,FSS}})   = Utype{ESS,FSS}
promote_rule{ESS,FSS}(::Type{Utype{ESS,FSS}}, ::Type{UboundSmall{ESS,FSS}}) = Utype{ESS,FSS}
promote_rule{ESS,FSS}(::Type{Utype{ESS,FSS}}, ::Type{UboundLarge{ESS,FSS}}) = Utype{ESS,FSS}

#aliasing operations
+{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = Utype{ESS,FSS}(lhs.val + rhs.val)
-{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = Utype{ESS,FSS}(lhs.val - rhs.val)
*{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = Utype{ESS,FSS}(lhs.val * rhs.val)
/{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = Utype{ESS,FSS}(lhs.val / rhs.val)

<{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = (lhs.val < rhs.val)
>{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = (lhs.val > rhs.val)
<={ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = (lhs.val <= rhs.val)
>={ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = (lhs.val >= rhs.val)
=={ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS}) = (lhs.val == rhs.val)

Base.isequal{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Utype{ESS,FSS})  = isequal(lhs.val, rhs.val)
Base.isequal{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Unum{ESS,FSS})   = isequal(lhs.val, rhs)
Base.isequal{ESS,FSS}(lhs::Utype{ESS,FSS}, rhs::Ubound{ESS,FSS}) = isequal(lhs.val, rhs)
Base.isequal{ESS,FSS}(lhs::Unum{ESS,FSS}, rhs::Utype{ESS,FSS})   = isequal(lhs, rhs.val)
Base.isequal{ESS,FSS}(lhs::Ubound{ESS,FSS}, rhs::Utype{ESS,FSS}) = isequal(lhs, rhs.val)

#other basics
Base.one{ESS,FSS}(::Utype{ESS,FSS})        = Utype{ESS,FSS}(one(Unum{ESS,FSS}))
Base.one{ESS,FSS}(::Type{Utype{ESS,FSS}})  = Utype{ESS,FSS}(one(Unum{ESS,FSS}))
Base.zero{ESS,FSS}(::Utype{ESS,FSS})       = Utype{ESS,FSS}(zero(Unum{ESS,FSS}))
Base.zero{ESS,FSS}(::Type{Utype{ESS,FSS}}) = Utype{ESS,FSS}(zero(Unum{ESS,FSS}))

describe{ESS,FSS}(x::Utype{ESS,FSS}) = describe(x.val)

Base.show{ESS,FSS}(io::IO, T::Type{Utype{ESS,FSS}}) = print(io, "Utype")

export Utype
