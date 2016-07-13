#Copyright (c) 2015 Rex Computing and Isaac Yonemoto

#see LICENSE.txt

#this work was supported in part by DARPA Contract D15PC00135


#log-table.jl

#log table describing logarithmic fractions for all 64-bit fraction bits...  starting
#with 1.1b, 1.01b, 1.001b, 1.0001b etc.

const lt64 = [
0x5269e12f346e2c00,
0x2b803473f7ad1000,
0x1663f6fac9131600,
0x0b5d69bac77ec380,
0x05b9e5a170b48a80,
0x02dfca16dde10a20,
0x01709c46d7aac770,
0x00b87c1ff853ab28,
0x005c4994dd0fd150,
0x002e27ac5ef2af86,
0x0017148ec2a1bfc9,
0x000b8a7588fd29b1,
0x0005c5464ec5f4d7,
0x0002e2a60a005c95,
0x00017153bda8f822,
0x0000b8aa0cfedcb1,
0x00005c55120a0c45,
0x00002e2a8be7ae56,
0x0000171546ac814f,
0x00000b8aa3846b33,
0x000005c551cdc03d,
0x000002e2a8e9c2c7,
0x0000017154759a0d,
0x000000b8aa3afb31,
0x0000005c551d8923,
0x0000002e2a8ec774,
0x0000001715476472,
0x0000000b8aa3b267,
0x00000005c551d93f,
]
