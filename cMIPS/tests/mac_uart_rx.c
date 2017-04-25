//========================================================================
// UART reception functional test
// Linux computer must be connected via USB-serial (/dev/ttyUSB0)
//    and must run putty @ 9,600 bps
// If all is well, LCD's line 2 shows text typed into putty's terminal.
// LCD screen shows on line 1 "cMIPS UART_status UART_error" and on line 2 
//    the last 15 chars typed on putty.  
// If all is well, UART_status=0x60="open single quote"
// in case of error, 
//     UART_error=0x61='a'=overun or 0x62='b'=framing or 0x63='c'=ovr+fram
// 7-segment leds show status.TXempty and status.RXfull,
//    left dot=framing error, right dot=overun error
// This test runs forever.
//========================================================================


#include "cMIPS.h"

#include "uart_defs.c"


#if 0
char s[32]; // = "the quick brown fox jumps over the lazy dog";
#else
// char s[32]; // = "               ";
#endif

void main(void) { // receive a string through the UART serial interface
                 // and write it to the LCD display
  volatile Tserial *uart;  // tell GCC not to optimize away code
  volatile Tstatus status;
  Tcontrol ctrl;
  int i,n, state;
  char c;

  LCDinit();

  LCDtopLine();

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

  LCDgotoxy(1,2);
  n = 1;
  do {

    do { 
      delay_us(1); // just do something so gcc won't optimize this away
      status = uart->cs.stat;
    } while ( status.rxFull == 0 );

    c = (char)uart->d.rx;

    state = ((status.cts <<7) |
      (status.txEmpty <<6) | (status.rxFull <<5) |
      // (status.int_TX_empt <<4) | (status.int_RX_full <<3) | 
	     (status.framing <<1) | status.overun) & 0xff;

    LCDgotoxy(8,1);
    LCDput((unsigned char)state);

    if (status.framing != 0 || status.overun != 0) {
      LCDgotoxy(11,1);
      LCDput((unsigned char)state);
      DSP7SEGput( (int)status.txEmpty, 
		  (int)status.framing,
		  (int)status.rxFull, 
		  (int)status.overun, 0 );
    }
    LCDgotoxy(n,2);
    LCDputc(c);

    n = n + 1;
    if ( n == 15 ){
      delay_ms(1000);
      LCDgotoxy(1,2);
      for(i = 1; i < 15; i++)
	LCDputc(' ');
      LCDgotoxy(1,2);
      n = 1;
    }

  } while (1 == 1);

  exit(0);

}
