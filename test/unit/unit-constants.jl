#unit-constants.jl
#testing each of the unum constant generators in four unum environments:
# Unum{0,0}, Unum{1,1}, Unum{4,6}, Unum{4,8}

#it's best to do this with a macro
macro uctest(T, f, fs, es, fl, fr, ex)
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

@uctest Unum{0,0} zero z16 z16 z16 z64 z64
@uctest Unum{1,1} zero z16 z16 z16 z64 z64
@uctest Unum{4,6} zero z16 z16 z16 z64 z64
@uctest Unum{4,8} zero z16 z16 z16 [z64, z64, z64, z64] z64

@uctest Unum{0,0} one z16 z16 z16 t64 z64
@uctest Unum{1,1} one z16 o16 z16 z64 o64
@uctest Unum{4,6} one z16 o16 z16 z64 o64
@uctest Unum{4,8} one z16 o16 z16 [z64, z64, z64, z64] o64
@uctest Unum{0,8} one z16 z16 z16 [t64, z64, z64, z64] z64

@uctest Unum{4,6} neg_one z16 o16 0x0002 z64 o64

@uctest Unum{0,0} nan z16 z16 0x0001 t64 o64
@uctest Unum{1,1} nan 0x0001 0x0001 0x0001 0xC000_0000_0000_0000 0x0000_0000_0000_0003
@uctest Unum{4,6} nan 0x003F 0x000F 0x0001 0xFFFF_FFFF_FFFF_FFFF 0x0000_0000_0000_FFFF
@uctest Unum{4,8} nan 0x00FF 0x000F 0x0001 [f64, f64, f64, f64]  0x0000_0000_0000_FFFF

@uctest Unum{0,0} inf z16 z16 0x0000 t64 o64
@uctest Unum{1,1} inf 0x0001 0x0001 0x0000 0xC000_0000_0000_0000 0x0000_0000_0000_0003
@uctest Unum{4,6} inf 0x003F 0x000F 0x0000 0xFFFF_FFFF_FFFF_FFFF 0x0000_0000_0000_FFFF
@uctest Unum{4,8} inf 0x00FF 0x000F 0x0000 [f64, f64, f64, f64]  0x0000_0000_0000_FFFF

@uctest Unum{0,0} neg_inf z16 z16 0x0002 t64 o64
@uctest Unum{1,1} neg_inf 0x0001 0x0001 0x0002 0xC000_0000_0000_0000 0x0000_0000_0000_0003
@uctest Unum{4,6} neg_inf 0x003F 0x000F 0x0002 0xFFFF_FFFF_FFFF_FFFF 0x0000_0000_0000_FFFF
@uctest Unum{4,8} neg_inf 0x00FF 0x000F 0x0002 [f64, f64, f64, f64]  0x0000_0000_0000_FFFF

@uctest Unum{0,0} mmr    z16    z16 0x0001 0x0000_0000_0000_0000 0x0000_0000_0000_0001
@uctest Unum{1,1} mmr 0x0001 0x0001 0x0001 0x8000_0000_0000_0000 0x0000_0000_0000_0003
@uctest Unum{4,6} mmr 0x003F 0x000F 0x0001 0xFFFF_FFFF_FFFF_FFFE 0x0000_0000_0000_FFFF
@uctest Unum{4,8} mmr 0x00FF 0x000F 0x0001 [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0000_0000_0000_FFFF

@uctest Unum{0,0} neg_mmr    z16    z16 0x0003 0x0000_0000_0000_0000 0x0000_0000_0000_0001
@uctest Unum{1,1} neg_mmr 0x0001 0x0001 0x0003 0x8000_0000_0000_0000 0x0000_0000_0000_0003
@uctest Unum{4,6} neg_mmr 0x003F 0x000F 0x0003 0xFFFF_FFFF_FFFF_FFFE 0x0000_0000_0000_FFFF
@uctest Unum{4,8} neg_mmr 0x00FF 0x000F 0x0003 [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0000_0000_0000_FFFF

@uctest Unum{0,0} big_exact    z16    z16 0x0000 0x0000_0000_0000_0000 0x0000_0000_0000_0001
@uctest Unum{1,1} big_exact 0x0001 0x0001 0x0000 0x8000_0000_0000_0000 0x0000_0000_0000_0003
@uctest Unum{4,6} big_exact 0x003F 0x000F 0x0000 0xFFFF_FFFF_FFFF_FFFE 0x0000_0000_0000_FFFF
@uctest Unum{4,8} big_exact 0x00FF 0x000F 0x0000 [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0000_0000_0000_FFFF

@uctest Unum{0,0} neg_big_exact    z16    z16 0x0002 0x0000_0000_0000_0000 0x0000_0000_0000_0001
@uctest Unum{1,1} neg_big_exact 0x0001 0x0001 0x0002 0x8000_0000_0000_0000 0x0000_0000_0000_0003
@uctest Unum{4,6} neg_big_exact 0x003F 0x000F 0x0002 0xFFFF_FFFF_FFFF_FFFE 0x0000_0000_0000_FFFF
@uctest Unum{4,8} neg_big_exact 0x00FF 0x000F 0x0002 [f64, f64, f64, 0xFFFF_FFFF_FFFF_FFFE] 0x0000_0000_0000_FFFF

@uctest Unum{0,0} sss    z16    z16 0x0001 0x0000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{1,1} sss 0x0001 0x0001 0x0001 0x0000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{4,6} sss 0x003F 0x000F 0x0001 0x0000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{4,8} sss 0x00FF 0x000F 0x0001 [z64, z64, z64, z64]  0x0000_0000_0000_0000

@uctest Unum{0,0} neg_sss    z16    z16 0x0003 0x0000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{1,1} neg_sss 0x0001 0x0001 0x0003 0x0000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{4,6} neg_sss 0x003F 0x000F 0x0003 0x0000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{4,8} neg_sss 0x00FF 0x000F 0x0003 [z64, z64, z64, z64]  0x0000_0000_0000_0000

@uctest Unum{0,0} small_exact    z16    z16 0x0000 0x8000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{1,1} small_exact 0x0001 0x0001 0x0000 0x4000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{4,6} small_exact 0x003F 0x000F 0x0000 0x0000_0000_0000_0001 0x0000_0000_0000_0000
@uctest Unum{4,8} small_exact 0x00FF 0x000F 0x0000 [z64, z64, z64, o64]  0x0000_0000_0000_0000

@uctest Unum{0,0} neg_small_exact    z16    z16 0x0002 0x8000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{1,1} neg_small_exact 0x0001 0x0001 0x0002 0x4000_0000_0000_0000 0x0000_0000_0000_0000
@uctest Unum{4,6} neg_small_exact 0x003F 0x000F 0x0002 0x0000_0000_0000_0001 0x0000_0000_0000_0000
@uctest Unum{4,8} neg_small_exact 0x00FF 0x000F 0x0002 [z64, z64, z64, o64]  0x0000_0000_0000_0000
