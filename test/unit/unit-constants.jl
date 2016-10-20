#unit-constants.jl
#testing each of the unum constant generators in four unum environments:
# Unum{0,0}, Unum{1,1}, Unum{4,6}, Unum{4,8}

#it's best to do this with a macro
macro uctest(T, f, ex, fr, fl, es, fs)
  creationstmt = :($f($T))

  arraytest = T.args[3] > 6 ? (:(x.fraction.a == $fr)) : (:(x.fraction == $fr))
  quote
    x = $creationstmt

    @test x.fsize == $fs
    @test x.esize == $es
    @test x.flags == $fl
    @test $arraytest
    @test x.exponent == $ex
  end
end

nan(T) = T(NaN)
inf(T) = Unums.inf(T)

@uctest Unum{0,0} zero z64 z64 z16 z16 z16
@uctest Unum{1,1} zero z64 z64 z16 z16 z16
@uctest Unum{4,6} zero z64 z64 z16 z16 z16
@uctest Unum{4,8} zero z64 [z64, z64, z64, z64] z16 z16 z16

@uctest Unum{0,0} one z64 t64 z16 z16 z16
@uctest Unum{1,1} one o64 z64 z16 o16 z16
@uctest Unum{4,6} one o64 z64 z16 o16 z16
@uctest Unum{4,8} one o64 [z64, z64, z64, z64] z16 o16 z16
@uctest Unum{0,8} one z64 [t64, z64, z64, z64] z16 z16 z16

@uctest Unum{4,6} neg_one o64 z64 0x0002 o16 z16

@uctest Unum{0,0} nan o64 t64                                     0x0001 z16 z16
@uctest Unum{1,1} nan 0x0000_0000_0000_0003 0xC000_0000_0000_0000 0x0001 0x0001 0x0001
@uctest Unum{4,6} nan 0x0000_0000_0000_FFFF 0xFFFF_FFFF_FFFF_FFFF 0x0001 0x000F 0x003F
@uctest Unum{4,8} nan 0x0000_0000_0000_FFFF [f64, f64, f64, f64]  0x0001 0x000F 0x00FF

@uctest Unum{0,0} inf o64 t64                                     0x0000 z16 z16
@uctest Unum{1,1} inf 0x0000_0000_0000_0003 0xC000_0000_0000_0000 0x0000 0x0001 0x0001
@uctest Unum{4,6} inf 0x0000_0000_0000_FFFF 0xFFFF_FFFF_FFFF_FFFF 0x0000 0x000F 0x003F
@uctest Unum{4,8} inf 0x0000_0000_0000_FFFF [f64, f64, f64, f64]  0x0000 0x000F 0x00FF

@uctest Unum{0,0} neg_inf o64 t64                                     0x0002 z16 z16
@uctest Unum{1,1} neg_inf 0x0000_0000_0000_0003 0xC000_0000_0000_0000 0x0002 0x0001 0x0001
@uctest Unum{4,6} neg_inf 0x0000_0000_0000_FFFF 0xFFFF_FFFF_FFFF_FFFF 0x0002 0x000F 0x003F
@uctest Unum{4,8} neg_inf 0x0000_0000_0000_FFFF [f64, f64, f64, f64]  0x0002 0x000F 0x00FF

@uctest Unum{0,0} mmr 0x0000_0000_0000_0001 0x0000_0000_0000_0000                  0x0001    z16    z16
@uctest Unum{1,1} mmr 0x0000_0000_0000_0003 0x8000_0000_0000_0000                  0x0001 0x0001 0x0001
@uctest Unum{4,6} mmr 0x0000_0000_0000_FFFF 0xFFFF_FFFF_FFFF_FFFE                  0x0001 0x000F 0x003F
@uctest Unum{4,8} mmr 0x0000_0000_0000_FFFF [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0001 0x000F 0x00FF

@uctest Unum{0,0} neg_mmr 0x0000_0000_0000_0001 0x0000_0000_0000_0000                  0x0003    z16    z16
@uctest Unum{1,1} neg_mmr 0x0000_0000_0000_0003 0x8000_0000_0000_0000                  0x0003 0x0001 0x0001
@uctest Unum{4,6} neg_mmr 0x0000_0000_0000_FFFF 0xFFFF_FFFF_FFFF_FFFE                  0x0003 0x000F 0x003F
@uctest Unum{4,8} neg_mmr 0x0000_0000_0000_FFFF [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0003 0x000F 0x00FF

@uctest Unum{0,0} big_exact 0x0000_0000_0000_0001 0x0000_0000_0000_0000                  0x0000    z16    z16
@uctest Unum{1,1} big_exact 0x0000_0000_0000_0003 0x8000_0000_0000_0000                  0x0000 0x0001 0x0001
@uctest Unum{4,6} big_exact 0x0000_0000_0000_FFFF 0xFFFF_FFFF_FFFF_FFFE                  0x0000 0x000F 0x003F
@uctest Unum{4,8} big_exact 0x0000_0000_0000_FFFF [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0000 0x000F 0x00FF

@uctest Unum{0,0} neg_big_exact 0x0000_0000_0000_0001 0x0000_0000_0000_0000                  0x0002    z16    z16
@uctest Unum{1,1} neg_big_exact 0x0000_0000_0000_0003 0x8000_0000_0000_0000                  0x0002 0x0001 0x0001
@uctest Unum{4,6} neg_big_exact 0x0000_0000_0000_FFFF 0xFFFF_FFFF_FFFF_FFFE                  0x0002 0x000F 0x003F
@uctest Unum{4,8} neg_big_exact 0x0000_0000_0000_FFFF [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0002 0x000F 0x00FF

@uctest Unum{0,0} sss z64 z64                   0x0001    z16    z16
@uctest Unum{1,1} sss z64 z64                   0x0001 0x0001 0x0001
@uctest Unum{4,6} sss z64 z64                   0x0001 0x000F 0x003F
@uctest Unum{4,8} sss z64 [z64, z64, z64, z64]  0x0001 0x000F 0x00FF

@uctest Unum{0,0} neg_sss z64 z64                    0x0003    z16    z16
@uctest Unum{1,1} neg_sss z64 z64                    0x0003 0x0001 0x0001
@uctest Unum{4,6} neg_sss z64 z64                    0x0003 0x000F 0x003F
@uctest Unum{4,8} neg_sss z64 [z64, z64, z64, z64]   0x0003 0x000F 0x00FF

@uctest Unum{0,0} small_exact z64 t64                   0x0000    z16    z16
@uctest Unum{1,1} small_exact z64 0x4000_0000_0000_0000 0x0000 0x0001 0x0001
@uctest Unum{4,6} small_exact z64 o64                   0x0000 0x000F 0x003F
@uctest Unum{4,8} small_exact z64 [z64, z64, z64, o64]  0x0000 0x000F 0x00FF

@uctest Unum{0,0} neg_small_exact z64 t64                   0x0002    z16    z16
@uctest Unum{1,1} neg_small_exact z64 0x4000_0000_0000_0000 0x0002 0x0001 0x0001
@uctest Unum{4,6} neg_small_exact z64 o64                   0x0002 0x000F 0x003F
@uctest Unum{4,8} neg_small_exact z64 [z64, z64, z64, o64]  0x0002 0x000F 0x00FF

#this doesn't seem to always work.
@test is_mmr(mmr(Unum{0,0}))
@test is_mmr(mmr(Unum{1,1}))
@test is_mmr(mmr(Unum{2,2}))
@test is_mmr(mmr(Unum{3,3}))
@test is_mmr(mmr(Unum{3,5}))
@test is_mmr(mmr(Unum{4,6}))
@test is_mmr(mmr(Unum{4,7}))
#turns out that the generation of the top_mask implicitly converted an UInt16 to
#Int64 by adding one, which has a different top_mask definition.
