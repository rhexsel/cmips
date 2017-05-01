//
// Test UART's reception circuit.
//
// Remote unit reads string from file serial.inp and sends it over the
//   serial line.  This program prints the string to simulator's stdout.


#include "cMIPS.h"

#include "uart_defs.h"



#if 0
char s[32]; // = "the quick brown fox jumps over the lazy dog";
#else
char s[32]; // = "               ";
#endif

#define SPEED 1

int main(void) { // receive a string through the UART serial interface
  int i;
  volatile int state;
  volatile Tserial *uart;  // tell GCC not to optimize away code
  volatile Tstatus status;
  Tcontrol ctrl;

  uart = (void *)IO_UART_ADDR; // bottom of UART address range

  // reset all UART's signals
  ctrl.ign   = 0;
  ctrl.rts   = 0;      // make RTS=0 to keep RemoteUnit inactive
  ctrl.ign2  = 0;
  ctrl.intTX = 0;
  ctrl.intRX = 0;
  ctrl.speed = SPEED;  // operate at the second highest data rate
  uart->ctl  = ctrl;

  i = -1;

  ctrl.ign   = 0;
  ctrl.rts   = 1;      // make RTS=1 to activate RemoteUnit
  ctrl.ign2  = 0;
  ctrl.intTX = 0;
  ctrl.intRX = 0;
  ctrl.speed = SPEED;  // operate at the second highest data rate
  uart->ctl  = ctrl;

  do {
    i = i+1;

    while ( (state = (int)uart->stat.rxFull) == 0 )
      delay_cycle(1);        // just do something
    s[i] = (char)uart->data;
    if (s[i] != EOT) {
      to_stdout( s[i] );     //   and print new char
    } else {
      to_stdout( '\n' );     //   print new-line
      to_stdout( EOT );      //   and signal End Of Transmission
    }
  } while (s[i] != EOT);

  return(state);

}
