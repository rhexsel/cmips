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
use work.p_WIRES.all;

package p_EXCEPTION is
  
  type exception_type is (exNOP,
                          exMTC0, exMFC0,  -- 2
                          exERET,       -- 3
                          exEI,exDI,    -- 5
                          exBREAK, exTRAP, exSYSCALL,  -- 8
                          exRESV_INSTR, exWAIT,  -- 10
                          IFaddressError,MMaddressErrorLD,MMaddressErrorST,--13
                          exTLBrefillIF, exTLBrefillRD, exTLBrefillWR,  -- 16
                          exTLBdblFaultIF,exTLBdblFaultRD,exTLBdblFaultWR,-- 19
                          exTLBinvalIF, exTLBinvalRD, exTLBinvalWR,  -- 22
                          exTLBmod, exOvfl,  -- 24
                          exLL,exSC,    -- 25,26  instrns handled by COP0
                          exEHB,        -- 27
                          exTLBP, exTLBR, exTLBWI, exTLBWR,  -- 31
                          exDERET,  -- 32
                          exIBE, exDBE,  -- 34
                          exNMI, exInterr,  -- 36
                          invalid_exception);

  attribute enum_encoding of exception_type : type is
    "000000 000001 000010 000011 000100 000101 000110 000111    001000 001001 001010 001011 001100 001101 001110 001111    010000 010001 010010 010011 010100 010101 010110 010111    011000 011001 011010 011011 011100 011101 011110 011111    100000 100001 100010 100011 100100 100101";  --   100110";

  
  -- Table 8-25 Cause Register ExcCode Field, pg 95
  constant cop0code_Int  : reg5 := b"00000";  --  0, interrupt=00 (CAUSE lsB)
  constant cop0code_Mod  : reg5 := b"00001";  --  1, TLBmodified=x04
  constant cop0code_TLBL : reg5 := b"00010";  --  2, TLBload if/ld=x08
  constant cop0code_TLBS : reg5 := b"00011";  --  3, TLBstore if/ld=x0c
  constant cop0code_AdEL : reg5 := b"00100";  --  4, AddrError if/ld=x10
  constant cop0code_AdES : reg5 := b"00101";  --  5, AddrError store=x14
  constant cop0code_IBE  : reg5 := b"00110";  --  6, BusErrorExcp if=x18
  constant cop0code_DBE  : reg5 := b"00111";  --  7, BusErrorExcp ld/st=x1c
  constant cop0code_Sys  : reg5 := b"01000";  --  8, syscall=x20
  constant cop0code_Bp   : reg5 := b"01001";  --  9, breakpoint=x24
  constant cop0code_RI   : reg5 := b"01010";  -- 10, reserved instruction=x28
  constant cop0code_CpU  : reg5 := b"01011";  -- 11, CopUnusable excp=x2c
  constant cop0code_Ov   : reg5 := b"01100";  -- 12, arithmetic overflow=x30
  constant cop0code_Tr   : reg5 := b"01101";  -- 13, trap=x34
  constant cop0code_NULL : reg5 := b"11111";  -- 1f, (no exception)=x3c


  -- Table 8-1 Coprocessor 0 Registers, pg 55
  constant cop0reg_Index    : reg5 := b"00000";  -- 0
  constant cop0reg_Random   : reg5 := b"00001";  -- 1
  constant cop0reg_EntryLo0 : reg5 := b"00010";  -- 2
  constant cop0reg_EntryLo1 : reg5 := b"00011";  -- 3
  constant cop0reg_Context  : reg5 := b"00100";  -- 4
  constant cop0reg_PageMask : reg5 := b"00101";  -- 5
  constant cop0reg_Wired    : reg5 := b"00110";  -- 6
  constant cop0reg_HWREna   : reg5 := b"00111";  -- 7
  constant cop0reg_BadVAddr : reg5 := b"01000";  -- 8
  constant cop0reg_COUNT    : reg5 := b"01001";  -- 9
  constant cop0reg_EntryHi  : reg5 := b"01010";  -- 10
  constant cop0reg_COMPARE  : reg5 := b"01011";  -- 11
  constant cop0reg_STATUS   : reg5 := b"01100";  -- 12
  constant cop0reg_CAUSE    : reg5 := b"01101";  -- 13
  constant cop0reg_EPC      : reg5 := b"01110";  -- 14
  constant cop0reg_CONFIG   : reg5 := b"10000";  -- 16
  constant cop0reg_LLAddr   : reg5 := b"10001";  -- 17
  constant cop0reg_ErrorPC  : reg5 := b"11110";  -- 30
  

  -- at exception level, kernel mode, cop0, all else disabled
  constant RESET_STATUS: std_logic_vector(31 downto 0) := x"10000002";

  -- COUNTER disabled, special interr vector, exceptionCode = noException
  constant RESET_CAUSE:  std_logic_vector(31 downto 0) := x"0880007c";


  -- Table 8-19 Status Register Field Descriptions, pg 79
  constant STATUS_CU3:  integer := 31;	-- COP-1 absent=0 (always)
  constant STATUS_CU2:  integer := 30;	-- COP-1 absent=0 (always)
  constant STATUS_CU1:  integer := 29;	-- COP-1 absent=0 (always)
  constant STATUS_CU0:  integer := 28;	-- COP-0 present=1 (always)
  constant STATUS_RP:   integer := 27;	-- reduced power=0 (always)  
  constant STATUS_BEV:  integer := 22;	-- locationVect at bootstrap=1
  constant STATUS_TS:   integer := 21;	-- TLBmatchesSeveral=1
  constant STATUS_SR:   integer := 20;	-- softReset=1
  constant STATUS_NMI:  integer := 19;	-- reset/softReset=0, NMI=1
  constant STATUS_IM7:  integer := 15;	-- hw interrupt-7 req eabled=1
  constant STATUS_IM6:  integer := 14;	-- hw interrupt-6 req eabled=1
  constant STATUS_IM5:  integer := 13;	-- hw interrupt-5 req eabled=1
  constant STATUS_IM4:  integer := 12;	-- hw interrupt-4 req eabled=1
  constant STATUS_IM3:  integer := 11;	-- hw interrupt-3 req eabled=1
  constant STATUS_IM2:  integer := 10;	-- hw interrupt-2 req eabled=1
  constant STATUS_IM1:  integer := 9;	-- sw interrupt-1 req eabled=1
  constant STATUS_IM0:  integer := 8;	-- sw interrupt-0 req eabled=1
  constant STATUS_SUP:  integer := 4;	-- in supervisor mode=1 (not used)
  constant STATUS_UM:   integer := 3;	-- in user mode=1
  constant STATUS_ERL:  integer := 2;	-- at error level=1
  constant STATUS_EXL:  integer := 1;	-- at exception level=1
  constant STATUS_IE:   integer := 0;	-- interrupt enabled=1


  -- Table 8-24 Cause Register Field Descriptions, pg 92
  constant CAUSE_BD:   integer := 31;	-- exceptn in branch-delay-slot=1
  constant CAUSE_TI:   integer := 30;	-- timer interrupt pending=1
  constant CAUSE_CE1:  integer := 29;	-- COP # in COP-UnusableExcp
  constant CAUSE_CE0:  integer := 28;	-- COP # in COP-UnusableExcp
  constant CAUSE_DC:   integer := 27;	-- COUNT reg is disabled=1
  constant CAUSE_PCI:  integer := 26;	-- perfCounter interr pndng=1
  constant CAUSE_IV:   integer := 23;	-- use special interrVector=1
  constant CAUSE_WP:   integer := 22;	-- watch deferred=1 (not used)
  constant CAUSE_IP7:  integer := 15;	-- hw interrupt-7 pending=1
  constant CAUSE_IP6:  integer := 14;	-- hw interrupt-6 pending=1
  constant CAUSE_IP5:  integer := 13;	-- hw interrupt-5 pending=1
  constant CAUSE_IP4:  integer := 12;	-- hw interrupt-4 pending=1
  constant CAUSE_IP3:  integer := 11;	-- hw interrupt-3 pending=1
  constant CAUSE_IP2:  integer := 10;	-- hw interrupt-2 pending=1
  constant CAUSE_IP1:  integer := 9;	-- sw interrupt-1 pending=1
  constant CAUSE_IP0:  integer := 8;	-- sw interrupt-0 pending=1
  constant CAUSE_ExcCodehi: integer := 6;      -- exception code
  constant CAUSE_ExcCodelo: integer := 2;      -- exception code

  -- Sources of Exception Handler's addresses; signal  excp_PCsel  
  constant PCsel_EXC_none : reg3 := b"000";  -- no exception
  constant PCsel_EXC_EPC  : reg3 := b"001";  -- ERET
  constant PCsel_EXC_0000 : reg3 := b"010";  -- TLBmiss entry point
  constant PCsel_EXC_0100 : reg3 := b"011";  -- Cache Error
  constant PCsel_EXC_0180 : reg3 := b"100";  -- general exception handler
  constant PCsel_EXC_0200 : reg3 := b"101";  -- separate interrupt handler
  constant PCsel_EXC_BFC0 : reg3 := b"110";  -- NMI or soft-reset handler
  
  -- Sources for EPC; signal  EPC_source
  constant EPC_src_PC  : reg3 := b"000"; -- from PC
  constant EPC_src_RF  : reg3 := b"001"; -- from RF pipestage
  constant EPC_src_EX  : reg3 := b"010"; -- from EX pipestage
  constant EPC_src_MM  : reg3 := b"011"; -- from MM pipestage
  constant EPC_src_WB  : reg3 := b"100"; -- from WB pipestage
  constant EPC_src_B   : reg3 := b"101"; -- from B register

  
end p_EXCEPTION;

-- package body p_EXCEPTION is
-- end p_EXCEPTION;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
