/*
/* matrix_m.c
/*
/* by:
/* Brian Grattan
/*
/**********************************************************************/
#ifdef cMIPS
  #include "cMIPS.h"
#else
  #include <stdio.h>
#endif
/**********************************************************************/


int random(int *m_z, int *m_w) {   // from wikipedia
  *m_z = 36969 * (*m_z & 65535) + (*m_z >> 16);
  *m_w = 18000 * (*m_w & 65535) + (*m_w >> 16);
  return ((*m_z << 16) + *m_w);  /* 32-bit result */
}

#define mSz 4

void main () {

  int matrix_a [mSz][mSz]; // = { { 1, 2, 3 }, { 4, 5,-6 }, {-7, 8, 9 } };
  int matrix_b [mSz][mSz]; // = { {-1, 1,-6 }, {-2, 2, 8 }, {-3, 3, 4 } };
  int result [mSz][mSz];
  int i, j, k;
  int sum;

  int m_w = 17;    /* must not be zero, nor 0x464fffff */
  int m_z = 31;    /* must not be zero, nor 0x9068ffff */


  for ( i=0; i<mSz; i++ ) {
    for ( j=0; j<mSz; j++ ) {
      matrix_a[i][j] = random(&m_z, &m_w);
      matrix_b[i][j] = random(&m_z, &m_w);
    }
  }

#ifdef cMIPS
  int *IO = (int *)x_IO_BASE_ADDR;
#endif
	
  for ( i=0; i<mSz; i++ ) {
    for ( j=0; j<mSz; j++ ) {
      sum = 0;
      for ( k=0; k<mSz; k++ ) {
	sum = sum + ( matrix_a [i][k] * matrix_b [k][j] );
	// *IO = sum;
      }
      result [i][j] = sum;
    } /* end j */
  } /* end i */

  for ( i=0; i<mSz; i++ ) {
    for ( j=0; j<mSz; j++ ) {

#ifdef cMIPS
      print(result[i][j]);
#else
      printf("%08x\n",result[i][j]);
#endif

    } /* end j */

#ifdef cMIPS
    to_stdout('\n');
#else
    printf("\n");
#endif
  } /* end i */

} /* end main */

