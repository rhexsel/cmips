
#ifdef cMIPS
  #include "cMIPS.h"
#else
  #include <stdio.h>
#endif

#define D_SZ 5

int reduzAND(int *v) {
  int i, ra;

  ra = 0xFFFFFFFF;
  for (i=0; i<D_SZ; i++) {
    ra = ra & v[i];
  }
  return(ra);
}

int reduzOR(int *v) {
  int i, ro;

  ro = 0x00000000;
  for (i=0; i<D_SZ; i++) {
    ro = ro | v[i];
  }
  return(ro);
}

int reduzSUM(int *v) {
  int i, ro;

  ro = 0x00000000;
  for (i=0; i<D_SZ; i++) {
    ro = ro + v[i];
  }
  return(ro);
}

int main (void) {
  int dat[D_SZ];

  int *ptr = dat;
  unsigned int i, m_w, m_z;

  // from wikipedia
  m_w = 17;    /* must not be zero, nor 0x464fffff */
  m_z = 31;    /* must not be zero, nor 0x9068ffff */

  for (i=0; i < D_SZ; i++, ptr++) {
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    *ptr = (m_z << 16) + m_w;  /* 32-bit result */
  }

#ifdef cMIPS
  print( reduzAND(dat) );   //  0x00006000
  print( reduzOR(dat)  );   //  0x737ff01e
  print( reduzSUM(dat) );   //  0xe89f102a
#else
  printf("%08x\n",reduzAND(dat));
  printf("%08x\n",reduzOR(dat));
  printf("%08x\n",reduzSUM(dat));
#endif

}
