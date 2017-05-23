//
// test DMA state machine -- not connected to CPU's data bus
//

#include "cMIPS.h"

#define FALSE (0==1)
#define TRUE  !(FALSE)

#define C_READ  0x80000000
#define C_WRITE 0x00000000
#define C_INTER 0x40000000

#define S_OPER  0x80000000
#define S_IPEND 0x40000000
#define S_BUSY  0x20000000
#define S_ADDR_MASK 0x00000fff

#define I_SET   0x00000002
#define I_CLR   0x00000001

#define CTRL   0
#define STAT   1
#define SRC    2
#define DST    3
#define INTERR 4

#define NUM 8

#define MEM_ADDR (x_DATA_BASE_ADDR + 4096 + 2048)

int main(void) {
  int i, increased, old, newValue;
  volatile int *c;
  volatile int new;

  c = (int *)IO_DMA_ADDR;

  *(c+CTRL) = C_WRITE | NUM;

  *(c+SRC) = 0;

  *(c+DST) = MEM_ADDR;

  for (i = 0; i < 2 ; i++) {
    new = *(c+STAT);
    print(new);
  }

  delay_cycle(5);

  print( *(c+STAT) );

#if 0

  *(c+CTRL) = C_WRITE | C_INTER | NUM;

  *(c+SRC) = 0;

  *(c+DST) = x_DATA_BASE_ADDR + 4096;

  for (i = 0; i < 2 ; i++) {
    new = *(c+STAT);
    print(new);
  }

  if (new & S_IPEND) {
    *(c+INTERR) = I_CLR;
  }
  delay_cycle(1);
  new = *(c+STAT);
  print(new);
#endif

  return(new & S_ADDR_MASK);

}
