/*
 * Copyright (c) 1999-2000 Tony Givargis.  Permission to copy is granted
 * provided that this header remains intact.  This software is provided
 * with no warranties.
 *
 * Version : 2.8
 */

/*---------------------------------------------------------------------------*/
#ifdef cMIPS

#include "cMIPS.h"

extern void exit(int);
extern void print(int);
extern int  readInt(int *);
extern void writeInt(int);

#else

  #include <stdio.h>
//#include <reg51.h>

#endif
/*---------------------------------------------------------------------------*/

void main() {

  unsigned x = 134;
  unsigned y = 1;
  unsigned q, r, p, i;
  
  for(i=0; i<12; i++) {
    q = x / y;
    r = x % y;
    p = q * y + r;
    y++;

#ifdef cMIPS
    print(y);
    print(q);
    print(p);
#else                      // 1 2 3 5 7 11 13 17 19 23 29 31
      printf("%08x\n%08x\n%08x\n",y,q,p);
#endif
  }

}
