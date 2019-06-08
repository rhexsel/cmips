// Testing the external counter is difficult because it counts clock cycles
// rather than instructions -- if the io/instruction latencies change then
// the simulation output also changes and comparisons become impossible.

#include "cMIPS.h"


// convert small integer (i<16) to hexadecimal digit
#define i2c(a) ( ((a) < 10)   ? ((a)+'0') : (((a)+'a')-10) )


#define N  6                    // must be less than 29
#define CNT_VALUE 0x40000040    // set count to 64 cycles

void main(void) {
  int i, increased, new, old, newValue;

  newValue  = CNT_VALUE;
  increased = TRUE;

  for (i=1; i < (N+1); i++) {   // repeat N rounds
    print(i);                   // print number of round
    // to_stdout( i2c(i) );     // print number of round
    // to_stdout('\n');

    newValue = CNT_VALUE + (i<<3);
    startCounter(newValue, 0);  // num cycles increases with i, no interrupts

    old = 0;

    do {

      if ( (new = readCounter()) > old) {
	increased = increased & TRUE;
	old = new;
	// print(new);          // print current count, not for automated tests
      } else {
	increased = FALSE;
      }

    } while ( (readCounter() & 0x3fffffff) < (newValue & 0x3fffffff) );
    // are we done yet?

    if (increased) {
      to_stdout('o');
      to_stdout('k');
    } else {
      to_stdout('e');
      to_stdout('r');
      to_stdout('r');
    }

    to_stdout('\n');
  }

}
