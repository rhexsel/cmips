/***************************************************************
 * check randomness of rand() [after Kelley & Phol pp 81]
 ***************************************************************/

#ifdef cMIPS
  #include "cMIPS.h"
#else
  #include <stdio.h>
  #include <stdlib.h>
#endif

#define ABS(x) ( ((x) < 0) ? -(x) : (x) )

 int Random( int *m_z,  int *m_w) { // from wikipedia
  *m_z = 36969 * (*m_z & 65535) + (*m_z >> 16);
  *m_w = 18000 * (*m_w & 65535) + (*m_w >> 16);
  return ((*m_z << 16) + *m_w);  /* 32-bit result */
}

#define MAX_NUM 100
#define SHOW (MAX_NUM / 5)

void main(void){
  int i, above, below, maxdif, newv;
  int median;
  
  int m_w = 177;    /* must not be zero, nor 0x464fffff */
  int m_z = 311;    /* must not be zero, nor 0x9068ffff */

  above = below = maxdif = 0;

  median = 0xffffffff;  // median ===> (2^32 - 1)

#ifdef cMIPS
  // print(median); to_stdout('\n');
#else
  // printf("%08x\n\n", median);
#endif

  for( i=1; i<= MAX_NUM; i++ ){
    if( Random(&m_z, &m_w) <= median ) below++ ;
    else above++ ;
    if( (newv = ABS(above - below)) > maxdif ) maxdif = newv;
    if( (i % SHOW) == 0 ) {
#ifdef cMIPS
      print(i); print(above); print(below); print(maxdif); to_stdout('\n');
#else
      printf("%08x\n%08x\n%08x\n%08x\n\n", i, above, below, maxdif);
#endif
    }
  }
}

