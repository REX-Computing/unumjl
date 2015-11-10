
/* Copyright (c) 2015 Rex Computing and Isaac Yonemoto"
   see LICENSE.txt
   this work was supported in part by DARPA Contract D15PC00135*/

#include <stdio.h>
#define ULL unsigned long long

ULL carried_add_7(ULL carry, ULL *res, ULL *a1, ULL *a2){
  //cell array starts fast forwarded as passed by julia.
  asm(
    //iteration 0:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    :"=a" (carry)                                 //the only output is the carry.
    :"a" (carry), "b" (res), "c" (a1), "d" (a2)   //a consistently will contain the carry, b, c, d passed parameters
  );
  return carry;
}
ULL carried_add_8(ULL carry, ULL *res, ULL *a1, ULL *a2){
  //cell array starts fast forwarded as passed by julia.
  asm(
    //iteration 0:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 1:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 2:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    :"=a" (carry)                                 //the only output is the carry.
    :"a" (carry), "b" (res), "c" (a1), "d" (a2)   //a consistently will contain the carry, b, c, d passed parameters
  );
  return carry;
}
ULL carried_add_9(ULL carry, ULL *res, ULL *a1, ULL *a2){
  //cell array starts fast forwarded as passed by julia.
  asm(
    //iteration 0:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 1:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 2:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 3:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 4:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 5:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 6:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    :"=a" (carry)                                 //the only output is the carry.
    :"a" (carry), "b" (res), "c" (a1), "d" (a2)   //a consistently will contain the carry, b, c, d passed parameters
  );
  return carry;
}
ULL carried_add_10(ULL carry, ULL *res, ULL *a1, ULL *a2){
  //cell array starts fast forwarded as passed by julia.
  asm(
    //iteration 0:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 1:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 2:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 3:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 4:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 5:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 6:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 7:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 8:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 9:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 10:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 11:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 12:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 13:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 14:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    :"=a" (carry)                                 //the only output is the carry.
    :"a" (carry), "b" (res), "c" (a1), "d" (a2)   //a consistently will contain the carry, b, c, d passed parameters
  );
  return carry;
}
ULL carried_add_11(ULL carry, ULL *res, ULL *a1, ULL *a2){
  //cell array starts fast forwarded as passed by julia.
  asm(
    //iteration 0:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 1:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 2:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 3:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 4:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 5:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 6:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 7:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 8:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 9:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 10:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 11:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 12:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 13:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 14:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 15:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 16:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 17:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 18:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 19:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 20:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 21:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 22:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 23:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 24:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 25:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 26:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 27:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 28:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 29:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    //iteration 30:
    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    //decrement pointers
    "sub  $0x0008,  %%rbx;"
    "sub  $0x0008,  %%rcx;"
    "sub  $0x0008,  %%rdx;"

    "mov  %%rax,   %%r8;"           //use r8 as an accumulator register.
    "xor  %%rax,   %%rax;"         //clear the rax register
    "adc  (%%rcx), %%r8;"          //dereference rcx and add the value to r8.
    "lahf;"                        //dump the flags into the ax register
    "mov  %%ah,    %%al;"
    "adc  (%%rdx), %%r8;"          //dereference rdx and add the value to r8.
    "mov  %%r8,    (%%rbx);"       //move the accumulated r8 value to the spot pointed to by res.
    "lahf;"                        //dump the flags again
    "or   %%ah,    %%al;"          //combine both bits
    "and  $0x0001, %%rax;"         //or it to mask out everything else.
    :"=a" (carry)                                 //the only output is the carry.
    :"a" (carry), "b" (res), "c" (a1), "d" (a2)   //a consistently will contain the carry, b, c, d passed parameters
  );
  return carry;
}
