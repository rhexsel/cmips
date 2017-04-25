#include "cMIPS.h"

//
// read a key from keypad and write it to the LCD display
//

int main(void) {
  int i, j;
  volatile int state, k;
  int c, s;

  LCDinit();

  LCDtopLine();

  LCDput(' ');
  LCDput('H');
  LCDput('e');
  LCDput('l');
  LCDput('l');
  LCDput('o');
  LCDput(' ');
  LCDput('w');
  LCDput('o');
  LCDput('r');
  LCDput('l');
  LCDput('d');
  LCDput('!');

  LCDbotLine();

  j = 0;

  while ( 1 == 1 ) {

    while( (k = KBDget()) == -1 ) {};  // wait for key

    switch(k) {
    case 10:
	i = '*'; break;
    case 11:
	i = '#'; break;
    case 15:
	i = '0'; break;
    default:
	i = k + 0x30;
    }

    LCDput(i);
    LCDput(0x20);

    j = j + 1;

    if (j == 5) {
      j = 0;
      LCDgotoxy(1, 0);
    }

    delay_ms(500);

  }

  return 0;

}
