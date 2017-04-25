/* BUBLLE SORT
 * Copyright (c) 1999-2000 Tony Givargis.  Permission to copy is granted
 * provided that this header remains intact.  This software is provided
 * with no warranties.
 *
 * Version : 2.8
 */

/*---------------------------------------------------------------------------*/
#ifdef cMIPS
  #include "cMIPS.h"
#else
  #include <stdio.h>
#endif

#define NUM_ITEMS 20

void sort(int buf[], int n);
void myprint(int buf[], int n);
/*---------------------------------------------------------------------------*/

// #include "sortData.h"

void main() {

#ifdef cMIPS
  int *buf = (int *)x_DATA_BASE_ADDR;
#else
  int buf[NUM_ITEMS];
#endif

  int *ptr = buf;
  unsigned int i, m_w, m_z;

  // from wikipedia
  m_w = 17;    /* must not be zero, nor 0x464fffff */
  m_z = 31;    /* must not be zero, nor 0x9068ffff */

  for (i=0; i < NUM_ITEMS; i++, ptr++) {
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    *ptr = (m_z << 16) + m_w;  /* 32-bit result */
  }

  sort(buf, NUM_ITEMS);
  myprint(buf, NUM_ITEMS);

}
/*---------------------------------------------------------------------------*/
void sort(int buf[], int n) {
  int i, j, t;
  
  for(i=0; i < n; i++) {
    for(j=i; j < n; j++) {
      if( buf[i] > buf[j] ) {
	t = buf[i];
	buf[i] = buf[j];
	buf[j] = t;
      }
    }
  }
}

/*---------------------------------------------------------------------------*/
void myprint(int buf[], int n) {
  int i;

  for(i=0; i < n; i++) {

#ifdef cMIPS
    print( buf[i] );
#else
    printf("%08x\n",buf[i]);
#endif

  }
}
/*---------------------------------------------------------------------------*/

// 000008cd
// 00000a8d
// 00000c0f
// 00000fc3
// 000015ac
// 00001731
// 00001ae9
// 00001ca0
// 00002105
// 0000212d
// 0000223d
// 000023c7
// 000024bf
// 000025fa
// 00002f29
// 000032bd
// 000033ad
// 000037b1
// 00003abe
// 00003bde
// 00003f66
// 00004276
// 00004406
// 00004551
// 000045a6
// 000046fe
// 00004812
// 0000487c
// 000049d5
// 00004c72
// 00004cb5
// 00004fde
// 00005249
// 000055f5
// 000056f4
// 00005e9e
// 00005f6e
// 000062ab
// 000063da
// 000065be
// 000067a8
// 00006902
// 00006995
// 0000719f
// 00007800
// 000079cb
// 00007d4b
// 00007de8
// 00007e8f
// 00007f39

