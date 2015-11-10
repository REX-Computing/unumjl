
innerasm = """    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else."""

joinasm = """    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"
"""


def makecfn(i):
    celldev = (1 << (i - 6)) - 1
    print "ULL carried_add_%i(ULL carry, ULL *res, ULL *a1, ULL *a2){" % i
    print "  //cell array starts fast forwarded as passed by julia."
    print "  asm("

    for j in range(celldev):
        print "    //iteration %i:" % j
        print innerasm
        print joinasm
    print innerasm

    print '    :"=a" (carry)                                 //the only output is the carry.'
    print '    :"a" (carry), "b" (res), "c" (a1), "d" (a2)   //a consistently will contain the carry, b, c, d passed parameters'
    print "  );"
    print "  return carry;"
    print "}"

print("#include <stdio.h>")
print("#define ULL unsigned long long")
for i in range(7,12):
    makecfn(i)
