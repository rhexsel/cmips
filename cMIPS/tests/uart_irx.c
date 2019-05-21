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
  Tserial  volatile *uart;  // tell GCC not to optimize away code
  Tcontrol ctrl;
  extern   int Ud[2];      // space reserved/declared in include/handlers.s
  volatile int *bfr;       // points to buffer Ud[]
  char c;

  bfr = (int *)Ud;             // buffer declared in include/handlers.s
  uart = (void *)IO_UART_ADDR; // bottom of UART address range

  ctrl.ign   = 0;
  ctrl.rts   = 0;  // make RTS=0 to hold remote unit inactive
  ctrl.ign4  = 0;
  ctrl.speed = SPEED;
  uart->ctl  = ctrl; // initialize UART

  // handler sets flag=[U_FLAG] to 1 after new character is received;
  // this program resets the flag on fetching a new character from buffer
  bfr[U_FLAG] = 0;      //   reset flag  

  // do generate interrupts on RXbuffer full
  uart->interr.i = UART_INT_progRX; // program only RX interrupts

  ctrl.ign   = 0;
  ctrl.rts   = 1;  // make RTS=1 to activate remote unit
  ctrl.ign4  = 0;
  ctrl.speed = SPEED; // operate at fraction of highest data rate
  uart->ctl = ctrl;

  do {
    while ( (c = (char)bfr[U_FLAG]) == 0 )  // check flag in Ud[]
      delay_cycle(1);                       // nothing new, wait

    c = (char)bfr[U_DATA];   // get new character
    bfr[U_FLAG] = 0;         //   and reset flag

    if (c != (char)EOT)      // if NOT end_of_transmission
      to_stdout( c );        //   then print new char
    else
      to_stdout( '\n' );     //   else print new-line

  } while (c != (char)EOT);  // end of transmission?

  return c;             // so compiler won't optimize away the last loop

}
