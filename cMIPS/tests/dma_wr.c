//
// test DMA state machine -- read from memory and write to "disk"
//

#include "cMIPS.h"

#define C_READ   0x80000000
#define C_WRITE  0x00000000
#define C_INTER  0x40000000

#define S_OPER   0x80000000
#define S_INTERR 0x40000000
#define S_BUSY   0x20000000
#define S_OPER   0x80000000
#define S_IPEND  0x40000000
#define S_BUSY   0x20000000
#define S_E_SZ   0x04000000
#define S_E_DSK  0x03000000
#define S_ADDR_MASK 0x00001fff

#define I_SET    0x00000002
#define I_CLR    0x00000001

#define CTRL   0
#define STAT   1
#define SRC    2
#define DST    3
#define INTERR 4

#define NUM 16

#define MEM_ADDR (x_DATA_BASE_ADDR + 4096 + 2048)


extern volatile int _dma_status[2]; // allocated in include/handlers.s

#define DMA_FLAG 0
#define DMA_STAT 1


int main(void) {
  int i, increased, old, o;
  int *mem;
  int *old_mem;
  volatile int *c;
  volatile int new;

  _dma_status[DMA_FLAG] = 0;

  mem = (int *)MEM_ADDR;
  for (i = 0; i < NUM; i++) {
    old = (~i)+1;
    *mem = old;
    mem++;
    print(old);
  }
  old_mem = mem;
  
  to_stdout('\n');

  c = (int *)IO_DMA_ADDR;

  *(c+CTRL) = C_WRITE | NUM;

  *(c+SRC) = MEM_ADDR;

  *(c+DST) = 0;

  for (i = 0; i < 2 ; i++) {
    new = *(c+STAT);
    print(new);
    delay_cycle(i);
  }

  delay_cycle(5);

  print( *(c+STAT) );

#if 1

  to_stdout('\n');

  for (i = 0; i < NUM; i++) { // write 2's complement to memory
    old = (~i)+1;
    *mem = old;
    print(old);
    mem++;
  }

  to_stdout('\n');
 
  *(c+CTRL) = C_WRITE | C_INTER | NUM; // generate an interrupt at the end

  *(c+SRC) = (int)old_mem;

  *(c+DST) = 0;

  while (_dma_status[DMA_FLAG] == 0) { // wait for interrupt
    new = *(c+STAT);
    print(new);
    delay_cycle(32);
  }

  to_stdout('\n');
  print(_dma_status[DMA_STAT]); // print DMA status post interrupt

#endif

  to_stdout('\n');

  return(new & S_ADDR_MASK);

}
