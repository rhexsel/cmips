//========================================================================
// UART transmission functional test
// Linux computer must be connected via USB-serial (/dev/ttyUSB0)
//    and must run putty @ 9.600 bps
// If all is well, putty's screen shows, 
//   ten times '0'..'9''\n'  then ten times 'a'...'j''\n'.
// LCD screen shows on line 1 "cMIPS UART_status" and on line 2
//    {0123456789|abcedfghij}
// Test ends with RED led shining.
//========================================================================


#include "cMIPS.h"

#include "uart_defs.c"


#if 0
char s[64] = "the quick brown fox jumps over the lazy dog";
#else
// char s[32]; // = "               ";
#endif


void main(void) { // receive a string through the UART serial interface
                 // and write it to the LCD display
  volatile Tserial *uart;  // tell GCC not to optimize away code
  volatile Tstatus status;
  Tcontrol ctrl;
  int i,n,z, DELAY;
  int state;
  char c,d; // , s[32];

  LCDinit();

  LCDtopLine();

  LCDput(' ');
  LCDput('c');
  LCDput('M');
  LCDput('I');
  LCDput('P');
  LCDput('S');

  uart = (void *)IO_UART_ADDR; // bottom of UART address range

  ctrl.ign   = 0;
  ctrl.rts   = 1;
  ctrl.ign2  = 0;
  ctrl.intTX = 0;
  ctrl.intRX = 0;
  ctrl.speed = 7;  // 9.600 bps
  uart->cs.ctl = ctrl;


  //
  // let us try with a long delay between consecutive characters
  //
  c = '0';
  n = z = 0;

  DELAY = 2500;  // wait 2ms == 2 character times, at 9,600baud

  do {

    do { 
      delay_us(1); // just do something so gcc won't optimize this away
      status = uart->cs.stat;
    } while ( status.txEmpty == 0 );

    uart->d.tx = (int)c;

    DSP7SEGput( (int)status.txEmpty, 0, (int)status.rxFull, 0, 0);
    LCDgotoxy(8,1);
    LCDbyte(state);

    LCDgotoxy(11,1);
    LCDputc(c);

    n += 1;
    z += 1;
    c = (char)((int)c + 1);

    delay_us(DELAY);

    if( status.rxFull == 1 ) {
      d = uart->d.rx;
      LCDgotoxy(11,2);
      LCDputc(c);
    }

    if ( n == 10 ) {
      while ( uart->cs.stat.txEmpty == 0 )
	{ delay_us(1); } // do something
      uart->d.tx = (int)('\n');
      delay_us(DELAY);
      c = '0';
      n = 0;
    }

  } while (z < 100);



  //
  // let us try with a short delay between consecutive characters
  //
  c = 'a';
  n = z = 0;

  DELAY = 5;  // wait 5us == 1/200 character times, at 9,600baud

  do {

    do { 
      delay_us(1); // just do something so gcc won't optimize this away
      status = uart->cs.stat;
    } while ( status.txEmpty == 0 );

    uart->d.tx = (int)c;

    DSP7SEGput( (int)status.txEmpty, 0, (int)status.rxFull, 0, 0);
    LCDgotoxy(8,1);
    LCDbyte(state);

    LCDgotoxy(11,1);
    LCDputc(c);

    n += 1;
    z += 1;
    c = (char)((int)c + 1);

    delay_us(DELAY);

    if( status.rxFull == 1 ) {
      d = uart->d.rx;
      LCDgotoxy(11,2);
      LCDputc(c);
    }

    if ( n == 10 ) {
      while ( uart->cs.stat.txEmpty == 0 )
	{ delay_us(1); } // do something
      uart->d.tx = (int)('\n');
      delay_us(DELAY);
      c = 'a';
      n = 0;
    }

  } while (z < 100);

  exit(0);

}
