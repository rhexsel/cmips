//
// Test UART's transmission circuit.
//
// Remote unit receives a string over the serial line and prints it
//   on the simulator's standard output.
//

#include "cMIPS.h"

#include "uart_defs.c"



#define LONG_STRING 1

#if LONG_STRING
char *dog = "\n\tthe quick brown fox jumps over the lazy dog\n";
char s[32];
#else
char s[32]; //  = "123";
#endif

int strcopy(const char *y, char *x)
{
  int i=0;
  while ( (*x++ = *y++) != '\0' ) // copia e testa final
    i = i+1;
  *x = '\0';
  return(i+1);
}



#define SPEED 0       // operate at the highest data rate

// how long to wait for last bits to be sent out before ending simulation
#define COUNTING ((SPEED+1)*100) 


int main(void) { // send a string through the UART serial interface
  int i;
  volatile unsigned int state, val;

  volatile Tserial *uart;  // tell GCC to not optimize away any code
  Tcontrol ctrl;

  volatile int *counter;        // address of counter

#if LONG_STRING
  i = strcopy(dog, s);
#else
  s[0] = '1';   s[1] = '2';   s[2] = '3';   s[3] = '\0';
#endif 

  uart    = (void *)IO_UART_ADDR;  // UART's address

  counter = (void *)IO_COUNT_ADDR; // counter's address

  ctrl.speed = SPEED;
  ctrl.intTX = 0;  // no interrupts
  ctrl.intRX = 0;
  ctrl.ign2  = 0;
  ctrl.ign   = 0;
  ctrl.rts   = 0;  // make RTS=0 so RemoteUnit won't transmit, just receive
  uart->ctl = ctrl;

  i = -1;
  do {

    i = i+1;
    while ( (state = (int)uart->stat.txEmpty) == 0 )
      delay_cycle(1);      // do something
    uart->data = (int)s[i];

  } while (s[i] != '\0');  // '\0' is transmitted in previous line

  // then wait until last char is sent out of the shift-register to return
  startCounter(COUNTING, 0);

  while ( (val=(readCounter() & 0x3fffffff)) < COUNTING )
    delay_cycle(1);

  return val;              // so compiler won't optimize away the last loop
}
