
#define x_INST_BASE_ADDR  0x00000000
#define x_DATA_BASE_ADDR  0x00040000
#define x_DATA_MEM_SZ     0x00020000
#define x_SDRAM_BASE_ADDR 0x04000000
#define x_SDRAM_MEM_SZ    0x02000000
#define x_IO_BASE_ADDR    0x3c000000
#define x_IO_MEM_SZ       0x00002000
#define x_IO_ADDR_RANGE   0x00000020
#define x_IO_ADDR_MASK   (0 - x_IO_ADDR_RANGE)


#define IO_PRINT_ADDR   x_IO_BASE_ADDR
#define IO_STDOUT_ADDR  (x_IO_BASE_ADDR + 1 * x_IO_ADDR_RANGE)
#define IO_STDIN_ADDR   (x_IO_BASE_ADDR + 2 * x_IO_ADDR_RANGE)
#define IO_READ_ADDR    (x_IO_BASE_ADDR + 3 * x_IO_ADDR_RANGE)
#define IO_WRITE_ADDR   (x_IO_BASE_ADDR + 4 * x_IO_ADDR_RANGE)
#define IO_COUNT_ADDR   (x_IO_BASE_ADDR + 5 * x_IO_ADDR_RANGE)
#define IO_FPU_ADDR     (x_IO_BASE_ADDR + 6 * x_IO_ADDR_RANGE)
#define IO_UART_ADDR    (x_IO_BASE_ADDR + 7 * x_IO_ADDR_RANGE)
#define IO_STATS_ADDR   (x_IO_BASE_ADDR + 8 * x_IO_ADDR_RANGE)
#define IO_DSP7SEG_ADDR (x_IO_BASE_ADDR + 9 * x_IO_ADDR_RANGE)
#define IO_KEYBD_ADDR   (x_IO_BASE_ADDR +10 * x_IO_ADDR_RANGE)
#define IO_LCD_ADDR     (x_IO_BASE_ADDR +11 * x_IO_ADDR_RANGE)
#define IO_SDC_ADDR     (x_IO_BASE_ADDR +12 * x_IO_ADDR_RANGE)
#define IO_DMA_ADDR     (x_IO_BASE_ADDR +13 * x_IO_ADDR_RANGE)


extern void exit(int);
extern void halt(void);
extern void exception_report(int, int, int, int);

extern void cmips_delay(int);
extern void delay_cycle(int);
extern void delay_us(int);
extern void delay_ms(int);

extern void enableInterr(void);
extern void disableInterr(void);

extern void print(int);
extern void to_stdout(char c);
extern int  from_stdin(void);

extern void writeInt(int);
extern void writeClose(void);
extern int  readInt(int*);
extern void dumpRAM(void);
extern int  print_sp(void);
extern int  print_status(void);
extern int  print_cause(void);

extern char *memcpy(char*, const char*, int);
extern char *memset(char*, const int, int);

// external counter (peripheral)
extern void startCounter(int, int);
extern void stopCounter(void);
extern int  readCounter(void);

// internal counter, CP0 register COUNT
extern int startCount(void);
extern int stopCount(void);
extern int readCount(void);

// LCD display (Macnica board)
#define LCDprint(n) LCDint((n))
extern void LCDinit(void);
extern int  LCDprobe(void); 
extern int  LCDset(int);
extern int  LCDput(int);
extern void LCDclr(void);
extern void LCDtopLine(void);
extern void LCDbotLine(void);
extern void LCDgotoxy(int, int);
extern void LCDputc(char);
extern void LCDint(unsigned int);
extern void LCDshort(unsigned short);
extern void LCDbyte(unsigned char);

// 7-segment display and keyboard (Macnica board)
extern void DSP7SEGput(int, int, int, int, int);
extern int  KBDget(void);
extern int  SWget(void);

// RGB led color for DSP7SEGput (color must be in [0,7]
#define l_RED   0x4
#define l_GREEN 0x2
#define l_BLUE  0x1


#if 0
// struct to access the cache system statistics "peripheral"
typedef struct sStats {
  int dc_ref;      // data cache references
  int dc_rd_hit;   // data cache read-hits
  int dc_wr_hit;   // data cache write-hits
  int dc_flush;    // data cache (write-back) flushes of dirty blocks
  int ic_ref;      // instruction cache references
  int ic_hit;      // instruction cache hits
} sStats;

extern void readStats(sStats *);
#endif

#define FALSE (0==1)
#define TRUE  (0==0)
