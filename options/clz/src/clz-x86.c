//clz.c
long long int clz(long long int v){
  long long int r;
  asm("lzcnt %1, %0;"
     :"=r" (r)
     :"r" (v)
     );
  return r;
}
