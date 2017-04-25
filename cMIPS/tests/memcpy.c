
// # ifdef cMIPS
#include "cMIPS.h"
// #else
//   #include <stdio.h>
// #endif



#define sSz 20
#define dSz 30

// char src[sSz] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
// char dst[dSz] = {255,255,255,255,255,255,255,255,255,255,255,255,255,
//		255,255,255,255,255,255,255,255,255,255,255,255,255,
//		255,255,255,129};

int main(void) {
  char src[sSz];
  char dst[dSz];

  char *vet;
  char *s,*d;
  int i,j,N;

  for (i=0; i<sSz; i++)
    src[i] = (char)i+'a';

  for (i=0; i<dSz; i++)
    dst[i] = (char)255;
  dst[(dSz-1)] = (char)129;

#if 1

  for (j=1; j<=15; j++) {
    N=j; 
    s=src;
    d=dst;
    vet = memcpy(d, s, N);
    //#ifdef cMIPS
    for (i=0; i<N; i++) { to_stdout(vet[i]); } ; to_stdout('\n');
    //#else
    //  for (i=0; i<N; i++) { printf("%c", vet[i]); } ; printf("\n");
    //#endif

  }

#endif

#if 1

  for (j=1; j<=15; j++) {
    N=j; 
    d=dst;
    vet = memset(d, (char)('c'+j), N);
    //#ifdef cMIPS
    for (i=0; i<N; i++) { to_stdout(vet[i]); } ; to_stdout('\n');
    //#else
    // for (i=0; i<N; i++) { printf("%c", vet[i]); } ; printf("\n");
    //#endif


  }

#endif
  return(0);

};
