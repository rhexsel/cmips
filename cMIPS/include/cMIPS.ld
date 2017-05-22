OUTPUT_ARCH(mips)
ENTRY(_start)

MEMORY
{
        rom (rx)  : ORIGIN = 0x00000000, /* x_INST_BASE_ADDR */
                    LENGTH = 0x00004000, /* x_INST_MEM_SZ */
        ram (!rx) : ORIGIN = 0x00040000, /* x_DATA_BASE_ADDR */
                    LENGTH = 0x00020000, /* x_DATA_MEM_SZ */
        sdram (!rx) : ORIGIN = 0x04000000, /* x_SDRAM_BASE_ADDR */
                      LENGTH = 0x02000000, /* x_SDRAM_MEM_SZ */
        io (!rx)  : ORIGIN = 0x3c000000, /* not used by LD, do not remove */
                    LENGTH = 0x00020000  /* edMemory.sh needs thess lines */
}

SECTIONS
{
       .text :
       {
          *(.text .text.*)
          _etext = . ;         /* end of text constant (from Xinu) */
       }                                   > rom

       .data : 
       {
          _bdata = . ;         /* begin of data constant */
          *(.data .data.*) 
          _edata = . ;         /* end of data constant  (from Xinu) */
       }                                   > ram
       .data1   : { *(.data1) }            > ram
       .lit8    : { *(.lit8) }             > ram
       .lit4    : { *(.lit4) }             > ram
       .sdata   : { *(.sdata .sdata.*) }   > ram
       .sbss    : { *(.sbss .sbss.*) *(.scommon .scommon.*) }  > ram
       .bss :
       {
          *(.bss .bss.*) *(COMMON) 
       }                                   > ram
       .rodata1 : { *(.rodata1) }          > ram  
       .rodata : 
       { 
          *(.rodata .rodata.*) 
          _end = . ;           /* end of image constant  (from Xinu) */
       }                                   > ram
  
       start_RAM = 0x00040000; /* x_DATA_BASE_ADDR */
       end_RAM = 0x00020000; /* x_DATA_MEM_SZ */
       half_RAM = (end_RAM >> 1);
       base_PT = ( start_RAM + half_RAM );
       .PT base_PT : { *(.PT) }            > ram
}

