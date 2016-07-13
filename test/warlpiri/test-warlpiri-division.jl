#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#test-warlpiri-division.jl

###############################################################################
##COMPLETE DIVISION TABLE

#column key
#none_ pfew_ pone_ psome ptwo_ pmany pall_ junk_ nnone n_few n_one nsome n_two nmany n_all
wdiv = Utype[
#none_ / line
 junk_ none_ none_ none_ none_ none_ none_ junk_ junk_ none_ none_ none_ none_ none_ none_;
#pfew_ / line
 junk_ pf_pm pfew_ pfew_ pfew_ pfew_ none_ junk_ junk_ nm_nf n_few n_few n_few n_few none_;
#pone_ / line
 junk_ ps_pm pone_ pfew_ pfew_ pfew_ none_ junk_ junk_ nm_ns n_one n_few n_few n_few none_;
#psome / line
 junk_ ps_pm psome pf_ps pfew_ pfew_ none_ junk_ junk_ nm_ns nsome ns_nf n_few n_few none_;
#ptwo_ / line
 junk_ pmany ptwo_ psome pone_ pfew_ none_ junk_ junk_ nmany n_two nsome n_one n_few none_;
#pmany / line
 junk_ pmany pmany ps_pm ps_pm pf_pm none_ junk_ junk_ nmany nmany nm_ns nm_ns nm_nf none_;
#pall_ / line
 junk_ pall_ pall_ pall_ pall_ pall_ junk_ junk_ junk_ n_all n_all n_all n_all n_all junk_;
#junk_ / line
 junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_;
#nnone / line
 junk_ none_ none_ none_ none_ none_ none_ junk_ junk_ none_ none_ none_ none_ none_ none_;
#n_few / line
 junk_ nm_nf n_few n_few n_few n_few none_ junk_ junk_ pf_pm pfew_ pfew_ pfew_ pfew_ none_;
#n_one / line
 junk_ nm_ns n_one n_few n_few n_few none_ junk_ junk_ ps_pm pone_ pfew_ pfew_ pfew_ none_;
#nsome / line
 junk_ nm_ns nsome ns_nf n_few n_few none_ junk_ junk_ ps_pm psome pf_ps pfew_ pfew_ none_;
#n_two / line
 junk_ nmany n_two nsome n_one n_few none_ junk_ junk_ pmany ptwo_ psome pone_ pfew_ none_;
#nmany / line
 junk_ nmany nmany nm_ns nm_ns nm_nf none_ junk_ junk_ pmany pmany ps_pm ps_pm pf_pm none_;
#n_all / line
 junk_ n_all n_all n_all n_all n_all junk_ junk_ junk_ pall_ pall_ pall_ pall_ pall_ junk_
]
testop(/, wdiv)
