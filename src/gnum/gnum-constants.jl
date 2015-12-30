#gnum-constants.jl
#setting gnum values to unum constants.

function nan!{ESS,FSS}(x::Gnum{ESS,FSS})
  x.scratchpad.flags |= GNUM_NAN_MASK
end

@generated function inf!{ESS,FSS,side}(x::Gnum{ESS,FSS}, flags::UInt16, ::Type{Val{side}})
  :(clear_gflags!(x.$side); x.$side.flags = flags | GNUM_INF_MASK; nothing)
end
@generated function mmr!{ESS,FSS,side}(x::Gnum{ESS,FSS}, flags::UInt16, ::Type{Val{side}})
  :(clear_gflags!(x.$side); x.$side.flags = flags | GNUM_MMR_MASK; nothing)
end
@generated function sss!{ESS,FSS,side}(x::Gnum{ESS,FSS}, flags::UInt16, ::Type{Val{side}})
  :(clear_gflags!(x.$side); x.$side.flags = flags | GNUM_SSS_MASK; nothing)
end
@generated function zero!{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  :(clear_gflags!(x.$side); x.$side.flags = GNUM_ZERO_MASK; nothing)
end

#testing gnum values for unum constants
function is_nan{ESS,FSS}(x::Gnum{ESS,FSS})
  x.scratchpad.flags & GNUM_NAN_MASK != 0
end

is_g_inf{ESS,FSS}(x::Unum{ESS,FSS}) = x.flags & GNUM_INF_MASK != 0
@generated function is_inf{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
 :(is_g_inf(x.$side))
end

is_g_mmr{ESS,FSS}(x::Unum{ESS,FSS}) = x.flags & GNUM_MMR_MASK != 0
@generated function is_mmr{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  :(is_g_mmr(x.$side))
end

is_g_sss{ESS,FSS}(x::Unum{ESS,FSS}) = x.flags & GNUM_SSS_MASK != 0
@generated function is_sss{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  :(is_g_sss(x.$side))
end

is_g_zero{ESS,FSS}(x::Unum{ESS,FSS}) = x.flags & GNUM_ZERO_MASK != 0
@generated function is_zero{ESS,FSS,side}(x::Gnum{ESS,FSS}, ::Type{Val{side}})
  :(is_g_zero(x.$side))
end

@generated function force_from_flags!{ESS,FSS,side}(src::Gnum{ESS,FSS}, dest::Unum{ESS,FSS}, ::Type{Val{side}})
  quote
    (src.$side.flags & GNUM_INF_MASK != 0) && (inf!(dest, src.$side.flags & UNUM_SIGN_MASK); return true)
    (src.$side.flags & GNUM_MMR_MASK != 0) && (mmr!(dest, src.$side.flags & UNUM_SIGN_MASK); return true)
    (src.$side.flags & GNUM_SSS_MASK != 0) && (sss!(dest, src.$side.flags & UNUM_SIGN_MASK); return true)
    (src.$side.flags & GNUM_ZERO_MASK != 0) && (zero!(dest); return true)
    false
  end
end
