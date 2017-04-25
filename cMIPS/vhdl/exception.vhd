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
-- Interrupt/exception pipeline registers
-------------------------------------------------------------------------


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- exception IF-RF
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
use work.p_EXCEPTION.all;
entity reg_excp_IF_RF is
  port(clk, rst, ld: in  std_logic;
       IF_excp_type: in  exception_type;
       RF_excp_type: out exception_type;
       PC_abort:     in  boolean;
       RF_PC_abort:  out boolean;
       IF_PC:        in  reg32;
       RF_PC:        out reg32);
end reg_excp_IF_RF;

architecture funcional of reg_excp_IF_RF is
begin
  process(clk, rst, ld)
  begin
    if rising_edge(clk) then
      if ld = '0' then
        RF_excp_type <= IF_excp_type ;
        RF_PC_abort  <= PC_abort     ;
        RF_PC        <= IF_PC        ;
      end if;
    end if;
  end process;
end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- exception RF-EX
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
use work.p_EXCEPTION.all;
entity reg_excp_RF_EX is
  port(clk, rst, ld: in  std_logic;
       RF_cop0_reg:     in  reg5;
       EX_cop0_reg:     out reg5;
       RF_cop0_sel:     in  reg3;
       EX_cop0_sel:     out reg3;
       RF_can_trap:     in  reg2;
       EX_can_trap:     out reg2;
       RF_exception:    in  exception_type;
       EX_exception:    out exception_type;
       RF_is_delayslot: in  std_logic;
       EX_is_delayslot: out std_logic;
       RF_PC_abort:     in  boolean;
       EX_PC_abort:     out boolean;
       RF_PC:           in  reg32;
       EX_PC:           out reg32;
       RF_trap_taken:   in  boolean;
       EX_trapped:      out boolean);
end reg_excp_RF_EX;

architecture funcional of reg_excp_RF_EX is
begin
  process(clk, rst, ld)
  begin
    if rst = '0' then
      EX_can_trap     <= b"00";
      EX_is_delayslot <= '0';
      EX_trapped      <= FALSE;
    elsif rising_edge(clk) then
      if ld = '0' then
        EX_cop0_reg     <= RF_cop0_reg     ;
        EX_cop0_sel     <= RF_cop0_sel     ;
        EX_can_trap     <= RF_can_trap     ;
        EX_exception    <= RF_exception    ;
        EX_is_delayslot <= RF_is_delayslot ;
        EX_PC_abort     <= RF_PC_abort     ;
        EX_PC           <= RF_PC           ;
        EX_trapped      <= RF_trap_taken   ;
      end if;
    end if;
  end process;
end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- exception EX-MEM
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
use work.p_EXCEPTION.all;
entity reg_excp_EX_MM is
  port(clk, rst, ld:  in  std_logic;
       EX_cop0_reg:   in  reg5;
       MM_cop0_reg:   out reg5;
       EX_cop0_sel:   in  reg3;
       MM_cop0_sel:   out reg3;
       EX_PC:         in  reg32;
       MM_PC:         out reg32;
       EX_v_addr:     in  reg32;
       MM_v_addr:     out reg32;
       EX_nullify:    in  boolean;
       MM_nullify:    out boolean;
       EX_addrError:  in  boolean;
       MM_addrError:  out boolean;
       EX_addrErr_stage_mm: in  boolean;
       MM_addrErr_stage_mm: out boolean;
       EX_is_delayslot:  in  std_logic;
       MM_is_delayslot:  out std_logic;
       EX_trapped:       in  boolean;
       MM_trapped:       out boolean;
       EX_ll_sc_abort:   in boolean;
       MM_ll_sc_abort:   out boolean;
       EX_tlb_exception: in  boolean;
       MM_tlb_exception: out boolean;
       EX_tlb_stage_mm:  in  boolean;
       MM_tlb_stage_mm:  out boolean;
       EX_int_req:       in  reg6;
       MM_int_req:       out reg6;
       EX_is_SC:         in  boolean;
       MM_is_SC:         out boolean;
       EX_is_MFC0:       in  boolean;
       MM_is_MFC0:       out boolean;
       EX_is_exception:  in  exception_type;
       MM_is_exception:  out exception_type);
end reg_excp_EX_MM;

architecture funcional of reg_excp_EX_MM is
begin
  process(clk, rst, ld)
  begin
    if rst = '0' then
      MM_trapped        <= FALSE;
      MM_nullify        <= FALSE;
      MM_addrError      <= FALSE;
      MM_trapped        <= FALSE;
      MM_tlb_exception  <= FALSE;
      MM_is_exception   <= exNOP;
    elsif rising_edge(clk) then
      if ld = '0' then
        MM_cop0_reg      <= EX_cop0_reg    ;
        MM_cop0_sel      <= EX_cop0_sel    ;
        MM_PC            <= EX_PC          ;
        MM_v_addr        <= EX_v_addr      ;
        MM_nullify       <= EX_nullify     ;
        MM_addrError     <= EX_addrError   ;
        MM_addrErr_stage_mm <= EX_addrErr_stage_mm;
        MM_is_delayslot  <= EX_is_delayslot;
        MM_trapped       <= EX_trapped     ;
        MM_ll_sc_abort   <= EX_ll_sc_abort ;
        MM_tlb_exception <= EX_tlb_exception;
        MM_tlb_stage_MM  <= EX_tlb_stage_MM;
        MM_int_req       <= EX_int_req     ;
        MM_is_SC         <= EX_is_SC       ;
        MM_is_MFC0       <= EX_is_MFC0     ;
        MM_is_exception  <= EX_is_exception;        
      end if;
    end if;
  end process;
end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- exception MEM-WB
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
use work.p_EXCEPTION.all;
entity reg_excp_MM_WB is
  port(clk, rst, ld:  in  std_logic;
       MM_PC:         in  reg32;
       WB_PC:         out reg32;
       MM_cop0_LLbit: in  std_logic;
       WB_cop0_LLbit: out std_logic;
       MM_is_delayslot: in  std_logic;
       WB_is_delayslot: out std_logic;
       MM_cop0_val:   in  reg32;
       WB_cop0_val:   out reg32);
end reg_excp_MM_WB;

architecture funcional of reg_excp_MM_WB is
begin
  process(clk, rst, ld)
  begin
    if rst = '0' then
      WB_cop0_LLbit <= '0';
    elsif rising_edge(clk) then
      if ld = '0' then
        WB_PC           <= MM_PC         ;
        WB_cop0_LLbit   <= MM_cop0_LLbit ;
        WB_is_delayslot <= MM_is_delayslot;
        WB_cop0_val     <= MM_cop0_val   ;
      end if;
    end if;
  end process;

end funcional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

