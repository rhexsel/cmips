//
// test DMA state machine -- read from memory and write to "disk"
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


extern int _dma_status[2]; // allocated in include/handlers.s

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
  old = 1;
  for (i = 0; i < NUM; i++) {
    old = old + i;
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
  }

  delay_cycle(5);

  print( *(c+STAT) );

#if 1

  to_stdout('\n');

  old = 1;
  for (i = 0; i < NUM; i++) {
    old = old + i<<1;
    *mem = old;
    // print((int)mem);
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
    delay_cycle(1);
  }

  to_stdout('\n');
  print(_dma_status[DMA_STAT]); // print DMA status post interrupt

#endif

  to_stdout('\n');

  return(new & S_ADDR_MASK);

}
