-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  cMIPS, a VHDL model of the classical five stage MIPS pipeline.
--  Copyright (C) 2013  Roberto Andre Hexsel
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, version 3.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

package p_MEMORY is

  -- To simplify (and accelerate) the RAM address decoding,
  --   the BASE of the RAM addresses MUST be allocated at an
  --   address which is at a different power of two than the ROM base.
  --   Otherwise, the base must be subtracted from the address on every
  --   reference, which means having an adder in the critical path.
  --   Not good at all.

  -- The address ranges for ROM, RAM and I/O must be distinct in the
  --   uppermost 16 bits of the address (bits 31..16).
  constant HI_SEL_BITS : integer := 31;
  constant LO_SEL_BITS : integer := 16;


  -- x_IO_ADDR_RANGE can have only ONE bit set, thus being a power of 2.
  -- ACHTUNG: changing that definition may break some of the test programs.  
  
  -- begin DO NOT change these names as several scripts depend on them --
  --  you may change the values, not names neither formatting          --
  constant x_INST_BASE_ADDR : reg32   := x"00000000";
  constant x_INST_MEM_SZ    : reg32   := x"00002000";
  constant x_DATA_BASE_ADDR : reg32   := x"00010000";
  constant x_DATA_MEM_SZ    : reg32   := x"00002000";
  constant x_IO_BASE_ADDR   : reg32   := x"3c000000";
  constant x_IO_MEM_SZ      : reg32   := x"00002000";
  constant x_IO_ADDR_RANGE  : reg32   := x"00000020";
  constant x_SDRAM_BASE_ADDR : reg32  := x"04000000";
  constant x_SDRAM_MEM_SZ    : reg32  := x"02000000";
  constant x_EXCEPTION_0000 : reg32   := x"00000130";  -- TLBrefill
  constant x_EXCEPTION_0100 : reg32   := x"00000200";  -- CacheError
  constant x_EXCEPTION_0180 : reg32   := x"00000280";  -- generalExcpHandler
  constant x_EXCEPTION_0200 : reg32   := x"00000400";  -- separInterrHandler
  constant x_EXCEPTION_BFC0 : reg32   := x"000004E0";  -- NMI, soft-reset
  constant x_ENTRY_POINT    : reg32   := x"00000500";  -- main()
  -- end DO NOT change these names --


  constant INST_BASE_ADDR  : integer := to_integer(signed(x_INST_BASE_ADDR));
  constant INST_MEM_SZ     : integer := to_integer(signed(x_INST_MEM_SZ));
  constant INST_ADDRS_BITS : natural := log2_ceil(INST_MEM_SZ);

  constant DATA_BASE_ADDR  : integer := to_integer(signed(x_DATA_BASE_ADDR));
  constant DATA_MEM_SZ     : integer := to_integer(signed(x_DATA_MEM_SZ));

  constant SDRAM_BASE_ADDR  : integer := to_integer(signed(x_SDRAM_BASE_ADDR));
  constant SDRAM_MEM_SZ     : integer := to_integer(signed(x_SDRAM_MEM_SZ));

  constant IO_BASE_ADDR    : integer := to_integer(signed(x_IO_BASE_ADDR));
  constant IO_MEM_SZ       : integer := to_integer(signed(x_IO_MEM_SZ));
  constant IO_ADDR_RANGE   : integer := to_integer(signed(x_IO_ADDR_RANGE));

  -- maximum number of IO devices, must be a power of two.
  constant IO_MAX_NUM_DEVS : integer := 16;

  constant IO_ADDR_BITS : integer := log2_ceil(IO_MAX_NUM_DEVS * IO_ADDR_RANGE);
  
  -- I/O addresses are IO_ADDR_RANGE apart 
  constant IO_PRINT_ADDR   : integer := IO_BASE_ADDR;
  constant IO_STDOUT_ADDR  : integer := IO_BASE_ADDR + 1*IO_ADDR_RANGE;
  constant IO_STDIN_ADDR   : integer := IO_BASE_ADDR + 2*IO_ADDR_RANGE;
  constant IO_READ_ADDR    : integer := IO_BASE_ADDR + 3*IO_ADDR_RANGE;
  constant IO_WRITE_ADDR   : integer := IO_BASE_ADDR + 4*IO_ADDR_RANGE;
  constant IO_COUNT_ADDR   : integer := IO_BASE_ADDR + 5*IO_ADDR_RANGE;
  constant IO_FPU_ADDR     : integer := IO_BASE_ADDR + 6*IO_ADDR_RANGE;
  constant IO_UART_ADDR    : integer := IO_BASE_ADDR + 7*IO_ADDR_RANGE;
  constant IO_STATS_ADDR   : integer := IO_BASE_ADDR + 8*IO_ADDR_RANGE;
  constant IO_DSP7SEG_ADDR : integer := IO_BASE_ADDR + 9*IO_ADDR_RANGE;
  constant IO_KEYBD_ADDR   : integer := IO_BASE_ADDR + 10*IO_ADDR_RANGE;
  constant IO_LCD_ADDR     : integer := IO_BASE_ADDR + 11*IO_ADDR_RANGE;
  constant IO_SDC_ADDR     : integer := IO_BASE_ADDR + 12*IO_ADDR_RANGE;
  constant IO_HIGHEST_ADDR : integer :=
    IO_BASE_ADDR + (IO_MAX_NUM_DEVS - 1)*IO_ADDR_RANGE;


  -- DATA CACHE parameters ================================================
  
  -- The combination of capacity, associativity and block/line size
  --  MUST be such that DC_INDEX_BITS >= 6 (64 sets/way)
  constant DC_TOTAL_CAPACITY  : natural := 2*1024;
  constant DC_NUM_WAYS        : natural := 1;  -- direct mapped
  constant DC_VIA_CAPACITY    : natural := DC_TOTAL_CAPACITY / DC_NUM_WAYS;
  constant DC_BTS_PER_WORD    : natural := 32;
  constant DC_BYTES_PER_WORD  : natural := 4;
  constant DC_WORDS_PER_BLOCK : natural := 4;
  constant DC_NUM_WORDS       : natural := DC_VIA_CAPACITY / DC_BYTES_PER_WORD;
  constant DC_NUM_BLOCKS      : natural := DC_NUM_WORDS / DC_WORDS_PER_BLOCK;
  constant DC_INDEX_BITS      : natural := log2_ceil( DC_NUM_BLOCKS );
  constant DC_WORD_SEL_BITS   : natural := log2_ceil( DC_WORDS_PER_BLOCK );
  constant DC_BYTE_SEL_BITS   : natural := log2_ceil( DC_BYTES_PER_WORD );

  -- constants for CONFIG1 cop0 register (Table 8-24 pg 103)
  constant DC_SETS_PER_WAY: reg3 :=
    std_logic_vector(to_signed(DC_INDEX_BITS - 6, 3));
  constant DC_LINE_SIZE: reg3 :=
    std_logic_vector(to_signed(DC_WORD_SEL_BITS + 1, 3));
  constant DC_ASSOCIATIVITY: reg3 :=
    std_logic_vector(to_signed(DC_NUM_WAYS - 1, 3));

  
  -- INSTRUCTION CACHE parameters =========================================

  -- The combination of capacity, associativity and block/line size
  --  MUST be such that IC_INDEX_BITS >= 6 (64 sets/via)
  constant IC_TOTAL_CAPACITY  : natural := 1024; -- 2*1024;
  constant IC_NUM_WAYS        : natural := 1;  -- direct mapped
  constant IC_VIA_CAPACITY    : natural := IC_TOTAL_CAPACITY / IC_NUM_WAYS;
  constant IC_BTS_PER_WORD    : natural := 32;
  constant IC_BYTES_PER_WORD  : natural := 4;
  constant IC_WORDS_PER_BLOCK : natural := 4;
  constant IC_NUM_WORDS       : natural := IC_VIA_CAPACITY / IC_BYTES_PER_WORD;
  constant IC_NUM_BLOCKS      : natural := IC_NUM_WORDS / IC_WORDS_PER_BLOCK;
  constant IC_INDEX_BITS      : natural := log2_ceil( IC_NUM_BLOCKS );
  constant IC_WORD_SEL_BITS   : natural := log2_ceil( IC_WORDS_PER_BLOCK );
  constant IC_BYTE_SEL_BITS   : natural := log2_ceil( IC_BYTES_PER_WORD );

  -- constants for CONFIG1 cop0 register (Table 8-24 pg 103)
  constant IC_SETS_PER_WAY: reg3 :=
    std_logic_vector(to_signed(IC_INDEX_BITS - 6, 3));
  constant IC_LINE_SIZE: reg3 :=
    std_logic_vector(to_signed(IC_WORD_SEL_BITS + 1, 3));
  constant IC_ASSOCIATIVITY: reg3 :=
    std_logic_vector(to_signed(IC_NUM_WAYS - 1, 3));

  -- constants to access the cache statistics counters
  constant dcache_Stats_ref   : reg3 := "000";
  constant dcache_Stats_rdhit : reg3 := "001";
  constant dcache_Stats_wrhit : reg3 := "010";
  constant dcache_Stats_flush : reg3 := "011";
  constant icache_Stats_ref   : reg3 := "100";
  constant icache_Stats_hit   : reg3 := "101";

  
  -- MMU parameters ========================================================

  -- constants for CONFIG1 cop0 register (Table 8-24 pg 103)
  constant MMU_CAPACITY : natural := 8;
  constant MMU_CAPACITY_BITS : natural := log2_ceil( MMU_CAPACITY );
  constant MMU_SIZE: reg6 := 
    std_logic_vector(to_signed( (MMU_CAPACITY-1), 6) );
  constant MMU_WIRED_INIT : reg32 := x"00000000";
  
  constant VABITS       : natural := 32;
  constant PABITS       : natural := 32;
  constant PAGE_SZ      : natural := 4096;              -- 4k pages
  constant PAGE_SZ_BITS : natural := log2_ceil( PAGE_SZ );

  constant PPN_BITS     : natural := PABITS - PAGE_SZ_BITS;
  constant VA_HI_BIT    : natural := 31; -- VAaddr in EntryHi 31..PG_size
  constant VA_LO_BIT    : natural := PAGE_SZ_BITS + 1;  -- maps 2 phy-pages

  constant ASID_HI_BIT  : natural := 7;  -- ASID   in EntryHi 7..0
  constant ASID_LO_BIT  : natural := 0;

  constant EHI_ASIDLO_BIT : natural := 0;
  constant EHI_ASIDHI_BIT : natural := 7;
  constant EHI_G_BIT    : natural := 8;
  constant EHI_ALO_BIT  : natural := PAGE_SZ_BITS + 1;  -- maps 2 phy-pages
  constant EHI_AHI_BIT  : natural := 31;
  constant EHI_ZEROS    : std_logic_vector(PAGE_SZ_BITS-EHI_G_BIT-1 downto 0) := (others => '0');    
  
  constant TAG_ASIDLO_BIT : natural := 0;
  constant TAG_ASIDHI_BIT : natural := 7;
  constant TAG_G_BIT    : natural := 8;
  constant TAG_Z_BIT    : natural := 9;
  constant TAG_ALO_BIT  : natural := PAGE_SZ_BITS + 1;  -- maps 2 phy-pages
  constant TAG_AHI_BIT  : natural := 31;
  
  constant ELO_G_BIT    : natural := 0;
  constant ELO_V_BIT    : natural := 1;
  constant ELO_D_BIT    : natural := 2;
  constant ELO_CLO_BIT  : natural := 3;
  constant ELO_CHI_BIT  : natural := 5;  
  constant ELO_ALO_BIT  : natural := 6;
  constant ELO_AHI_BIT  : natural := ELO_ALO_BIT + PPN_BITS - 1;

  constant DAT_G_BIT    : natural := 0;
  constant DAT_V_BIT    : natural := 1;
  constant DAT_D_BIT    : natural := 2;
  constant DAT_CLO_BIT  : natural := 3;
  constant DAT_CHI_BIT  : natural := 5;  
  constant DAT_ALO_BIT  : natural := 6;
  constant DAT_AHI_BIT  : natural := DAT_ALO_BIT + PPN_BITS - 1;
  constant DAT_REG_BITS : natural := DAT_ALO_BIT + PPN_BITS;

  constant ContextPTE_init : reg9  := b"000000000";
  constant mmu_PageMask :    reg32 := x"00001800";  -- pg 68, 4k pages only
  
  subtype mmu_dat_reg is std_logic_vector (DAT_AHI_BIT downto 0);
  
  subtype  MMU_idx_bits is std_logic_vector(MMU_CAPACITY_BITS-1 downto 0);
  constant MMU_idx_0s : std_logic_vector(30 downto MMU_CAPACITY_BITS) :=
    (others => '0');
  constant MMU_IDX_BIT : natural := 31;  -- probe hit=1, miss=0

  -- VA tags map a pair of PHY pages, thus VAddr is 1 bit less than (VABITS-1..PAGE_SZ_BITS)
  constant tag_zeros : std_logic_vector(PAGE_SZ_BITS downto 0) := (others => '0');
  constant tag_ones  : std_logic_vector(VABITS-1 downto PAGE_SZ_BITS+1) := (others => '1');
  constant tag_mask  : reg32 := tag_ones & tag_zeros;
  constant tag_g     : reg32 := x"00000100";


  -- physical addresses for 8 ROM pages
  
  constant x_ROM_PPN_0 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 0*PAGE_SZ, 32));
  constant x_ROM_PPN_1 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 1*PAGE_SZ, 32));
  constant x_ROM_PPN_2 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 2*PAGE_SZ, 32));
  constant x_ROM_PPN_3 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 3*PAGE_SZ, 32));
  constant x_ROM_PPN_4 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 4*PAGE_SZ, 32));
  constant x_ROM_PPN_5 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 5*PAGE_SZ, 32));
  constant x_ROM_PPN_6 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 6*PAGE_SZ, 32));
  constant x_ROM_PPN_7 : reg32 := std_logic_vector(to_signed(INST_BASE_ADDR + 7*PAGE_SZ, 32));

  constant MMU_ini_tag_ROM0 : reg32 := (x_ROM_PPN_0 and tag_mask) or tag_g;
  constant MMU_ini_dat_ROM0 : mmu_dat_reg := 
   x_ROM_PPN_0(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_ROM1 : mmu_dat_reg := 
   x_ROM_PPN_1(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_ROM2 : reg32 := (x_ROM_PPN_2 and tag_mask) or tag_g;
  constant MMU_ini_dat_ROM2 : mmu_dat_reg := 
   x_ROM_PPN_2(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_ROM3 : mmu_dat_reg := 
   x_ROM_PPN_3(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_ROM4 : reg32 := (x_ROM_PPN_4 and tag_mask) or tag_g;
  constant MMU_ini_dat_ROM4 : mmu_dat_reg := 
   x_ROM_PPN_4(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_ROM5 : mmu_dat_reg := 
   x_ROM_PPN_5(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_ROM6 : reg32 := (x_ROM_PPN_6 and tag_mask) or tag_g;
  constant MMU_ini_dat_ROM6 : mmu_dat_reg := 
   x_ROM_PPN_6(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_ROM7 : mmu_dat_reg := 
   x_ROM_PPN_7(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1


  -- physical addresses for 8 RAM pages
  
  constant x_RAM_PPN_0 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 0*PAGE_SZ, 32));
  constant x_RAM_PPN_1 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 1*PAGE_SZ, 32));
  constant x_RAM_PPN_2 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 2*PAGE_SZ, 32));
  constant x_RAM_PPN_3 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 3*PAGE_SZ, 32));
  constant x_RAM_PPN_4 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 4*PAGE_SZ, 32));
  constant x_RAM_PPN_5 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 5*PAGE_SZ, 32));
  constant x_RAM_PPN_6 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 6*PAGE_SZ, 32));
  constant x_RAM_PPN_7 : reg32 := std_logic_vector(to_signed(DATA_BASE_ADDR + 7*PAGE_SZ, 32));
  
  constant MMU_ini_tag_RAM0 : reg32 := (x_RAM_PPN_0 and tag_mask) or tag_g;
  constant MMU_ini_dat_RAM0 : mmu_dat_reg := 
   x_RAM_PPN_0(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_RAM1 : mmu_dat_reg := 
   x_RAM_PPN_1(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_RAM2 : reg32 := (x_RAM_PPN_2 and tag_mask) or tag_g;
  constant MMU_ini_dat_RAM2 : mmu_dat_reg := 
   x_RAM_PPN_2(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_RAM3 : mmu_dat_reg := 
   x_RAM_PPN_3(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_RAM4 : reg32 := (x_RAM_PPN_4 and tag_mask) or tag_g;
  constant MMU_ini_dat_RAM4 : mmu_dat_reg := 
   x_RAM_PPN_4(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_RAM5 : mmu_dat_reg := 
   x_RAM_PPN_5(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_RAM6 : reg32 := (x_RAM_PPN_6 and tag_mask) or tag_g;
  constant MMU_ini_dat_RAM6 : mmu_dat_reg := 
   x_RAM_PPN_6(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_RAM7 : mmu_dat_reg := 
   x_RAM_PPN_7(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1


  -- physical addresses for 2 pages reserved for I/O devices
  
  constant x_IO_PPN_0 : reg32 := std_logic_vector(to_signed(IO_BASE_ADDR + 0*PAGE_SZ, 32));
  constant x_IO_PPN_1 : reg32 := std_logic_vector(to_signed(IO_BASE_ADDR + 1*PAGE_SZ, 32));

  constant MMU_ini_tag_IO : reg32 := (x_IO_BASE_ADDR and tag_mask) or tag_g;
  constant MMU_ini_dat_IO0 : mmu_dat_reg := 
   x_IO_PPN_0(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_IO1 : mmu_dat_reg := 
   x_IO_PPN_1(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1


  -- physical addresses for 8 SDRAM pages
  
  constant x_SDRAM_PPN_0 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 0*PAGE_SZ, 32));
  constant x_SDRAM_PPN_1 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 1*PAGE_SZ, 32));
  constant x_SDRAM_PPN_2 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 2*PAGE_SZ, 32));
  constant x_SDRAM_PPN_3 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 3*PAGE_SZ, 32));
  constant x_SDRAM_PPN_4 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 4*PAGE_SZ, 32));
  constant x_SDRAM_PPN_5 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 5*PAGE_SZ, 32));
  constant x_SDRAM_PPN_6 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 6*PAGE_SZ, 32));
  constant x_SDRAM_PPN_7 : reg32 := std_logic_vector(to_signed(SDRAM_BASE_ADDR + 7*PAGE_SZ, 32));
  
  constant MMU_ini_tag_SDR0 : reg32 := (x_SDRAM_PPN_0 and tag_mask) or tag_g;
  constant MMU_ini_dat_SDR0 : mmu_dat_reg := 
   x_SDRAM_PPN_0(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_SDR1 : mmu_dat_reg := 
   x_SDRAM_PPN_1(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_SDR2 : reg32 := (x_SDRAM_PPN_2 and tag_mask) or tag_g;
  constant MMU_ini_dat_SDR2 : mmu_dat_reg := 
   x_SDRAM_PPN_2(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_SDR3 : mmu_dat_reg := 
   x_SDRAM_PPN_3(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_SDR4 : reg32 := (x_SDRAM_PPN_4 and tag_mask) or tag_g;
  constant MMU_ini_dat_SDR4 : mmu_dat_reg := 
   x_SDRAM_PPN_4(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_SDR5 : mmu_dat_reg := 
   x_SDRAM_PPN_5(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  constant MMU_ini_tag_SDR6 : reg32 := (x_SDRAM_PPN_6 and tag_mask) or tag_g;
  constant MMU_ini_dat_SDR6 : mmu_dat_reg := 
   x_SDRAM_PPN_6(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1
  constant MMU_ini_dat_SDR7 : mmu_dat_reg := 
   x_SDRAM_PPN_7(PABITS-1 downto PAGE_SZ_BITS) & b"000111"; -- d,v,g=1

  
end p_MEMORY;

-- package body p_MEMORY is
-- end p_MEMORY;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
