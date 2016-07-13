#unum-test-warlpiri.jl

#unit tests based on warlpiri mathematics.
#not part of the main test suite.

include("../unum.jl")
using Unums
using Base.Test

#some useful unsigned int constants
one16 = one(Uint16)
one64 = one(Uint64)
zero16 = zero(Uint16)
zero64 = zero(Uint64)
top64 = 0x8000_0000_0000_0000 #our representation for the fraction part is left-shifted.

#create the warlpiri type.  This is a 0/0 unum.
Warlpiri = Unum{0,0}
#an external constructor will make things a bit easier, sadly we have to lower case this.
warlpiri(flags::Integer, frac::Uint64, exp::Uint64) = Warlpiri(zero16, zero16, uint16(flags), frac, exp)
#first let's make sure that the Warlpiri unums take up four bits
@test 4 == maxubits(Warlpiri)

#create english words for each of the warlpiri unums
stop_ = nan!(Warlpiri)
n_all = neg_inf(Warlpiri)
nmany = warlpiri(0b11, zero64, one64)
n_two = warlpiri(0b10, zero64, one64)
nsome = warlpiri(0b11, top64,  zero64)
n_one = -one(Warlpiri)
n_few = warlpiri(0b11, zero64, zero64)
nnone = -zero(Warlpiri)
none_ = zero(Warlpiri)
pfew_ = warlpiri(0b1,  zero64, zero64)
pone_ = one(Warlpiri)
psome = warlpiri(0b1,  top64,  zero64)
ptwo_ = warlpiri(0b0,  zero64, one64)
pmany = warlpiri(0b1,  zero64, one64)
pall_ = pos_inf(Warlpiri)
junk_ = nan(Warlpiri)
#check the bits on all of the warpiri unums
@test "1111" == bits(stop_)
@test "1110" == bits(n_all)
@test "1101" == bits(nmany)
@test "1100" == bits(n_two)
@test "1011" == bits(nsome)
@test "1010" == bits(n_one)
@test "1001" == bits(n_few)
@test "1000" == bits(nnone)
@test "0000" == bits(none_)
@test "0001" == bits(pfew_)
@test "0010" == bits(pone_)
@test "0011" == bits(psome)
@test "0100" == bits(ptwo_)
@test "0101" == bits(pmany)
@test "0110" == bits(pall_)
@test "0111" == bits(junk_)

@test none_ == nnone #and also that negative zero equals zero.

#create the warlarray, simple ordered array of warlpiris, by bit representation, minus the stop_.
warlpiris = [none_, pfew_, pone_, psome, ptwo_, pmany, pall_, junk_, nnone, n_few, n_one, nsome, n_two, nmany, n_all]

#the complete set of warlpiri ubounds
println("----")
na_nm = ubound(n_all, nmany)
na_nt = ubound(n_all, n_two)
na_ns = ubound(n_all, nsome)
na_no = ubound(n_all, n_one)
na_nf = ubound(n_all, n_few)
na_n_ = ubound(n_all, none_)
na_pf = ubound(n_all, pfew_)
na_po = ubound(n_all, pone_)
na_ps = ubound(n_all, psome)
na_pt = ubound(n_all, ptwo_)
na_pm = ubound(n_all, pmany)
na_pa = ubound(n_all, pall_)

nm_nt = ubound(nmany, n_two)
nm_ns = ubound(nmany, nsome)
nm_no = ubound(nmany, n_one)
nm_nf = ubound(nmany, n_few)
nm_n_ = ubound(nmany, none_)
nm_pf = ubound(nmany, pfew_)
nm_po = ubound(nmany, pone_)
nm_ps = ubound(nmany, psome)
nm_pt = ubound(nmany, ptwo_)
nm_pm = ubound(nmany, pmany)
nm_pa = ubound(nmany, pall_)

nt_ns = ubound(n_two, nsome)
nt_no = ubound(n_two, n_one)
nt_nf = ubound(n_two, n_few)
nt_n_ = ubound(n_two, none_)
nt_pf = ubound(n_two, pfew_)
nt_po = ubound(n_two, pone_)
nt_ps = ubound(n_two, psome)
nt_pt = ubound(n_two, ptwo_)
nt_pm = ubound(n_two, pmany)
nt_pa = ubound(n_two, pall_)

ns_no = ubound(nsome, n_one)
ns_nf = ubound(nsome, n_few)
ns_n_ = ubound(nsome, none_)
ns_pf = ubound(nsome, pfew_)
ns_po = ubound(nsome, pone_)
ns_ps = ubound(nsome, psome)
ns_pt = ubound(nsome, ptwo_)
ns_pm = ubound(nsome, pmany)
ns_pa = ubound(nsome, pall_)

no_nf = ubound(n_one, n_few)
no_n_ = ubound(n_one, none_)
no_pf = ubound(n_one, pfew_)
no_po = ubound(n_one, pone_)
no_ps = ubound(n_one, psome)
no_pt = ubound(n_one, ptwo_)
no_pm = ubound(n_one, pmany)
no_pa = ubound(n_one, pall_)

nf_n_ = ubound(n_few, none_)
nf_pf = ubound(n_few, pfew_)
nf_po = ubound(n_few, pone_)
nf_ps = ubound(n_few, psome)
nf_pt = ubound(n_few, ptwo_)
nf_pm = ubound(n_few, pmany)
nf_pa = ubound(n_few, pall_)

n__pf = ubound(none_, pfew_)
n__po = ubound(none_, pone_)
n__ps = ubound(none_, psome)
n__pt = ubound(none_, ptwo_)
n__pm = ubound(none_, pmany)
n__pa = ubound(none_, pall_)

pf_po = ubound(pfew_, pone_)
pf_ps = ubound(pfew_, psome)
pf_pt = ubound(pfew_, ptwo_)
pf_pm = ubound(pfew_, pmany)
pf_pa = ubound(pfew_, pall_)

po_ps = ubound(pone_, psome)
po_pt = ubound(pone_, ptwo_)
po_pm = ubound(pone_, pmany)
po_pa = ubound(pone_, pall_)

ps_pt = ubound(psome, ptwo_)
ps_pm = ubound(psome, pmany)
ps_pa = ubound(psome, pall_)

pt_pm = ubound(ptwo_, pmany)
pt_pa = ubound(ptwo_, pall_)

pm_pa = ubound(pmany, pall_)

println("one:", bits(pone_))
println("one x one:", bits(Unums.__mult_exact(pone_, pone_)))
#println(bits(pfew_ * pfew_))

exit()

#and a general purpose function for testing an operation,
function testop(op, expected)
  #now create a matrix of warlpiris
  amatrix = warlpiris
  for i = 1:14
    amatrix = [amatrix warlpiris]
  end
  #then transpose it.
  bmatrix = amatrix'
  fails = 0

  for i=1:15
    for j=1:15
      try
        res = op(warlpiris[i], warlpiris[j])

#=        println("====")
        println(bits(res))
        println(bits(expected[i,j]))
        println(typeof(expected[i,j]))
        println(isequal(res, expected[i,j]))=#

        if !isequal(res, expected[i, j])
          println("$i, $j: $(bits(warlpiris[i])) $op $(bits(warlpiris[j])) failed as $(bits(res)); should be $(bits(expected[i,j]))")
          fails += 1
        end
      catch
        println("$i, $j: $(bits(warlpiris[i])) $op $(bits(warlpiris[j])) failed due to thrown error:")
        bt = catch_backtrace()
        s = sprint(io->Base.show_backtrace(io, bt))
        println("$s")
        fails += 1
      end
    end
  end
  println("$op $fails / 225 = $(100 * fails/225)% failure!")
end

include("test-warlpiri-addition.jl")
include("test-warlpiri-multiplication.jl")
