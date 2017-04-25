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
#else
  #include <stdio.h>
#endif
/*---------------------------------------------------------------------------*/

void sort(short* buf, int n) {
  int i, j;
  short t;
  
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

void myprint(short* buf, int n) {
  int i;
  
  for(i=0; i < n; i++) {
        
#ifdef cMIPS
    print((int)buf[i]);
#else
    printf("%08x\n",buf[i]);
#endif

    }
}

/*---------------------------------------------------------------------------*/

#define BUF_SZ 12

// short buf[] = { 0x13,0x12,0xfffd,0x01,0x10,0xfffb,0x0f,0x0e,0xfff3,0x0c,0x0b,0x0a };    

int main() {

  //  int buf[] = { 19, 18, 17, 16, 15, 14, 13, 12, 11, 10 };
  //short buf[] = { 19, 18, -3, 17, 16, -5, 15, 14, -13, 12, 11, 10 };

#ifdef cMIPS
  short *DATA = (short *)x_DATA_BASE_ADDR;
#else
  short DATA[BUF_SZ];
#endif

  short *ptr = DATA;
  unsigned int i, m_w, m_z;

  // from wikipedia
  m_w = 17;    /* must not be zero, nor 0x464fffff */
  m_z = 31;    /* must not be zero, nor 0x9068ffff */

  for (i=0; i < BUF_SZ; i++, ptr++) {
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    *ptr = (short)((m_z << 16) + m_w) & 0xffff;  /* 8-bit result */
  }

  sort(DATA, BUF_SZ);
  myprint(DATA, BUF_SZ);

}
