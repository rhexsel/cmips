//
// test the SDcard interface
// 
//

#include "cMIPS.h"

extern int _counter_val;

#define ACTIVE 1
#define OFF    0

#define SIMUL     FALSE
#define SYNTHESIS (!SIMUL)

#if SIMUL
#define QUARTER   0
#define HALFSEC   0
#define SECOND    0
#else
#define QUARTER   250
#define HALFSEC   500
#define SECOND   1000
#endif

#define WAIT_SEC   delay_ms(SECOND)
#define WAIT_HALF  delay_ms(HALFSEC)
#define WAIT_QUART delay_ms(QUARTER)



typedef struct control { // control register fields (uses only ls byte)
  unsigned int ign : 24, // ignore uppermost 3 bytes
    ign3  : 3,         // bits 7,6,5 ignored
    reset : 1,         // bit4: re-initialize the SDcard controller (drastic)
    ign2  : 2,         // bits 2,3 ignored
    rd    : 1,         // bit1: activate rd_i to read a block
    wr    : 1;         // bit0: activate wr_i to write a block
} Tcontrol;

typedef struct status {  // status register fields
  unsigned int busy : 1, // SDcard controller is busy
    oper_err : 1,        // attempted RD and WR simultaneous (bad idea)
    ign14    : 14,       // ignored (bits 29..16)
    error    : 16;       // error message from SDcard controller
} Tstatus;

typedef union stat {    // data registers on same address
  Tstatus stat;         // bit by bit
  int     lump;         // lumped
} Tstat;

typedef union data {    // data registers on same address
  int wr;               // write-only
  int rd;               // read-only
} Tdata;

typedef struct SDcard { // base address is (int *)IO_SDC_ADDR
  int addr;             // 32bit address register, at base+0
  Tdata     d;          // 8bit data register, at base+4 (LS byte only)
  Tcontrol  ctrl;       // 8bit control register, at base+8 (LS byte only)
  Tstat     stat;       // 32bit status register, at base+12
} Tsdcard;




void main(void) {
  int i, j, k;
  Tsdcard* sdc;

  Tcontrol ctrl;

  sdc = (Tsdcard *)IO_SDC_ADDR;

  // reset the controller
  ctrl.reset = 1;
  ctrl.rd = 0;
  ctrl.wr = 0;
  sdc->ctrl = ctrl;   // single pulse, no need to reset ctrl bit
  delay_cycle(0);           // give the controller some time

#if SYNTHESIS

  LCDinit();                // this takes a long time

  LCDtopLine();

  LCDput(' ');
  LCDput('H');
  LCDput('e');
  LCDput('l');
  LCDput('l');
  LCDput('o');
  LCDput(' ');
  LCDput('w');
  LCDput('o');
  LCDput('r');
  LCDput('l');
  LCDput('d');
  LCDput('!');

  LCDbotLine();
  WAIT_SEC;

  // check status
  LCDprint( sdc->stat.lump );

  WAIT_SEC;   WAIT_SEC; 

#endif

  while (sdc->stat.stat.busy == 1) { // wait for RESET to end
    delay_cycle(0);

#if SYNTHESIS
    DSP7SEGput(1, 0x04, 1, 0x04, l_GREEN);  // light up GREEN
    
    LCDgotoxy(1,2);
    LCDput('r');
    LCDput('s');
    LCDput('t');
    LCDput(':');
    LCDput(' ');
    LCDprint( sdc->stat.lump );
    WAIT_SEC;
    DSP7SEGput(0, 0x04, 0, 0x04, 0);  // led off
    WAIT_QUART;
#endif

  }

  if (sdc->stat.stat.busy == 0) {  // init OK, let us read one sector

    sdc->addr    = 0;              // start at address zero
    ctrl.reset = 0;
    ctrl.rd = 1;
    ctrl.wr = 0;
    sdc->ctrl = ctrl;
    delay_cycle(1);

    while ( sdc->stat.stat.busy == 0 )
      delay_cycle(1);

#if SYNTHESIS
    for (i=0; i < 512; i++) {      // read 512 bytes

      if ((i & 15) == 0)           // filled one line
	LCDgotoxy(1,1);
      LCDbyte( sdc->d.rd );
      
      if (sdc->stat.stat.busy == 0) {  // error while reading

	DSP7SEGput(0, 0x0c, 0, 0x0c, l_GREEN);

	LCDgotoxy(1,2);
	LCDput('e');
	LCDput('r');
	LCDput('r');
	LCDput(':');
	LCDput(' ');
	LCDprint( sdc->stat.lump );

	while (TRUE)  // wait forever
	  WAIT_SEC;
      }
    }
#endif

  } else { // busy was TRUE, this means something wrong

    while (sdc->stat.stat.busy == 1) {

#if SYNTHESIS
      DSP7SEGput(0, 0x04, 0, 0x04, l_RED);  // light up RED
    
      LCDgotoxy(1,2);
      LCDput('e');
      LCDput('r');
      LCDput('r');
      LCDput(':');
      LCDput(' ');
      LCDprint( sdc->stat.lump );
      WAIT_SEC;    
#endif
      // reset the controller
      ctrl.reset = 1;
      ctrl.rd = 0;
      ctrl.wr = 0;
      sdc->ctrl = ctrl;   // single pulse, no need to reset ctrl bit
      delay_cycle(0);     // give the controller some time

#if SYNTHESIS
      DSP7SEGput(0, 0x04, 0, 0x04, 0);  // led off
      WAIT_SEC;
      WAIT_SEC;
#endif
    }

#if SYNTHESIS
    DSP7SEGput(0, 0x04, 0, 0x04, l_RED & l_BLUE);  // light up purple
    while (TRUE) {  // wait forever
      WAIT_SEC;
      LCDgotoxy(8,2);
      LCDprint( sdc->stat.lump );
    }
#endif
  }

#if SYNTHESIS
  DSP7SEGput(0, 0, 0x0, 0x0, l_BLUE);
    
    LCDgotoxy(1,2);
    LCDput('O');
    LCDput('K');
    LCDput(':');
    LCDput(' ');
    LCDprint( sdc->stat.lump );
#endif
    while (TRUE)  // wait forever
      WAIT_SEC;

}

