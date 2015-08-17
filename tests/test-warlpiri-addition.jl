#test-warlpiri-addition.jl

###############################################################################
##COMPLETE ADDITION TABLE

#column key
#none_ pfew_ pone_ psome ptwo_ pmany pall_ junk_ nnone n_few n_one nsome n_two nmany n_all
wadd = [
#none_ + line
 none_ pfew_ pone_ psome ptwo_ pmany pall_ junk_ none_ n_few n_one nsome n_two nmany n_all;
#pfew_ + line
 pfew_ pf_ps psome ps_pm pmany pmany pall_ junk_ pfew_ nf_pf n_few ns_nf nsome nm_ns n_all;
#pone_ + line
 pone_ psome ptwo_ pmany pmany pmany pall_ junk_ pone_ pfew_ none_ n_few n_one nm_ns n_all;
#psome + line
 psome ps_pm pmany pmany pmany pmany pall_ junk_ psome pf_ps pfew_ nf_pf n_few nm_nf n_all;
#ptwo_ + line
 ptwo_ pmany pmany pmany pmany pmany pall_ junk_ ptwo_ psome pone_ pfew_ none_ nm_nf n_all;
#pmany + line
 pmany pmany pmany pmany pmany pmany pall_ junk_ pmany ps_pm ps_pm pf_pm pf_pm nm_pm n_all;
#pall_ + line
 pall_ pall_ pall_ pall_ pall_ pall_ pall_ junk_ pall_ pall_ pall_ pall_ pall_ pall_ junk_;
#junk_ + line
 junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_;
#nnone + line
 none_ pfew_ pone_ psome ptwo_ pmany pall_ junk_ none_ n_few n_one nsome n_two nmany n_all;
#n_few + line
 n_few nf_pf pfew_ pf_ps psome ps_pm pall_ junk_ n_few ns_nf nsome nm_ns nmany nmany n_all;
#n_one + line
 n_one n_few none_ pfew_ pone_ ps_pm pall_ junk_ n_one nsome n_two nmany nmany nmany n_all;
#nsome + line
 nsome ns_nf n_few nf_pf pfew_ pf_pm pall_ junk_ nsome nm_ns nmany nmany nmany nmany n_all;
#n_two + line
 n_two nsome n_one n_few none_ pf_pm pall_ junk_ n_two nmany nmany nmany nmany nmany n_all;
#nmany + line
 nmany nm_ns nm_ns nm_nf nm_nf nm_pm pall_ junk_ nmany nmany nmany nmany nmany nmany n_all;
#n_all + line
 n_all n_all n_all n_all n_all n_all junk_ junk_ n_all n_all n_all n_all n_all n_all n_all
]

testop(+, wadd)
