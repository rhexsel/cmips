/*
 * Copyright (c) 1999-2000 Tony Givargis.  Permission to copy is granted
 * provided that this header remains intact.  This software is provided
 * with no warranties.
 *
 * Version : 2.8
 */

/*---------------------------------------------------------------------------*/
#include "cMIPS.h"

#ifndef cMIPS
  #include <stdio.h>
#endif

#define BSZ 256

unsigned char  bch[BSZ];
unsigned short bsh[BSZ];
unsigned int   bin[BSZ];

/*---------------------------------------------------------------------------*/

void main() {
    
  int i;

#ifdef cMIPS
extern void exit(int);
extern void print(int);
extern int readInt(int *);
extern void writeInt(int);
#endif
  
  bch[0] = 1;
  for(i=1; i<BSZ; i++) {
    bch[i] = bch[i - 1] + 1;
  }

  bsh[0] = 1;
  for(i=1; i<BSZ; i++) {
    bsh[i] = bsh[i - 1] + 1;
  }

  bin[0] = 1;
  for(i=1; i<BSZ; i++) {
    bin[i] = bin[i - 1] + 1;
  }


  for(i=0; i<BSZ; i=i+16) {
#ifdef cMIPS
    print((unsigned int)bch[i]);
    print((unsigned int)bsh[i]);
    print(bin[i]);
#else
    printf("%08x\n%08x\n%08x\n",
	   (unsigned int)bch[i], (unsigned int)bsh[i], bin[i]);
#endif
  }

}
