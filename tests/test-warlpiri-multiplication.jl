#test-warlpiri-addition.jl

###############################################################################
##COMPLETE ADDITION TABLE

#column key
#none_ pfew_ pone_ psome ptwo_ pmany pall_ junk_ nnone n_few n_one nsome n_two nmany n_all
wmult = Utype[
#none_ * line
 none_ none_ none_ none_ none_ none_ junk_ junk_ none_ none_ none_ none_ none_ none_ junk_;
#pfew_ * line
 none_ pfew_ pfew_ pf_ps pf_ps pf_pm pall_ junk_ none_ n_few n_few ns_nf ns_nf nm_nf n_all;
#pone_ * line
 none_ pfew_ pone_ psome ptwo_ pmany pall_ junk_ none_ n_few n_one nsome n_two nmany n_all;
#psome * line
 none_ pf_ps psome ps_pm pmany pmany pall_ junk_ none_ ns_nf nsome nm_ns nmany nmany n_all;
#ptwo_ * line
 none_ pf_ps ptwo_ pmany pmany pmany pall_ junk_ none_ ns_nf n_two nmany nmany nmany n_all;
#pmany * line
 none_ pf_pm pmany pmany pmany pmany pall_ junk_ none_ nm_nf nmany nmany nmany nmany n_all;
#pall_ * line
 junk_ pall_ pall_ pall_ pall_ pall_ pall_ junk_ junk_ n_all n_all n_all n_all n_all n_all;
#junk_ * line
 junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_ junk_;
#nnone * line
 none_ none_ none_ none_ none_ none_ junk_ junk_ none_ none_ none_ none_ none_ none_ junk_;
#n_few * line
 none_ n_few n_few ns_nf ns_nf nm_nf n_all junk_ none_ pfew_ pfew_ pf_ps pf_ps pf_pm pall_;
#n_one * line
 none_ n_few n_one nsome n_two nmany n_all junk_ none_ pfew_ pone_ psome ptwo_ pmany pall_;
#nsome * line
 none_ ns_nf nsome nm_ns nmany nmany n_all junk_ none_ pf_ps psome ps_pm pmany pmany pall_;
#n_two * line
 none_ ns_nf n_two nmany nmany nmany n_all junk_ none_ pf_ps ptwo_ pmany pmany pmany pall_;
#nmany * line
 none_ nm_nf nmany nmany nmany nmany n_all junk_ none_ pf_pm pmany pmany pmany pmany pall_;
#n_all * line
 junk_ n_all n_all n_all n_all n_all n_all junk_ junk_ pall_ pall_ pall_ pall_ pall_ pall_
]
testop(*, wmult)
