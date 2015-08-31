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
n_two = -one(Warlpiri)
nsome = warlpiri(0b11, top64,  zero64)
n_one = warlpiri(0b10, top64,  zero64)
n_few = warlpiri(0b11, zero64, zero64)
nnone = -zero(Warlpiri)
none_ = zero(Warlpiri)
pfew_ = warlpiri(0b1,  zero64, zero64)
pone_ = warlpiri(0b0,  top64,  zero64)
psome = warlpiri(0b1,  top64,  zero64)
ptwo_ = one(Warlpiri)
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
na_nm = Ubound(n_all, nmany)
na_nt = Ubound(n_all, n_two)
na_ns = Ubound(n_all, nsome)
na_no = Ubound(n_all, n_one)
na_nf = Ubound(n_all, n_few)
na_n_ = Ubound(n_all, none_)
na_pf = Ubound(n_all, pfew_)
na_po = Ubound(n_all, pone_)
na_ps = Ubound(n_all, psome)
na_pt = Ubound(n_all, ptwo_)
na_pm = Ubound(n_all, pmany)
na_pa = Ubound(n_all, pall_)

nm_nt = Ubound(nmany, n_two)
nm_ns = Ubound(nmany, nsome)
nm_no = Ubound(nmany, n_one)
nm_nf = Ubound(nmany, n_few)
nm_n_ = Ubound(nmany, none_)
nm_pf = Ubound(nmany, pfew_)
nm_po = Ubound(nmany, pone_)
nm_ps = Ubound(nmany, psome)
nm_pt = Ubound(nmany, ptwo_)
nm_pm = Ubound(nmany, pmany)
nm_pa = Ubound(nmany, pall_)

nt_ns = Ubound(n_two, nsome)
nt_no = Ubound(n_two, n_one)
nt_nf = Ubound(n_two, n_few)
nt_n_ = Ubound(n_two, none_)
nt_pf = Ubound(n_two, pfew_)
nt_po = Ubound(n_two, pone_)
nt_ps = Ubound(n_two, psome)
nt_pt = Ubound(n_two, ptwo_)
nt_pm = Ubound(n_two, pmany)
nt_pa = Ubound(n_two, pall_)

ns_no = Ubound(nsome, n_one)
ns_nf = Ubound(nsome, n_few)
ns_n_ = Ubound(nsome, none_)
ns_pf = Ubound(nsome, pfew_)
ns_po = Ubound(nsome, pone_)
ns_ps = Ubound(nsome, psome)
ns_pt = Ubound(nsome, ptwo_)
ns_pm = Ubound(nsome, pmany)
ns_pa = Ubound(nsome, pall_)

no_nf = Ubound(n_one, n_few)
no_n_ = Ubound(n_one, none_)
no_pf = Ubound(n_one, pfew_)
no_po = Ubound(n_one, pone_)
no_ps = Ubound(n_one, psome)
no_pt = Ubound(n_one, ptwo_)
no_pm = Ubound(n_one, pmany)
no_pa = Ubound(n_one, pall_)

nf_n_ = Ubound(n_few, none_)
nf_pf = Ubound(n_few, pfew_)
nf_po = Ubound(n_few, pone_)
nf_ps = Ubound(n_few, psome)
nf_pt = Ubound(n_few, ptwo_)
nf_pm = Ubound(n_few, pmany)
nf_pa = Ubound(n_few, pall_)

n__pf = Ubound(none_, pfew_)
n__po = Ubound(none_, pone_)
n__ps = Ubound(none_, psome)
n__pt = Ubound(none_, ptwo_)
n__pm = Ubound(none_, pmany)
n__pa = Ubound(none_, pall_)

pf_po = Ubound(pfew_, pone_)
pf_ps = Ubound(pfew_, psome)
pf_pt = Ubound(pfew_, ptwo_)
pf_pm = Ubound(pfew_, pmany)
pf_pa = Ubound(pfew_, pall_)

po_ps = Ubound(pone_, psome)
po_pt = Ubound(pone_, ptwo_)
po_pm = Ubound(pone_, pmany)
po_pa = Ubound(pone_, pall_)

ps_pt = Ubound(psome, ptwo_)
ps_pm = Ubound(psome, pmany)
ps_pa = Ubound(psome, pall_)

pt_pm = Ubound(ptwo_, pmany)
pt_pa = Ubound(ptwo_, pall_)

pm_pa = Ubound(pmany, pall_)

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
  println("$op $fails / 225 = $(fails/225)% failure!")
end

include("test-warlpiri-addition.jl")
