
typedef struct control { // control register fields (uses only ls byte)
  unsigned int ign : 24, // ignore uppermost 3 bytes
    rts     : 1,         // Request to Send output (bit 7)
    ign2    : 2,         // bits 6,5 ignored
    intTX   : 1,         // interrupt on TX buffer empty (bit 4)
    intRX   : 1,         // interrupt on RX buffer full (bit 3)
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
    overun  : 1;         // overun error (bit 0)
} Tstatus;

typedef struct interr  { // interrupt clear bits (uses only ls byte)
  unsigned int ign : 24, // ignore uppermost 3 bytes
    ign3m   : 3,         // bits 7,6,5 ignored
    clrTX   : 1,         // interrupt on TX buffer empty (bit 4)
    clrRX   : 1,         // interrupt on RX buffer full (bit 3)
    ign3l   : 3;         // bits 2,1,0 ignored
} Tinterr;

typedef struct serial {
  Tcontrol  ctl;        // read-write,  address is (int *)IO_UART_ADDR
  Tstatus   stat;       // read-only,   address is (int *)(IO_UART_ADDR+1)
  Tinterr   interr;     // write-only,  address is (int *)(IO_UART_ADDR+2)
  int       data;       // read-write,  address is (int *)(IO_UART_ADDR+3)
} Tserial;


#define EOT 0x04   // End Of Transmission character
