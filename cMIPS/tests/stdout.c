#include "cMIPS.h"

char s[] = "the quick brown fox jumps over the lazy dog";

void main(void) { // copy input.data to output.data, both binary files
  int i,n,val;
  // char s[] = "abcd"; -- GCC 4.8.1 generates wrong code for this decl  B^(

  to_stdout('\0'); // blank line

  for (i=0; s[i] != '\0' ; i++)
    to_stdout(s[i]);

  to_stdout('\0'); // end of line

  to_stdout('\0'); // blank line

}

