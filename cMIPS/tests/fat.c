#include "cMIPS.h"

#ifndef cMIPS
  #include <stdio.h>
#endif

#ifdef cMIPS
extern void exit(int);
extern void print(int);
extern int readInt(int *);
extern void writeInt(int);
#endif

int myprint(int n, int f) {
  int i;
#ifdef cMIPS
  print(n);
  print(f);
#else
  printf("%08x:\n%08x:",n,f);
#endif
  return(n+f);
}

int fat(int n) {
   if (n==0) 
     return 1;
   else
     return (n * fat(n-1));
}

int fat2(int n) {
   int i; 
   for (i=(n-1); i>0; i--)
     n = n*i;
   return n;
}

int main() {
  int ret;

  //ret = myprint(3,fat2(3));
  //ret = myprint(3,fat(3));
  //ret = myprint(4,fat2(4));
  //ret = myprint(4,fat(4));
  //ret = myprint(8,fat(8));

  ret = myprint(7,fat2(7));  // 13b0
  ret = myprint(7,fat(7));   // 13b0

  ret = myprint(12,fat2(12));  //1c8cfc00
  ret = myprint(12,fat(12));

  return(ret);
}
