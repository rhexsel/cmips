// ---------------------------------------------------------------------------
// Structures to program and access the serial interface
//
// See vhdl/io.vhd and vhdl/uart.vhd for details
// ---------------------------------------------------------------------------

typedef struct control { // control register fields (uses only ls byte)
  unsigned int ign : 24, // ignore uppermost 3 bytes
    rts     : 1,         // Request to Send output (bit 7)
    ign4    : 4,         // ignored (bits 6,5,4,3)
    speed   : 3;         // 4,8,16... {tx,rx}clock data rates  (bits 2,1,0)
} Tcontrol;


typedef struct status {  // status register fields (uses only ls byte)
  unsigned int ign : 24, // ignore uppermost 3 bytes
    cts     : 1,         // Clear To Send input=1 (bit 7)
    txEmpty : 1,         // TX register is empty (bit 6)
    rxFull  : 1,         // octet available from RX register (bit 5)
    int_TX_empt: 1,      // interrupt pending on TX empty (bit 4)
    int_RX_full: 1,      // interrupt pending on RX full (bit 3)
    ign1    : 1,         // ignored (bit 2)
    framing : 1,         // framing error (bit 1)
    overrun : 1;         // overrun error (bit 0)
} Tstatus;


// software MUST read this register before setting/clearing IRQs
//   otw, intRX + intTX bits will be reset.  Chaos, death and destruction.
typedef struct intreg { // interrupt register (uses only ls byte)
  unsigned int ign : 24, // ignore uppermost 3 bytes
    ignb    : 1,         // ignored (bit 7)
    setTX   : 1,         // set   IRQ on TX buffer empty (bit 6)
    setRX   : 1,         // set   IRQ on RX buffer full (bit 5)
    clrTX   : 1,         // clear IRQ on TX buffer empty (bit 4)
    clrRX   : 1,         // clear IRQ on RX buffer full (bit 3)
    igna    : 1,         // ignored (bit 2)
    intTX   : 1,         // program interrupt on TX buffer empty (bit 1)
    intRX   : 1;         // program interrupt on RX buffer full (bit 0)
} Tintreg;

typedef union interr {
  Tintreg      s;        // structure bits
  unsigned int i;        // integer
} Tinterr;

#define UART_INT_setTX  0x40
#define UART_INT_setRX  0x20
#define UART_INT_clrTX  0x10
#define UART_INT_clrRX  0x08
#define UART_INT_progTX 0x02
#define UART_INT_progRX 0x01


typedef struct serial {
  volatile       Tcontrol ctl;   // RD+WR,   at (int *)IO_UART_ADDR
  const volatile Tstatus  stat;  // RD only, at (int *)(IO_UART_ADDR+1)
  volatile       Tinterr interr; // Rd+WR    at (int *)(IO_UART_ADDR+2)
  volatile       int       data; // RD+WR,   at (int *)(IO_UART_ADDR+3)
} Tserial;


#define Q_SZ (1<<4)          //  16, MUST be a power of 2

// rx_tl and tx_hd are updated by the interrupt handler, hence volatile
// rx_q  is updated only by the handler, hence constant (RO) and volatile

typedef struct UARTdriver {
   int  volatile rx_hd;      // reception queue head index
   int  volatile rx_tl;      // reception queue tail index
   char const volatile rx_q[Q_SZ]; // reception queue, read-only (C code)
   int  volatile tx_hd;      // transmission queue head index
   int  volatile tx_tl;      // transmission queue tail index
   char          tx_q[Q_SZ]; // transmission queue, write-only
   int  volatile nrx;        // number of characters in rx_queue
   int  volatile ntx;        // number of spaces in tx_queue
} UARTdriver;


#define EOT 0x04        // End Of Transmission character


// convert small integer (i<16) to hexadecimal digit
static inline unsigned char i2c(int i) {
  return ( ((i) < 10) ? ((i)+'0') : (((i & 0x0f)+'a')-10) );
}

// convert hexadecimal digit to integer (i<16)
static inline unsigned int c2i(char c) {
  return ( ((c) <= '9') ? ((c)-'0') : (((c)-'a')+10) );
}

