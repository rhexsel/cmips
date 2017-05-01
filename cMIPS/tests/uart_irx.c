//
// Test interrupts caused by UART's reception circuit.
//
// Remote unit reads string from serial.inp and sends it over the
//   serial line.
//
// This program makes use of abstraction to synchronize handler and main().
//   handler sets a flag on receiving a new character; main() waits for
//   flag==1, reads char, makes flag=0.
//
// UARTinterr, in include/handlers.s, reads newly arrived character,
//   sets a flag and puts character in a buffer.
// main() waits for flag==1, then reads from the buffer, prints
//    character to the simulator's standard output, makes flag=0.
//

#include "cMIPS.h"

#include "uart_defs.h"

#define U_DATA 0
#define U_FLAG 1

#define SPEED 2    // operate at 1/4 of the highest data rate


int main(void) {  // receive a string through the UART serial interface
  volatile Tserial *uart;  // tell GCC not to optimize away code
  Tcontrol ctrl;
  extern int Ud[2];  // declared in include/handlers.s
  volatile int *bfr;
  volatile char c;

  bfr = (int *)Ud;
  uart = (void *)IO_UART_ADDR; // bottom of UART address range

  ctrl.ign   = 0;
  ctrl.rts   = 0;  // make RTS=0 to hold remote unit inactive
  ctrl.intTX = 0;
  ctrl.intRX = 0;
  ctrl.speed = SPEED;
  uart->ctl = ctrl; // initizlize UART

  // handler sets flag=[U_FLAg] to 1 after new character is received;
  // this program resets the flag on fetching a new character from buffer
  bfr[U_FLAG] = 0;      //   reset flag  

  ctrl.ign   = 0;
  ctrl.rts   = 1;  // make RTS=1 to activate remote unit
  ctrl.intTX = 0;
  ctrl.intRX = 1;  // do generate interrupts on RXbuffer full
  ctrl.speed = SPEED;  // operate at 1/4 of the highest data rate
  uart->ctl = ctrl;

  do {
    while ( (c = (char)bfr[U_FLAG]) == 0 )  // check flag in Ud[]
      delay_cycle(1);                       // nothing new, wait
    c = (char)bfr[U_DATA];  // get new character
    bfr[U_FLAG] = 0;        //   and reset flag
    if (c != EOT) 
      to_stdout( c );       //   and print new char
    else
      to_stdout( '\n' );    //   and print new-line
  } while (c != EOT);       // end of transmission?

  return c;             // so compiler won't optimize away the last loop

}
