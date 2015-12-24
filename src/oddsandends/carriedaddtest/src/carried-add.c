
/* Copyright (c) 2015 Rex Computing and Isaac Yonemoto"
   see LICENSE.txt
   this work was supported in part by DARPA Contract D15PC00135*/

#include <stdio.h>
#define ULL unsigned long long

ULL carried_add_lahf(ULL carry, ULL *res, ULL *a1, ULL *a2){
  asm("xor  %%rax,   %%rax;"         //clear the rax register
      "adc  (%%rbx),   %%rdx;"         //first add the first value into rdx.
      "lahf;"                        //dump the flags into the ax register
      "mov  %%ah,    %%al;"          //and then shift it so that it's aligned with bit one.
      "adc  (%%rcx),   %%rdx;"         //add the second value into the rdx register.
      "lahf;"                        //dump the flags again
      "or   %%ah,    %%al;"          //copy ah with al.
      "and  $0x0001, %%rax;"         //or it to mask out everything else.
  :"=a" (carry), "=d" (*res)         //output operands: a contains the carry, and d contains the result, but dereference it.
  :"b" (a1), "c" (a2), "d" (carry)   //input operands:
  );
  return carry;
};

ULL carried_add_jnc(ULL carry, ULL *res, ULL *a1, ULL *a2){
  asm("xor %%rax, %%rax;"          //clobber rax
      "adc %%rbx, %%rdx;"         //first add the first value into rdx.
      "jnc nofirst;"              //skip the next step we didn't carry
      "mov $1, %%rax;"             //set rax to 1
      "nofirst:"
      "adc %%rcx, %%rdx;"         //add the second value into the rdx register.
      "jnc nosecond;"             //skip the next step if we didn't carry
      "mov $1, %%rax;"             //increment rax again.
      "nosecond:"
    :"=a" (carry), "=d" (*res)          //output operands: a contains the carry, and d contains the result, but dereference it.
    :"b" (*a1), "c" (*a2), "d" (carry)   //input operands:
  );
  return carry;
};

ULL carried_add_loop2(ULL carry, ULL *res, ULL *a1, ULL *a2, long long ct){
  long long idx;
  for (idx = ct; idx > 0; idx--){
    asm("xor %%rax, %%rax;"         //clear the rax register
        "adc (%%rbx), %%rdx;"         //first add the first value into rdx.
        "lahf;"                     //dump the flags into the ax register
        "mov  %%ah,    %%al;"          //and then shift it so that it's aligned with bit one.
        "adc (%%rcx),   %%rdx;"         //add the second value into the rdx register.
        "lahf;"                        //dump the flags again
        "or   %%ah,    %%al;"          //copy ah with al.
        "and  $0x0001, %%rax;"         //or it to mask out everything else.
      :"=a" (carry), "=d" (*res)          //output operands: a contains the carry, and d contains the result, but dereference it.
      :"b" (a1), "c" (a2), "d" (carry)   //input operands:
    );
    a1--;
    a2--;
    res--;
  }
  return carry;
};

int main(){
  ULL carry = 0;
  ULL res = 0;
  ULL a1 = 0xFFFFFFFFFFFFFFFF;
  ULL a2 = 0x1;
  carry = carried_add_jnc(carry, &res, &a1, &a2);
  printf("%llX : %llX\n", carry, res);
  return 0;
}
