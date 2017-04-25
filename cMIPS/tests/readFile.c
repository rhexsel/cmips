#include "cMIPS.h"

char s[] = "the quick brown fox jumps over the lazy dog";

void main(void) { // copy input.data to output.data, both binary files
  int i,n,val;
  // char s[] = "abcd"; -- GCC generates wrong code for this declaration B^(

#if 0
  print(1);
  while ( readInt(&val) == 0 ) {
    print(val);
    writeInt(val);
  };
  writeClose();

#else

  to_stdout('\0'); // blank line

  for (i=0; s[i] != '\0' ; i++)
    to_stdout(s[i]);

  to_stdout('\0'); // end of line

  to_stdout('\0'); // blank line

  dumpRAM();

  to_stdout('\0'); // blank line

  dumpRAM();

#endif
}

