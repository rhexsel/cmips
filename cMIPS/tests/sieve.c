/* Sieve of Eratostenes *
/* Counts number of primes smaller than MAX */

#include "cMIPS.h"

#ifndef cMIPS
  #include <stdio.h>
#endif

#define MAX   100

int p[MAX] = {0};

void main() {

  int i, k, iter;
  int num;
#ifdef cMIPS
  int *IO = (int *)x_IO_BASE_ADDR;
#endif

  for (i = 0; i < MAX; i++)
    p[i] = TRUE;
  i = 2;

  while (i*i <= MAX) {
    if (p[i] == TRUE) {
      k = i + i;
      while (k < MAX) {
	p[k] = FALSE;
	k += i;
      }
    }
    i++;
  }
  num = 0;

  for (i = 1; i < MAX; i++) {
    if (p[i] == TRUE) {
      ++num;
#ifdef cMIPS
      *IO = i;
#else                      // 1 2 3 5 7 11 13 17 19 23 29 31
      printf("%08x\n",i);  // 00000001 00000002 00000003 00000005 00000007 0000000b 0000000d 00000011 00000013 00000017 0000001d 0000001f
#endif
    }
  }
#ifdef cMIPS
      *IO = num;
      IO++;
#endif

}


