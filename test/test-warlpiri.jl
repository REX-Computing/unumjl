#unum-test-warlpiri.jl

#unit tests based on warlpiri mathematics.
#not part of the main test suite.

#some useful unsigned int constants

#create the warlpiri type.  This is a 0/0 unum.
Warlpiri = Unum{0,0}
#an external constructor will make things a bit easier, sadly we have to lower case this.
warlpiri(flags::UInt16, frac::UInt64, exp::UInt64) = Warlpiri(z16, z16, flags, frac, exp)

#create english words for each of the warlpiri unums
stop_ = nan(Warlpiri, Unums.UNUM_SIGN_MASK)
n_all = neg_inf(Warlpiri)
nmany = warlpiri(0x0003, z64, o64)
n_two = warlpiri(0x0002, z64, o64)
nsome = warlpiri(0x0003, t64, z64)
n_one = Unums.additiveinverse!(one(Warlpiri))
n_few = warlpiri(0x0003, z64, z64)
nnone = Unums.additiveinverse!(zero(Warlpiri))
none_ = zero(Warlpiri)
pfew_ = warlpiri(0x0001,  z64, z64)
pone_ = one(Warlpiri)
psome = warlpiri(0x0001,  t64, z64)
ptwo_ = warlpiri(0x0000,  z64, o64)
pmany = warlpiri(0x0001,  z64, o64)
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
na_nm = Ubound{0,0}(n_all, nmany)
na_nt = Ubound{0,0}(n_all, n_two)
na_ns = Ubound{0,0}(n_all, nsome)
na_no = Ubound{0,0}(n_all, n_one)
na_nf = Ubound{0,0}(n_all, n_few)
na_n_ = Ubound{0,0}(n_all, none_)
na_pf = Ubound{0,0}(n_all, pfew_)
na_po = Ubound{0,0}(n_all, pone_)
na_ps = Ubound{0,0}(n_all, psome)
na_pt = Ubound{0,0}(n_all, ptwo_)
na_pm = Ubound{0,0}(n_all, pmany)
na_pa = Ubound{0,0}(n_all, pall_)

nm_nt = Ubound{0,0}(nmany, n_two)
nm_ns = Ubound{0,0}(nmany, nsome)
nm_no = Ubound{0,0}(nmany, n_one)
nm_nf = Ubound{0,0}(nmany, n_few)
nm_n_ = Ubound{0,0}(nmany, none_)
nm_pf = Ubound{0,0}(nmany, pfew_)
nm_po = Ubound{0,0}(nmany, pone_)
nm_ps = Ubound{0,0}(nmany, psome)
nm_pt = Ubound{0,0}(nmany, ptwo_)
nm_pm = Ubound{0,0}(nmany, pmany)
nm_pa = Ubound{0,0}(nmany, pall_)

nt_ns = Ubound{0,0}(n_two, nsome)
nt_no = Ubound{0,0}(n_two, n_one)
nt_nf = Ubound{0,0}(n_two, n_few)
nt_n_ = Ubound{0,0}(n_two, none_)
nt_pf = Ubound{0,0}(n_two, pfew_)
nt_po = Ubound{0,0}(n_two, pone_)
nt_ps = Ubound{0,0}(n_two, psome)
nt_pt = Ubound{0,0}(n_two, ptwo_)
nt_pm = Ubound{0,0}(n_two, pmany)
nt_pa = Ubound{0,0}(n_two, pall_)

ns_no = Ubound{0,0}(nsome, n_one)
ns_nf = Ubound{0,0}(nsome, n_few)
ns_n_ = Ubound{0,0}(nsome, none_)
ns_pf = Ubound{0,0}(nsome, pfew_)
ns_po = Ubound{0,0}(nsome, pone_)
ns_ps = Ubound{0,0}(nsome, psome)
ns_pt = Ubound{0,0}(nsome, ptwo_)
ns_pm = Ubound{0,0}(nsome, pmany)
ns_pa = Ubound{0,0}(nsome, pall_)

no_nf = Ubound{0,0}(n_one, n_few)
no_n_ = Ubound{0,0}(n_one, none_)
no_pf = Ubound{0,0}(n_one, pfew_)
no_po = Ubound{0,0}(n_one, pone_)
no_ps = Ubound{0,0}(n_one, psome)
no_pt = Ubound{0,0}(n_one, ptwo_)
no_pm = Ubound{0,0}(n_one, pmany)
no_pa = Ubound{0,0}(n_one, pall_)

nf_n_ = Ubound{0,0}(n_few, none_)
nf_pf = Ubound{0,0}(n_few, pfew_)
nf_po = Ubound{0,0}(n_few, pone_)
nf_ps = Ubound{0,0}(n_few, psome)
nf_pt = Ubound{0,0}(n_few, ptwo_)
nf_pm = Ubound{0,0}(n_few, pmany)
nf_pa = Ubound{0,0}(n_few, pall_)

n__pf = Ubound{0,0}(none_, pfew_)
n__po = Ubound{0,0}(none_, pone_)
n__ps = Ubound{0,0}(none_, psome)
n__pt = Ubound{0,0}(none_, ptwo_)
n__pm = Ubound{0,0}(none_, pmany)
n__pa = Ubound{0,0}(none_, pall_)

pf_po = Ubound{0,0}(pfew_, pone_)
pf_ps = Ubound{0,0}(pfew_, psome)
pf_pt = Ubound{0,0}(pfew_, ptwo_)
pf_pm = Ubound{0,0}(pfew_, pmany)
pf_pa = Ubound{0,0}(pfew_, pall_)

po_ps = Ubound{0,0}(pone_, psome)
po_pt = Ubound{0,0}(pone_, ptwo_)
po_pm = Ubound{0,0}(pone_, pmany)
po_pa = Ubound{0,0}(pone_, pall_)

ps_pt = Ubound{0,0}(psome, ptwo_)
ps_pm = Ubound{0,0}(psome, pmany)
ps_pa = Ubound{0,0}(psome, pall_)

pt_pm = Ubound{0,0}(ptwo_, pmany)
pt_pa = Ubound{0,0}(ptwo_, pall_)

pm_pa = Ubound{0,0}(pmany, pall_)

#and a general purpose function for testing an operation,
function testop(op, expected)
  #now create a matrix of warlpiris
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
  println("$op $fails / 225 = $(100 * fails/225)% failure!")
end

include("./warlpiri/test-warlpiri-ordering.jl")
include("./warlpiri/test-warlpiri-addition.jl")
include("./warlpiri/test-warlpiri-multiplication.jl")
#=
include("test-warlpiri-division.jl")
=#
