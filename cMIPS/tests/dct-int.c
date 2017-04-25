/*
 * Copyright (c) 1999-2000 University of California, Riverside.
 * Permission to copy is granted provided that this header remains
 * intact.  This software is provided with no warranties.
 *
 * Version : 1.0
 * Version : 2.0 (changed to run on PC) 2/18/01
 * Version : 3.0 (changed to use as small variables as possible) 2/25/01
 *
 */

/*--------------------------------------------------------------------------*/

// This file does a Discrete Cosine Transform (DCT) on the 8X8 matrix inBuffer
// It then does the reconstruction of the result.
// The reconstruction should be similar, but not exactly equal to inBuffer

#include "cMIPS.h"

#ifndef cMIPS
  #include <stdio.h>
#endif

const int COS_TABLE[8][8] = {
  {64,   62,   59,   53,   45,   35,   24,   12},
  {64,   53,   24,  -13,  -46,  -63,  -60,  -36},
  {64,   35,  -25,  -63,  -46,   12,   59,   53},
  {64,   12,  -60,  -36,   45,   53,  -25,  -63},
  {64,  -13,  -60,   35,   45,  -54,  -25,   62},
  {64,  -36,  -25,   62,  -46,  -13,   59,  -54},
  {64,  -54,   24,   12,  -46,   62,  -60,   35},
  {64,  -63,   59,  -54,   45,  -36,   24,  -13}
};  /* taken times constant 64 and 'integerized' */

const int ONE_OVER_SQRT_TWO = 45; /* taken time constant 64 and 'integerized' */

const  int inBuffer[8][8]= {
  { 100, 90, 80, 70,  0,  0,  0, 0 },
  { 100,  0,  0,  0, 60,  0,  0, 0 },
  { 100,  0,  0,  0, 60,  0,  0, 0 },
  { 100,  0,  0, 70, 60,  0,  0, 0 },
  { 100,  0,  0,  0, 60,  0,  0, 0 },
  { 100,  0,  0,  0,  0, 50,  0, 0 },
  { 100,  0,  0,  0,  0, 50,  0, 0 },
  { 100, 90, 80, 70, 60, 50,  0, 0 }
};

int outBuffer[8][8];
int recsrct [8][8];

/*--------------------------------------------------------------------------*/

// int C (int h) {    /* taken time constant 64 and 'integerized' */
//   
//  return (h ? 64 : ONE_OVER_SQRT_TWO);
//}

#define C(h)  (h ? 64 : ONE_OVER_SQRT_TWO)


/*--------------------------------------------------------------------------*/
int F(int u, int v, const int img[8][8]) {
    
  int r;
  int x,y;
  r = 0;
  for(x=0; x < 8; x++) {
    for (y=0; y < 8; y++){
      r = r + ((img[x][y] * COS_TABLE[x][u] * COS_TABLE[y][v]) >> 12);
    }
  }

  return (int) (r  * C(u) * C(v) >> 14);
}


/*--------------------------------------------------------------------------*/

void CodecDoFdct(void) {
    
   int u, v;
  
  for(u=0; u < 8; u++) {
    for(v=0; v < 8; v++) {
      outBuffer[u][v] = F(u, v, inBuffer);
    }
  }
}

/*--------------------------------------------------------------------------*/

void Reconstruct (void) {

  int x, y, u, v;
  int  temp1 = 0, temp2 = 0;

  for (x=0; x < 8; x++) {
    for (y=0; y < 8; y++) {
      temp1 = 0;
      for (u=0; u < 8; u++){
	for (v=0; v < 8; v++){
	  temp1 = temp1 + 
	    ((C(u) * C(v) * outBuffer[u][v] * COS_TABLE[x][u] * COS_TABLE[y][v])
	     >> 24);
	}
      }
      temp2 = temp1 >> 2;  /* shifted to divide by 4 */
      recsrct[x][y] = temp2;
    }
  }
}

/*--------------------------------------------------------------------------*/

int main (void) {

  int i,j;
#ifdef cMIPS
  int *IO = (int *)x_IO_BASE_ADDR;
#endif

  CodecDoFdct();

  for ( i=0; i < 8; i++ ) {
    for ( j=0; j < 8; j++ ) {

#ifdef cMIPS
      *IO++ = outBuffer[i][j];
#else
      printf("%08x ",outBuffer[i][j]);
#endif

    } /* end j */

#ifdef cMIPS
      *IO++ = 0xaaaa0000;
#else
      printf("\n");
#endif
  } /* end i */


#ifdef cMIPS
  *IO++ = 0xaaaa0000;
  *IO++ = 0xffffffff;
  *IO++ = 0xffffffff;
  *IO++ = 0xaaaa0000;
#else
  printf("\n");
#endif


  Reconstruct();

  for ( i=0; i < 8; i++ ) {
    for ( j=0; j < 8; j++ ) {
      
#ifdef cMIPS
      *IO++ = recsrct[i][j];
#else
      printf("%08x ",recsrct[i][j]);
#endif

    } /* end j */

#ifdef cMIPS
      *IO++ = 0xaaaa0000;
#else
      printf("\n");
#endif
  } /* end i */

  return(0);
}

//z 000000de 0000009c 00000022 00000071 00000062 0000001d 00000024 00000016 
//z ffffffed 0000000b ffffffff ffffffe0 00000018 00000000 ffffffde 00000018 
//z 0000003c 00000032 fffffff6 ffffffca ffffffbc fffffff1 00000001 ffffffdd 
//z ffffffe1 fffffffd 00000021 fffffff5 ffffffdd 0000000d 00000011 ffffffe6 
//z 00000042 00000030 ffffffd3 ffffffc2 fffffff8 fffffffa ffffffdd ffffffef 
//z fffffff9 00000000 00000001 ffffffec fffffff6 00000019 00000002 ffffffd8 
//z 00000016 00000011 fffffff9 ffffffe8 ffffffe1 fffffff7 fffffffe fffffff0 
//z ffffffeb fffffffb 0000000e 00000000 fffffff5 ffffffee fffffffe 00000014 
//z 
//z 0000003c 00000057 00000041 0000003d fffffff3 fffffff8 fffffff7 fffffff7 
//z 00000062 fffffff4 fffffff7 fffffff6 00000034 fffffff6 fffffff7 fffffff9 
//z 00000054 fffffff6 fffffff4 fffffff6 00000033 fffffff8 fffffff6 fffffff9 
//z 0000005c fffffff7 fffffff6 0000003e 00000035 fffffff8 fffffff7 fffffff8 
//z 00000057 fffffff7 fffffff6 fffffff6 00000033 fffffff6 fffffff6 fffffff9 
//z 0000005c fffffff5 fffffff6 fffffff6 fffffff8 00000029 fffffff7 fffffff7 
//z 0000005a fffffff5 fffffff5 fffffff6 fffffff6 00000029 fffffff7 fffffff8 
//z 00000056 00000054 00000046 0000003e 00000035 0000002a fffffff8 fffffff5 
