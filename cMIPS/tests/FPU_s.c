#include "cMIPS.h"

void main(void) {
  int i,j;
  volatile int *fpu,res;        // address of fpu

  //fpu = (int *)0x0f0000c0; // MUL
  fpu = (int *)0x0f0000c8; // ADD
  //fpu = (int *)0x0f0000cf; // DIV


//  ALL NaN cases :  set  i < 9 stop case
//  int A[] = {(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7f800000,(int)0xff800000};
//  int B[] = {(int)0x7fc00000,(int)0x7f800000,(int)0xff800000,(int)0x80000000,(int)0x00000000,(int)0x32029000,(int)0x82029000,(int)0xff800000,(int)0x7f800000};
//  int C[] = {(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff,(int)0x7fffffff};
//  ALL +inf cases :  set  i < 6 stop case
//  int A[] = {(int)0x7f800000,(int)0x7f800000,(int)0x7f800000,(int)0x7f800000,(int)0x7f800000,(int)0x7f000000};
//  int B[] = {(int)0x7f800000,(int)0x00000000,(int)0x80000000,(int)0x32029000,(int)0x82029000,(int)0x7f000000};
//  int C[] = {(int)0x7f800000,(int)0x7f800000,(int)0x7f800000,(int)0x7f800000,(int)0x7f800000,(int)0x7f800000};
//  ALL -inf cases :  set  i < 6 stop case
//  int A[] = {(int)0xff800000,(int)0xff800000,(int)0xff800000,(int)0xff800000,(int)0xff800000,(int)0xff000000};
//  int B[] = {(int)0xff800000,(int)0x00000000,(int)0x80000000,(int)0x32029000,(int)0x82029000,(int)0xff000000};
//  int C[] = {(int)0xff800000,(int)0xff800000,(int)0xff800000,(int)0xff800000,(int)0xff800000,(int)0xff800000};
//  ALL 0 cases :  set  i < 4 stop case
//  int A[] = {(int)0x00000000,(int)0x00000000,(int)0x80000000,(int)0x32029000};
//  int B[] = {(int)0x00000000,(int)0x80000000,(int)0x80000000,(int)0xb2029000};
//  int C[] = {(int)0x00000000,(int)0x00000000,(int)0x80000000,(int)0x00000000};
//  ALL denorm cases, and a special case (denorm + denorm = normal) :  set  i < 3 stop case
//  int A[] = {(int)0x00800000,(int)0x0980000f,(int)0x00780000};
//  int B[] = {(int)0x80400000,(int)0x89800000,(int)0x00780000};
//  int C[] = {(int)0x00400000,(int)0x003c0000,(int)0x00f00000};

//  teses with normal numbers
//  int A[] = {};
//  int B[] = {};
//  int C[] = {};



  for (i = 0; i < 3; i++) {
      *fpu = A[i];
      *(fpu+1) = B[i];
      res = *fpu;
      if (res == C[i])
        print((int)0x00000000);
      else
        print((int)0xffffffff);
  }
}
