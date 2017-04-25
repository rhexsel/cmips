#include "cMIPS.h"

// -- cMIPS I/O functions -----------------------------------------------


// do not generate extra (simulation only) code when programming the FPGA

#ifdef FOR_SYNTHESIS
  #define FOR_SIMULATION 0
#else
  #define FOR_SIMULATION 1
#endif

#if FOR_SIMULATION

//=======================================================================
// simulator's STD_INPUT and STD_OUTPUT
//=======================================================================
// read a character from VHDL simulator's standard input
int from_stdin(void) {
  int *IO = (void *)IO_STDIN_ADDR;
  
  // gets line line only after receiving a '\n' (line-feed, 0x0a)
  return( *IO );
}

// write a character to VHDL simulator's standard output
void to_stdout(char c) {
  int *IO = (int *)IO_STDOUT_ADDR;
  
  // prints line only after receiving a '\0' or a '\n' (line-feed, 0x0a)
  *IO = (unsigned char)c;
}

// write an integer (hex) to VHDL simulator's standard output
void print(int n) { 
  int *IO = (int *)IO_PRINT_ADDR;

  *IO = n;
}


//=======================================================================
// simulator's file I/O
//=======================================================================
// read an integer from file input.data
//  return value = 1 if EndOfFile, 0 otherwise
int readInt(int *n) {
  int *IO = (int *)IO_READ_ADDR;
  int status, value;

  value  = *IO;
  status = *(IO + 1);

  if (status == 0) {
    *n = value;
  }
  return status;
}

// write an integer integer to file  output.data
void writeInt(int n) {
  int *IO = (int *)IO_WRITE_ADDR;

  *IO = n;
}

// close file output.data
void writeClose(void) {
  int *IO = (int *)IO_WRITE_ADDR;

  *(IO + 1) = 1;
}

// write a dump of the current state of the RAM to file dump.data
void dumpRAM(void) {
  char *IO = (char *)IO_WRITE_ADDR;

  *(IO + 7) = 1;
}; //--------------------------------------------------------------------


//=======================================================================
// system statistics -- read system counters
//=======================================================================
void readStats(sStats *s) {
#if 0
  int *IO = (int *)IO_STATS_ADDR;

  s->dc_ref    = *(IO+0);
  s->dc_rd_hit = *(IO+1);
  s->dc_wr_hit = *(IO+2);
  s->dc_flush  = *(IO+3);
  s->ic_ref    = *(IO+4);
  s->ic_hit    = *(IO+5);
#endif
}; //--------------------------------------------------------------------


//=======================================================================
// memcpy -- need this to fool GCC into believing we have libc
//=======================================================================
char *memcpy(char *dst, const char *src, int n) {
  int cnt;
  char *ret;

  ret = dst;
  cnt = (int)src % 4;
  while( (cnt > 0) && (n > 0) ) {
    *dst = *src;
    cnt--; n--;
    dst++; src++;
  } // src is now word aligned
  while ( n >= 4) {
    if ( ((int)dst % 4) == 0 ) { // dst aligned to word x00
      *((int *)dst) = *((int *)src);
    } else if ( ((int)dst % 2) == 0 ) { // dst aligned to short xx0
      *((short *)dst) = *((short *)src);
      *((short *)(dst+2)) = *((short *)(src+2));
    } else { // dst aligned to char
      *dst = *src;
      *((short *)(dst+1)) = *((short *)(src+1));
      *(dst+3) = *(src+3);
    }
    n-=4; src+=4; dst+=4;
  }
  while(n > 0) {
    *dst = *src;
    n--; dst++; src++;
  }
  return(ret);
}; //--------------------------------------------------------------------


//=======================================================================
// memset -- need this to fool GCC into believing we have libc
//=======================================================================
char *memset(char *dst, const int val, int len) {
  unsigned char *ptr = (unsigned char*)dst;
  int cnt;

  cnt = (int)ptr % 4;
  while( (cnt > 0) && (len > 0) ) {
    *ptr = (char)val;
    cnt--; len--;
    ptr++;
  } // ptr is now word aligned
  cnt = val | (val<<8) | (val<<16) | (val<<24);
  while (len >= 4) {
    *((int *)ptr) = cnt;
    len -= 4;
    ptr += 4;
  }
  while(len > 0) {
    *ptr = (char)val;
    len--;
    ptr++;
  }
  return(dst);
}; //--------------------------------------------------------------------




#else  // compile FOR_SYNTHESIS




//=======================================================================
// keyboard
//=======================================================================
// read the keyboard
//   keyboard presents key value in d0-d3, no-key=0x0
//   debouncing done if d31 != 0
//   switches are presented in d4-d7
int  KBDget(void) {
  int *IO = (int *)IO_KEYBD_ADDR;
  int k;
  
  k = *IO;
  if ( (k & 0x80000000) != 0 ) {
    if ((k & 0xf) == 15)
      return(0);
    else
      return(k & 0xf);
  } else {
    return(-1); // not debounced yet
  }
}


// read the slide switches -- no debouncing on these switches
//  data(3) <= sw(3);
//  data(2) <= sw(2);
//  data(1) <= sw(1);
//  data(0) <= sw(0);
int  SWget(void) {
  int *IO = (int *)IO_KEYBD_ADDR;
  int k;
  
  return ( (*IO & 0xf0) >>4 ); 
}
//-----------------------------------------------------------------------


//=======================================================================
// LCD display
//=======================================================================
/*
        # .byte  0b00110000        # x30 wake-up
        # .byte  0b00110000        # x30 wake-up
        # .byte  0b00111001        # x39 funct: 8bits, 2line, 5x8font, IS=0
        # .byte  0b00010111        # x17 int oscil freq: 1/5bias, freq=700kHz 
        # .byte  0b01110000        # x70 contrast for int follower mode: 0
        # .byte  0b01010110        # x56 pwrCntrl: ICON=off, boost=on, contr=2 
        # .byte  0b01101101        # x6d follower control: fllwr=on, aplif=5 
        # .byte  0b00001111        # x0f displayON/OFF: Off, cur=on, blnk=on
        # .byte  0b00000110        # x06 entry mode: blink, noShift, addrs++
        # .byte  0b00000001        # x01 clear display
        # .byte  0b10000000        # x80 RAMaddrs=0, cursor at home
        # .byte  0b10000000        # x80 RAMaddrs=0, cursor at home
        # .byte  0b11000000        # x80 RAMaddrs=40, cursor at home
*/

#define wait_1_sec       50000000/4 //  1s / 20ns
#define LCD_power_cycles 10000000/4 //  200ms / 20ns
#define LCD_reset_cycles 2500000/4  //  50ms / 20ns
#define LCD_clear_delay  35000/4    //  0.7ms / 20ns
#define LCD_delay_30us   1500/4     //  30us / 20ns
#define LCD_oper_delay   750/4      //  15us / 20ns
#define LCD_write_delay  750/4      //  15us / 20ns
#define LCD_busy         0x80

#define LCD_LINE_TWO     0x40       // RAM address for second line


void LCDinit(void) {
  int *IO = (int *)IO_LCD_ADDR;

  cmips_delay(LCD_reset_cycles); // wait 50ms for LCD controller to reset

  *IO = 0b00110000; // x30 = wake-up
  cmips_delay(LCD_delay_30us);

  *IO = 0b00110000; // x30 = wake-up
  cmips_delay(LCD_delay_30us);

  *IO = 0b00111001; // x39 funct: 8bits, 2line, 5x8font, IS=0
  cmips_delay(LCD_delay_30us);

  // set internal oscillator frequency to 700KHz
  *IO = 0b00010111; // x17 int oscil freq: 1/5bias, freq=700kHz 
  cmips_delay(LCD_delay_30us);

  // display is now on fast clock

  *IO = 0b01110000; // x70 contrast for int follower mode: 0
  cmips_delay(LCD_oper_delay); // wait for 15us

  *IO = 0b01010110; // x56 pwrCntrl: ICON=off, boost=on, contr=2
  cmips_delay(LCD_oper_delay);

  // change amplification (b2-b0) to increase contrast
  *IO = 0b01101101; // x6d follower control: fllwr=on, aplif=5 
  cmips_delay(LCD_oper_delay);

  *IO = 0b00001111; // x0f displayON/OFF: Off, cur=on, blnk=on
  cmips_delay(LCD_oper_delay);

  *IO = 0b00000001; // x01 clear display -- DELAY=0.6ms
  cmips_delay(LCD_clear_delay);

  *IO = 0b00000110; // x06 entry mode: blink, noShift, addrs++
  cmips_delay(LCD_oper_delay);
}

// check LCD's status register
int LCDprobe(void) {
  int *IO = (int *)IO_LCD_ADDR;
  return ( (*IO & LCD_busy)>>7 );
}

// write a new command to the LCD's control register
int LCDset(int cmd) {
  int *IO = (int *)IO_LCD_ADDR;
  volatile int s;

  *IO = cmd;
  cmips_delay(LCD_oper_delay);

  s = *IO;
  while ( (s & LCD_busy) != 0) { s = *IO; }; // still busy?
  return(s);
}

// write a "raw" character on the current position
int LCDput(int c) {
  int *IO = (int *)IO_LCD_ADDR;
  volatile int s;
  
  *(IO+1) = c;
  s = *IO;
  while ( (s & LCD_busy) != 0) { s = *IO; }; // still busy?
  return(s);
}

// clear screen
void LCDclr(void) {
  int *IO = (int *)IO_LCD_ADDR;
  *IO = 0b00000001; // x01 clear display -- DELAY=0.6ms
  cmips_delay(LCD_clear_delay);
}

// set home to the left of the TOP line
void LCDtopLine(void) {
  int *IO = (int *)IO_LCD_ADDR;
  *IO = 0b10000000; // x80 RAMaddrs=00, cursor at home on TOP LINE
  cmips_delay(LCD_clear_delay);
}

// set home to the left of the BOTTOM line
void LCDbotLine(void) {
  int *IO = (int *)IO_LCD_ADDR;
  *IO = 0b11000000; // xc0 RAMaddrs=40, cursor at home on BOTTOM LINE
  cmips_delay(LCD_clear_delay);
}

// set cursor at position (x,y)
void LCDgotoxy(int x, int y) {
   int address;

   if(y != 1)
     address = LCD_LINE_TWO;
   else
     address = 0;

   address += (x - 1);

   LCDset( 0x80 | (address & 0x7f) ); // write to control register
}

// write a "cooked" character to the display
void LCDputc(char c) {
  switch (c) {
  case '\f'   : LCDset(1); cmips_delay(LCD_clear_delay); break;
  case '\n'   : LCDgotoxy(1,2);         break;
  case '\b'   : LCDset(0x10);           break;
  default     : LCDput(c);              break;
  }
}

#define conv(c) ((c<10)?((c)+0x30):((c)+('a'-10)))

// write an integer to the display
void LCDint(unsigned int n) {
  int k;

  k = (n     >>28);
  LCDput( conv(k) );
  k = (n<< 4)>>28;
  LCDput( conv(k) );

  k = (n<< 8)>>28;
  LCDput( conv(k) );
  k = (n<<12)>>28;
  LCDput( conv(k) );

  k = (n<<16)>>28;
  LCDput( conv(k) );
  k = (n<<20)>>28;
  LCDput( conv(k) );

  k = (n<<24)>>28;
  LCDput( conv(k) );
  k = (n<<28)>>28;
  LCDput( conv(k) );
}

// write a short to the display
void LCDshort(unsigned short n) {
  int k;

  k = (n     >>12);
  LCDput( conv(k) );
  k = (n<< 4)>>12;
  LCDput( conv(k) );

  k = (n<< 8)>>12;
  LCDput( conv(k) );
  k = (n<<12)>>12;
  LCDput( conv(k) );
}

// write a char to the display
void LCDbyte(unsigned char n) {
  int k;

  k = (n     >>4);
  LCDput( conv(k) );
  k = (n<< 4)>>4;
  LCDput( conv(k) );
}

//-----------------------------------------------------------------------


//=======================================================================
// 7 segment display and RGB leds
// rgb values are in [0,7], stored in bits R=bit14, G=bit13, B=bit12
// MSdigit bits bit7..4, lsDigit bit3..0, MSD dot bit9, lsD dot bit8
//=======================================================================
void DSP7SEGput(int MSD, int MSdot, int lsd, int lsdot, int rgb) {
  int *IO = (int *)IO_DSP7SEG_ADDR;
  int leds, dot1, dot0, dig1, dig0;

  dot1 = (MSdot != 0 ? 1 << 9 : 0);
  dot0 = (lsdot != 0 ? 1 << 8 : 0);
  
  dig1 = (MSD & 0xf) << 4;
  dig0 = (lsd & 0xf);

  leds = (rgb & 0x07) <<12;

  *IO = leds | dot1 | dot0 | dig1 | dig0;
}
//-----------------------------------------------------------------------


#endif // FOR_SYNTHESIS



//=======================================================================
// external counter -- counts up to limit, then stops or interrupts
//=======================================================================
// write an integer with number of pulses to count and start counter
//  if interr is not 0, then raise an interrupt when count reaches 'n'
void startCounter(int n, int interr) {
  int *IO = (int *)IO_COUNT_ADDR;
  int interrupt;
  // set bit 31 to cause an interrupt on count==n, reset for no interrupt
  interrupt = (interr == 0 ? 0x00000000 : 0x80000000);

  // set bit 30 to start counting, reset to stop
  *IO = (interrupt | 0x40000000 | (0x3fffffff & n)); 
}

// stop the counter, keep current count & interrupt status
void stopCounter(void) {
  int *IO = (int *)IO_COUNT_ADDR;
  int value;
  
  value = *IO;
  *IO = value & 0xbfffffff; // reset bit 30 to stop counter
}

// read counter value and interrupt status
int readCounter(void) {
  int *IO = (int *)IO_COUNT_ADDR;

  return *IO;
}; //--------------------------------------------------------------------


