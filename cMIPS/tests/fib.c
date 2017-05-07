/*
 * Copyright (c) 1999-2000 Tony Givargis.  Permission to copy is granted
 * provided that this header remains intact.  This software is provided
 * with no warranties.
 *
 * Version : 2.8
 */

/*---------------------------------------------------------------------------*/

#ifndef cMIPS
  #include <stdio.h>
  #define SEQ_SZ 100
#else
  #include "cMIPS.h"
  #define SEQ_SZ 10
#endif


/*---------------------------------------------------------------------------*/
void fib(unsigned int* buf, unsigned int n) {

  char i;

  buf[0] = 1;
  buf[1] = 1;
  for(i=2; i<n; i++) {
    buf[i] = buf[i-1] + buf[i-2];
  }
}
/*---------------------------------------------------------------------------*/
void myprint(unsigned int* buf, unsigned int n) {
  int i;

#ifdef cMIPS
  int *IO = (int *)x_IO_BASE_ADDR;
#endif

  for(i=0; i<n; i++) {
#ifdef cMIPS
    print(buf[i]);   // 0x001 001 002 003 005 008 00d 015 022 0x037 15.275ns
#else
    printf("%08x\n",buf[i]); // 0x001 001 002 003 005 008 00d 015 022 0x037
#endif
  }
}
/*---------------------------------------------------------------------------*/
int main() {

  unsigned int buf[SEQ_SZ];

  fib(buf, SEQ_SZ);
  myprint(buf, SEQ_SZ);
  return(1);
}
/*---------------------------------------------------------------------------*/
