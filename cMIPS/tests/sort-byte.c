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

void sort(char* buf, int n) {
  int i, j;
  char t;
  
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

void myprint(char* buf, int n) {
  int i,j;
  
  for(i=0; i < n; i++) {
        
#ifdef cMIPS
    print((signed char)buf[i]);
#else
    printf("%08x\n",buf[i]);
#endif

    }
  //0000000a 0000000b 0000000c 0000000d 0000000e 0000000f 00000010 00000011 00000012 00000013 
}

/*---------------------------------------------------------------------------*/

#define BUF_SZ 12

//char buf[] = { 0x13,0x12,-3,0x01,0x10,-5,0x0f,0x0e,-13,0x0c,0x0b,0x0a };
// char buf[] = { 0x13,0x12,0xfd,0x01,0x10,0xfb,0x0f,0x0e,0xf3,0x0c,0x0b,0x0a };

int main() {

  //  int buf[] = { 19, 18, 17, 16, 15, 14, 13, 12, 11, 10 };
  //char buf[]={ 19,  18,  -3,  1,   16,  -5,  15,  14,  -13, 12,  11,  10 };

#ifdef cMIPS
  char *DATA = (char *)x_DATA_BASE_ADDR;
#else
  char DATA[BUF_SZ];
#endif

  char *ptr = DATA;
  unsigned int i, m_w, m_z;

  // from wikipedia
  m_w = 17;    /* must not be zero, nor 0x464fffff */
  m_z = 31;    /* must not be zero, nor 0x9068ffff */

  for (i=0; i < BUF_SZ; i++, ptr++) {
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    *ptr = (char)((m_z << 16) + m_w) & 0xff;  /* 8-bit result */
  }

  sort(DATA, BUF_SZ);
  myprint(DATA, BUF_SZ);
  return(0);

}
