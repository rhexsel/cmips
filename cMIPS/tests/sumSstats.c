// sum of matrices to test sysStats
// 14/06/14, Edmar Bellorini


#ifdef cMIPS
  #include "cMIPS.h"
#else
  #include <stdio.h>
#endif

#define N 16

#ifdef cMIPS
  sStats st;
#endif

int A[N][N];
int B[N][N];
int C[N][N];

int main(void) {

  int i, j;


  for(i = 0; i < N; i++){
    for(j = 0; j < N; j++){
      A[i][j] = i + j;
      B[i][j] = i + j;
      C[i][j] = i + j;
    }
  }


  for(i = 0; i < N; i++){
    for(j = 0; j < N; j++){
      C[i][j] += A[i][j] + B[i][j];  // N*N write hits on C
    }
  }

#ifdef cMIPS
  to_stdout('\n');
  readStats(&st);
  print(st.dc_ref);
  print(st.dc_rd_hit);
  print(st.dc_wr_hit);
  print(st.dc_flush);
  print(st.ic_ref);
  print(st.ic_hit);

  exit(0);
#else
  for(i = 0; i < N; i++){
    for(j = 0; j < N; j++){
      printf("%d ", C[i][j]);
    }
    printf("\n");
  }

  return 0;
#endif

}
