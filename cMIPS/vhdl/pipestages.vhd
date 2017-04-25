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


-------------------------------------------------------------------------
-- Processor core pipeline registers
-------------------------------------------------------------------------


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- IF-RF
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;

entity reg_IF_RF is
  port(clk, rst, ld: in  std_logic;
       PCincd_d:     in  reg32;
       PCincd_q:     out reg32;
       instr:        in  reg32;
       RF_instr:     out reg32);
end reg_IF_RF;

architecture funcional of reg_IF_RF is
begin
  process(clk, rst)
  begin
    if rst = '0' then
      PCincd_q <= x"00000000";
      RF_instr <= x"00000000";
    elsif rising_edge(clk) then
      if ld = '0' then
        PCincd_q <= PCincd_d ;
        RF_instr <= instr    ;
      end if;
    end if;
  end process;
end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- RF-EX
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
entity reg_RF_EX is
  port(clk, rst, ld: in  std_logic;
       selB:       in  std_logic;
       EX_selB:    out std_logic;
       oper:       in  t_alu_fun;
       EX_oper:    out t_alu_fun;
       a_rs:       in  reg5;
       EX_a_rs:    out reg5;
       a_rt:       in  reg5;
       EX_a_rt:    out reg5;
       a_c:        in  reg5;
       EX_a_c:     out reg5;
       wreg:       in  std_logic;
       EX_wreg:    out std_logic;
       muxC:       in  reg3;
       EX_muxC:    out reg3;
       move:       in  std_logic;
       EX_move:    out std_logic;
       postn:      in  reg5;
       EX_postn:   out reg5;
       shamt:      in  reg5;
       EX_shamt:   out reg5;
       aVal:       in  std_logic;
       EX_aVal:    out std_logic;
       wrmem:      in  std_logic;
       EX_wrmem:   out std_logic;
       mem_t:      in  reg4;
       EX_mem_t:   out reg4;              
       is_load:    in  boolean;
       EX_is_load: out boolean;
       A:          in  reg32;
       EX_A:       out reg32;
       B:          in  reg32;
       EX_B:       out reg32;
       displ32:    in  reg32;
       EX_displ32: out reg32;
       pc_p8:      in  reg32;
       EX_pc_p8:   out reg32);
end reg_RF_EX;

architecture funcional of reg_RF_EX is
begin
  process(clk, rst)
  begin
    if rst = '0' then
      EX_wreg  <= '1';
      EX_wrmem <= '1';
      EX_aVal  <= '1';
    elsif rising_edge(clk) then
      if ld = '0' then
        EX_selB    <= selB    ;
        EX_oper    <= oper    ;
        EX_a_rs    <= a_rs    ;
        EX_a_rt    <= a_rt    ;
        EX_a_c     <= a_c     ;
        EX_wreg    <= wreg    ;
        EX_muxC    <= muxC    ;
        EX_move    <= move    ;
        EX_postn   <= postn   ;
        EX_shamt   <= shamt   ;
        EX_aVal    <= aVal    ;
        EX_wrmem   <= wrmem   ;
        EX_mem_t   <= mem_t   ;
        EX_is_load <= is_load ;
        EX_A       <= A       ;
        EX_B       <= B       ;
        EX_displ32 <= displ32 ;
        EX_pc_p8   <= pc_p8   ;
      end if;
    end if;
    end process;
end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- EX-MEM
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
entity reg_EX_MM is
  port(clk, rst, ld: in  std_logic;
       EX_a_rt:    in  reg5;
       MM_a_rt:    out reg5;
       EX_a_c:     in  reg5;
       MM_a_c:     out reg5;
       EX_wreg:    in  std_logic;
       MM_wreg:    out std_logic;
       EX_muxC:    in  reg3;
       MM_muxC:    out reg3;
       EX_aVal:    in  std_logic;
       MM_aVal:    out std_logic;
       EX_wrmem:   in  std_logic;
       MM_wrmem:   out std_logic;
       EX_mem_t:   in  reg4;
       MM_mem_t:   out reg4;              
       EX_is_load: in  boolean;
       MM_is_load: out boolean;
       EX_A:       in  reg32;
       MM_A:       out reg32;
       EX_B:       in  reg32;
       MM_B:       out reg32;
       EX_result:  in  reg32;
       MM_result:  out reg32;
       EX_addr:    in  reg32;
       MM_addr:    out reg32;
       HI:         in  reg32;
       MM_HI:      out reg32;
       LO:         in  reg32;
       MM_LO:      out reg32;
       EX_alu_move_ok: in  std_logic;
       MM_alu_move_ok: out std_logic;
       EX_move:    in  std_logic;
       MM_move:    out std_logic;
       EX_pc_p8:   in  reg32;
       MM_pc_p8:   out reg32);
end reg_EX_MM;

architecture funcional of reg_EX_MM is
begin
  process(clk, rst)
  begin
    if rst = '0' then
      MM_wreg  <= '1';
      MM_wrmem <= '1';
      MM_aVal  <= '1';
    elsif rising_edge(clk) then
      if ld = '0' then
        MM_a_rt     <= EX_a_rt    ;
        MM_a_c      <= EX_a_c     ;
        MM_wreg     <= EX_wreg    ;
        MM_muxC     <= EX_muxC    ;
        MM_aVal     <= EX_aVal    ;
        MM_wrmem    <= EX_wrmem   ;
        MM_mem_t    <= EX_mem_t   ;
        MM_is_load  <= EX_is_load ;
        MM_A        <= EX_A       ;
        MM_B        <= EX_B       ;
        MM_result   <= EX_result  ;
        MM_addr     <= EX_addr    ;
        MM_HI       <= HI         ;
        MM_LO       <= LO         ;
        MM_alu_move_ok <= EX_alu_move_ok ;
        MM_move     <= EX_move    ;        
        MM_pc_p8    <= EX_pc_p8   ;
      end if;
    end if;
  end process;
end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- MEM-WB
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
entity reg_MM_WB is
  port(clk, rst, ld: in  std_logic;
       MM_a_c:     in  reg5;
       WB_a_c:     out reg5;
       MM_wreg:    in  std_logic;
       WB_wreg:    out std_logic;
       MM_muxC:    in  reg3;
       WB_muxC:    out reg3;
       MM_A:       in  reg32;
       WB_A:       out reg32;
       MM_result:  in  reg32;
       WB_result:  out reg32;
       MM_HI:      in  reg32;
       WB_HI:      out reg32;
       MM_LO:      in  reg32;
       WB_LO:      out reg32;
       rd_data:    in  reg32;
       WB_rd_data: out reg32;
       MM_B_data:  in  reg32;
       WB_B_data:  out reg32;
       MM_addr2:   in  reg2;
       WB_addr2:   out reg2;
       MM_oper:    in  reg2;
       WB_oper:    out reg2;
       MM_pc_p8:   in  reg32;
       WB_pc_p8:   out reg32);
end reg_MM_WB;

architecture funcional of reg_MM_WB is
begin
  process(clk, rst)
  begin
    if rst = '0' then
      WB_wreg  <= '1';
    elsif rising_edge(clk) then
      if ld = '0' then
        WB_a_c     <= MM_a_c    ;
        WB_wreg    <= MM_wreg   ;
        WB_muxC    <= MM_muxC   ;
        WB_A       <= MM_A      ;
        WB_result  <= MM_result ;
        WB_HI      <= MM_HI     ;
        WB_LO      <= MM_LO     ;
        WB_rd_data <= rd_data   ;
        WB_B_data  <= MM_B_data ;
        WB_addr2   <= MM_addr2  ;
        WB_oper    <= MM_oper   ;
        WB_pc_p8   <= MM_pc_p8  ;
      end if;
    end if;
  end process;

end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


