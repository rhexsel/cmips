#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <float.h>

typedef union
{
  unsigned int i;
  float f;
  struct
  { // Bitfields for exploration.
    unsigned int m : 23,
      e : 8,
     s : 1;
  } p;
} Float_t;

int main(){
  int n,i,j,r;
  float C;
  Float_t x;

  x.f = (float)1.0/3.0;

  printf("f %f = (-1)**%x * 1.%x ** (2**%d) = i 0x%x\n",
	 (float)x.f, (int)x.p.s, (int)(x.p.m<<1), (int)(x.p.e - 127), (int)x.i);

#if 0

    srand((unsigned int)time(NULL));
    
    printf("Quantos testes : ");
    i=scanf("%d",&n);
    float A[256],B[256],num;
    
    if( n > 255 ) { printf("erro: %d > 256\n", n) ; return(-1); };

    num = 3.141517;
    printf("int A[] = {");
    for (i = 0;i<n-1;i++) {
      A[i] = r = num / (float)((float)n * (float)i);
      // A[i] = ((float)rand())/(float)(rand()/5.0);
      printf("(int)0x%x,",(unsigned int)A[i]);
      // printf("(int)0x%x,",*((unsigned int*)(&A[i])));
    }
    
    A[i] = ((float)rand()/(float)(RAND_MAX/5.0));
    printf("(int)0x%x};\nint B[] = {",*(unsigned int*)&A[i]);
    
    for (i = 0;i<n-1;i++) {
        B[i] = ((float)rand()/(float)(RAND_MAX/5.0));
        printf("(int)0x%x,",*(unsigned int*)&B[i]);
    }
    B[i] = ((float)rand()/(float)(RAND_MAX/5.0));
    printf("(int)0x%x};\nint C[] = {",*(unsigned int*)&B[i]);
    
    for (i = 0;i<n;i++) {
        for (j = 0;j<n;j++) {
            C = A[i]*B[j];
            printf("(int)0x%x,",*(unsigned int*)&C);
        }
    }
    puts("\b};");

#endif  

    return(0);

}
