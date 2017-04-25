#include "cMIPS.h"

  int A[] = {
    // normal numbers
    (int)0x9c038000,(int)0x9c038000,(int)0x9c038000,(int)0x9c038000,
    // denormalized 
    (int)0x3c000000,(int)0x3c000000,(int)0x3f800000,
    // all 0 cases :  set  i < 12 stop case
    (int)0x00000000,(int)0x80000000,(int)0x00000000,(int)0x80000000,
    (int)0x00800000,(int)0x80800000,(int)0x00000000,(int)0x00000000,
    (int)0x80000000,(int)0x80000000,(int)0x00800000,(int)0x80800000,
    // all inf cases :  set  i < 12 stop case
    (int)0x7f800000,(int)0xff800000,(int)0x7f800000,(int)0xff800000,
    (int)0x7f000000,(int)0xff000000,(int)0xff800000,(int)0xff800000,
    (int)0x7f800000,(int)0xff800000,(int)0x7f000000,(int)0xff000000,
    // all NaN cases :  set  i < 11 stop case
    (int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,
    (int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7f800000,
    (int)0x7f800000,(int)0xff800000,(int)0xff800000
  };

  int B[] = {
    // normal numbers
    (int)0x3f800000,(int)0x3f800000,(int)0x3f800000,(int)0x3f800000,
    // denormalized
    (int)0x03800000,(int)0x03000000,(int)0x00200000,
    // all 0 cases
    (int)0x00000000,(int)0x80000000,(int)0x1c038000,(int)0x9c038000,
    (int)0x00800000,(int)0x80800000,(int)0x9c038000,(int)0x80000000,
    (int)0x00000000,(int)0x1c038000,(int)0x80800000,(int)0x00800000,
    // all inf cases
    (int)0x7f800000,(int)0xff800000,(int)0x1c038000,(int)0x9c038000,
    (int)0x7f000000,(int)0xff000000,(int)0x7f800000,(int)0x1c038000,
    (int)0x9c038000,(int)0x1c038000,(int)0xff000000,(int)0x7f000000,
    // all NaN cases
    (int)0x7fffffff,(int)0x7f800000,(int)0xff800000,(int)0x00000000,
    (int)0x80000000,(int)0x1c038000,(int)0x9c038000,(int)0x00000000,
    (int)0x80000000,(int)0x00000000,(int)0x80000000
  };

  int C[] = {
    // normalized, ordinary numbers
    (int)0x9c038000,(int)0x9c038000,(int)0x9c038000,(int)0x9c038000,
    // denorm
    (int)0x00400000,(int)0x00200000,(int)0x00200000,
    // all zero cases
    (int)0x00000000,(int)0x00000000,(int)0x00000000,(int)0x00000000,
    (int)0x00000000,(int)0x00000000,(int)0x80000000,(int)0x80000000,
    (int)0x80000000,(int)0x80000000,(int)0x80000000,(int)0x80000000,
    // all inf cases
    (int)0x7f800000,(int)0x7f800000,(int)0x7f800000,(int)0x7f800000,
    (int)0x7f800000,(int)0x7f800000,(int)0xff800000,(int)0xff800000,
    (int)0xff800000,(int)0xff800000,(int)0xff800000,(int)0xff800000,
    // all NaN cases
    (int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,
    (int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,
    (int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff
};


void main(void) {
  int i,j, acc;
  volatile int *fpu,res;        // address of fpu

  fpu = (int *)IO_FPU_ADDR;        // 0x0f0000c0; // MUL
  // fpu = (int *)IO_FPU_ADDR + 4; // 0x0f0000c8; // ADD
  // fpu = (int *)IO_FPU_ADDR + 8; // 0x0f0000cc; // DIV

  acc = 0;
  for (i = 0; i < 4; i++) { // normalized, ordinary numbers
      *fpu = A[i];
      *(fpu+1) = B[i];
      asm("nop");
      res = *fpu;
      if (res != C[i])
        acc = 1;
  }
  if (acc == 0) {
    to_stdout('n'); to_stdout('o'); to_stdout('r'); to_stdout('\n');
  } else {
    to_stdout('E'); to_stdout('R'); to_stdout('R'); to_stdout('\n');
  }

  acc = 0;
  for ( ; i < 4+3; i++) { // denormalized
      *fpu = A[i];
      *(fpu+1) = B[i];
      asm("nop");
      res = *fpu;
      if (res != C[i])
        acc = 1;
  }
  if (acc == 0) {
    to_stdout('d'); to_stdout('e'); to_stdout('n'); to_stdout('\n');
  } else {
    to_stdout('E'); to_stdout('R'); to_stdout('R'); to_stdout('\n');
  }

  acc = 0;
  for ( ; i < 7+12; i++) { // zeroes
      *fpu = A[i];
      *(fpu+1) = B[i];
      asm("nop");
      res = *fpu;
      if (res != C[i])
        acc = 1;
  }
  if (acc == 0) {
    to_stdout('z'); to_stdout('e'); to_stdout('r'); to_stdout('\n');
  } else {
    to_stdout('E'); to_stdout('R'); to_stdout('R'); to_stdout('\n');
  }

  acc = 0;
  for ( ; i < 19+12; i++) { // infinites
      *fpu = A[i];
      *(fpu+1) = B[i];
      asm("nop");
      res = *fpu;
      if (res != C[i])
        acc = 1;
  }
  if (acc == 0) {
    to_stdout('i'); to_stdout('n'); to_stdout('f'); to_stdout('\n');
  } else {
    to_stdout('E'); to_stdout('R'); to_stdout('R'); to_stdout('\n');
  }

  acc = 0;
  for ( ; i < 21+11; i++) { // NaNs
      *fpu = A[i];
      *(fpu+1) = B[i];
      asm("nop");
      res = *fpu;
      if (res != C[i])
        acc = 1;
  }
  if (acc == 0) {
    to_stdout('N'); to_stdout('a'); to_stdout('N'); to_stdout('\n');
  } else {
    to_stdout('E'); to_stdout('R'); to_stdout('R'); to_stdout('\n');
  }

}
