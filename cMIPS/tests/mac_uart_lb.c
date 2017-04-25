//-------------------------------------------------------------------
// loop-back test
//   UART's input must be connected to UART's output for this to work
//
// clear LCD screen, light up BLUE led, wait for 2 seconds, then
// send a string ('0'..'9') through the UART in loop-back mode
//   write received characters to the LCD display
// 7-segment displays the last UART's status (must be 0x40)
//
// on 30march2017 tested OK with speeds 2,4,7
//
//-------------------------------------------------------------------

#include "cMIPS.h"

#include "uart_defs.c"


#if 0
int strcopy(const char *y, char *x) {
  int i=0;
  while ( (*x++ = *y++) != '\0' ) // copy and check end-of-string
    i = i+1;
  *x = '\0';
  return(i+1);
}
#endif


// to remove code not needed for debugging at the simulator -> SYNTHESIS=0
#define SYNTHESIS 1

int main(void) {

  volatile Tserial *uart;  // tell GCC not to optimize away code
  volatile Tstatus status;
  Tcontrol ctrl;
  int i,n,r,s;
  int state;
  int *addr;

#if SYNTHESIS
  LCDinit();

  LCDclr();
  DSP7SEGput( 0, 0, 0, 0, 1); // light up BLUE led
  delay_ms(2000);             // wait 2 seconds

  LCDtopLine();

  LCDput(' ');
  LCDput('l');
  LCDput('o');
  LCDput('o');
  LCDput('p');
  LCDput('-');
  LCDput('b');
  LCDput('a');
  LCDput('c');
  LCDput('k');
  LCDput('?');
  LCDput(' ');
#else
  to_stdout('\n');
#endif

  uart = (void *)IO_UART_ADDR; // bottom of UART address range

  ctrl.ign   = 0;
  ctrl.rts   = 0;
  ctrl.ign2  = 0;
  ctrl.intTX = 0;
  ctrl.intRX = 0;
  ctrl.speed = 7;        // on 30march2017 tested for speed = {2,4,7}
  uart->cs.ctl = ctrl;

  // let us see the state
  state = uart->cs.stat.rxFull;
  LCDgotoxy(14,1);
  LCDbyte((unsigned char)state);
  DSP7SEGput( state>>4 , 0, state & 0xf, 0, 4);

  s = '0'; // start transmission from '0'
  do {
    i = 0;
    while ( ( state = uart->cs.stat.txEmpty ) == 0 ) {
      i = i+1;
      LCDgotoxy(14,1);
      LCDbyte((unsigned char)state);
      DSP7SEGput( state>>4 , 0, state & 0xf, 0, i & 0x07);
    };
    uart->d.tx = (int)s; // send out char

    if (s == '0') 
      LCDgotoxy(1,2);    // put cursor on second line
    i = 0;
    while ( ( state = uart->cs.stat.rxFull ) == 0 ) {
      i = i+1;
      DSP7SEGput( state>>4 , 0, state & 0xf, 0, i & 0x07);
    };
    r = uart->d.rx;      // get char from UART
    
#if SYNTHESIS
    LCDputc((unsigned char)r);  // send it to LCD display
    DSP7SEGput( state>>4 , 0, state & 0xf, 0, r & 0x07);
#else
    to_stdout(r);
#endif

    s = (char)((int)s + 1);     // next ASCII algarism

  } while (s != ':');

#if SYNTHESIS
  addr = (int *)IO_UART_ADDR;  // get last state
  state = *addr;               // must show 0x40 = TXempty, no errors
  DSP7SEGput( state>>4 , 0, state & 0xf, 0, 0x02); // light up GREEN

  do { delay_us(1) ; } while (1 == 1); // and wait forever
#else
  to_stdout('\n');
  to_stdout('\n');
#endif

  return 0;

}
