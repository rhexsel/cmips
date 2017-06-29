//
// test DMA state machine -- read from "disk" and write it to memory
//

#include "cMIPS.h"

#define C_READ  0x80000000
#define C_WRITE 0x00000000
#define C_INTER 0x40000000

#define S_OPER  0x80000000
#define S_IPEND 0x40000000
#define S_BUSY  0x20000000
#define S_IPEND 0x10000000
#define S_E_SZ  0x04000000
#define S_E_DSK 0x03000000
#define S_ADDR_MASK 0x00001fff

#define I_SET   0x00000002
#define I_CLR   0x00000001

#define CTRL   0
#define STAT   1
#define SRC    2
#define DST    3
#define INTERR 4

#define NUM 16

#define MEM_ADDR (x_DATA_BASE_ADDR + 4096 + 2048)


extern int _dma_status[2]; // allocated in include/handlers.s

#define DMA_FLAG 0
#define DMA_STAT 1


int main(void) {
  int i, increased, old, newValue;
  volatile int *c;
  volatile int new;

  _dma_status[DMA_FLAG] = 0;

  c = (int *)IO_DMA_ADDR;

  *(c+CTRL) = C_READ | NUM;

  *(c+SRC) = 0;           // read file DMA_0.src 

  *(c+DST) = MEM_ADDR;    // and write NUM words to memory

  for (i = 0; i < 5 ; i++) {  // do something while waiting
    new = *(c+STAT);
    print(new);
    delay_cycle(i);
  }

  delay_cycle(20);

  to_stdout('\n');                    // verify if memory was written to
  for (i = 0; i < NUM ; i++) {
    print( *( (int *)MEM_ADDR+i ) );
  }
  to_stdout('\n');

  new = *(c+STAT);
  print(new);

  to_stdout('\n');


  delay_us(2); // give it plenty of time to start afresh


#if 1
  *(c+CTRL) = C_READ | C_INTER | (NUM*2);  // generate an interrupt at the end

  *(c+SRC) = 0;

  *(c+DST) = MEM_ADDR;

  while (_dma_status[DMA_FLAG] == 0) { // wait for interrupt
    new = *(c+STAT);
    print(new);
  }

  to_stdout('\n');
  print(_dma_status[DMA_STAT]); // print DMA status post interrupt
  to_stdout('\n');

  for (i = 0; i < (NUM*2) ; i++) {  // verify if memory was written to
    print( *( (int *)MEM_ADDR+i ) );
  }
  to_stdout('\n');

  new = *(c+STAT);
  print(new);

  to_stdout('\n');

#endif

  return(new & S_ADDR_MASK);

}
