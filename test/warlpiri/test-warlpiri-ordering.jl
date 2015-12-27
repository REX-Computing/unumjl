#test-warlpiri-addition.jl

###############################################################################
##COMPLETE ORDER TABLE

#column key

#none_ pfew_ pone_ psome ptwo_ pmany pall_ junk_ nnone n_few n_one nsome n_two nmany n_all
wcmp = Bool[
#none_ > line
 false false false false false false false false false true  true  true  true  true  true;
#pfew_ > line
 true  false false false false false false false true  true  true  true  true  true  true;
#pone_ > line
 true  true  false false false false false false true  true  true  true  true  true  true;
#psome > line
 true  true  true  false false false false false true  true  true  true  true  true  true;
#ptwo_ > line
 true  true  true  true  false false false false true  true  true  true  true  true  true;
#pmany > line
 true  true  true  true  true  false false false true  true  true  true  true  true  true;
#pall_ > line
 true  true  true  true  true  true  false false true  true  true  true  true  true  true;
#junk_ > line
 false false false false false false false false false false false false false false false;
#nnone > line
 false false false false false false false false false true  true  true  true  true  true;
#n_few > line
 false false false false false false false false false false true  true  true  true  true;
#n_one > line
 false false false false false false false false false false false true  true  true  true;
#nsome > line
 false false false false false false false false false false false false true  true  true;
#n_two > line
 false false false false false false false false false false false false false true  true;
#nmany > line
 false false false false false false false false false false false false false false true;
#n_all > line
 false false false false false false false false false false false false false false false;
]


for i=1:15
  for j=1:15
    @test (warlpiris[i] > warlpiris[j]) == wcmp[i,j]
  end
end
