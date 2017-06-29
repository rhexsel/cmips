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


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CPU core
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;
use work.p_exception.all;


entity core is
  port (
    rst    : in    std_logic;
    clk    : in    std_logic;
    phi1   : in    std_logic;
    phi2   : in    std_logic;
    phi3   : in    std_logic;
    i_aVal : out   std_logic;
    i_wait : in    std_logic;
    i_addr : out   reg32;
    instr  : in    reg32;
    d_aVal : out   std_logic;
    d_wait : in    std_logic;
    d_addr : out   reg32;
    data_inp : in  reg32;
    data_out : out reg32;
    wr       : out std_logic;
    b_sel    : out reg4;
    busFree  : out std_logic;
    nmi      : in  std_logic;
    irq      : in  reg6;
    i_busErr : in  std_logic;
    d_busErr : in  std_logic);
end core;

architecture rtl of core is

  -- control pipeline registers ------------ 
  component reg_excp_IF_RF is
    port(clk, rst, ld: in  std_logic;
         IF_excp_type: in  exception_type;
         RF_excp_type: out exception_type;
         PC_abort:     in  boolean;
         RF_PC_abort:  out  boolean;
         IF_PC:        in  std_logic_vector;
         RF_PC:        out std_logic_vector);
  end component reg_excp_IF_RF;

  component reg_excp_RF_EX is
    port(clk, rst, ld: in  std_logic;
         RF_cop0_reg:     in  reg5;
         EX_cop0_reg:     out reg5;
         RF_cop0_sel:     in  reg3;
         EX_cop0_sel:     out reg3;
         RF_can_trap:     in  std_logic_vector;
         EX_can_trap:     out std_logic_vector;
         RF_exception:    in  exception_type;
         EX_exception:    out exception_type;
         RF_is_delayslot: in  std_logic;
         EX_is_delayslot: out std_logic;
         RF_PC_abort:     in  boolean;
         EX_PC_abort:     out  boolean;
         RF_PC:           in  std_logic_vector;
         EX_PC:           out std_logic_vector;
         RF_trap_taken:   in  boolean;
         EX_trapped:      out boolean);
  end component reg_excp_RF_EX;

  component reg_excp_EX_MM is
    port(clk, rst, ld:  in  std_logic;
         EX_cop0_reg:   in  reg5;
         MM_cop0_reg:   out reg5;
         EX_cop0_sel:   in  reg3;
         MM_cop0_sel:   out reg3;
         EX_PC:         in  std_logic_vector;
         MM_PC:         out std_logic_vector;
         EX_v_addr:     in  std_logic_vector;
         MM_v_addr:     out std_logic_vector;
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
         EX_ll_sc_abort:   in  boolean;
         MM_ll_sc_abort:   out boolean;
         EX_tlb_exception: in  boolean;
         MM_tlb_exception: out boolean;
         EX_tlb_stage_MM:  in  boolean;
         MM_tlb_stage_MM:  out boolean;
         EX_int_req:       in  reg6;
         MM_int_req:       out reg6;
         EX_is_SC:         in  boolean;
         MM_is_SC:         out boolean;
         EX_is_MFC0:       in  boolean;
         MM_is_MFC0:       out boolean;
         EX_is_exception:  in  exception_type;
         MM_is_exception:  out exception_type);
    
  end component reg_excp_EX_MM;

  component reg_excp_MM_WB is
    port(clk, rst, ld:  in  std_logic;
         MM_PC:         in  std_logic_vector;
         WB_PC:         out std_logic_vector;
         MM_cop0_LLbit: in  std_logic;
         WB_cop0_LLbit: out std_logic;
         MM_is_delayslot: in  std_logic;
         WB_is_delayslot: out std_logic;
         MM_cop0_val:   in  std_logic_vector;
         WB_cop0_val:   out std_logic_vector);
  end component reg_excp_MM_WB;

  signal nullify_MM_pre, nullify_MM_int :std_logic;
  signal annul_1, annul_2, annul_twice : std_logic;
  signal interrupt, exception_stall : std_logic;
  signal dly_i0, dly_i1, dly_i2, dly_interr: std_logic; 
  signal exception_taken, interrupt_taken, tlb_excp_taken : std_logic;
  signal nullify_fetch, nullify, MM_nullify : boolean;
  signal addrError, MM_addrError, abort_ref, MM_ll_sc_abort : boolean;
  signal PC_abort, RF_PC_abort, EX_PC_abort : boolean;
  signal IF_excp_type,RF_excp_type : exception_type;
  signal mem_excp_type, tlb_excp_type : exception_type;
  signal trap_instr: instr_type;
  signal RF_PC,EX_PC,MM_PC,WB_PC, LLaddr: reg32;
  signal ll_sc_bit, MM_LLbit,WB_LLbit: std_logic;
  signal LL_update, LL_SC_abort, LL_SC_differ: std_logic;
  signal EX_trapped, MM_trapped, EX_ovfl, trap_taken: boolean;
  signal int_req, MM_int_req: reg6;
  signal can_trap,EX_can_trap : reg2;
  signal is_trap, tr_signed, tr_stall: std_logic;
  signal tr_is_equal, tr_less_than: std_logic;
  signal tr_fwd_A, tr_fwd_B, tr_result : reg32;
  signal excp_IF_RF_ld,excp_RF_EX_ld,excp_EX_MM_ld,excp_MM_WB_ld: std_logic;
  signal update, not_stalled: std_logic;
  signal update_reg : reg5;
  signal status_update,epc_update,compare_update: std_logic;
  signal disable_count, compare_set, compare_clr: std_logic;
  signal STATUSinp, STATUS, CAUSE, EPCinp,EPC : reg32;
  signal COUNT, COMPARE : reg32;
  signal count_eq_compare,count_update,count_enable : std_logic;
  signal exception,EX_exception, MM_exception : exception_type;
  signal is_exception, EX_is_exception : exception_type;
  signal ExcCode : reg5 := cop0code_NULL;
  signal exception_dec,TLB_excp_num,trap_dec: integer; -- debugging
  signal RF_is_delayslot,EX_is_delayslot,MM_is_delayslot,WB_is_delayslot,is_delayslot : std_logic;
  signal cop0_sel, EX_cop0_sel, MM_cop0_sel, epc_source : reg3;
  signal cop0_reg,EX_cop0_reg,MM_cop0_reg : reg5;
  signal cop0_inp, RF_cop0_val,MM_cop0_val,WB_cop0_val : reg32;
  signal BadVAddr, BadVAddr_inp : reg32;
  signal BadVAddr_update : std_logic;
  signal is_SC, MM_is_SC, is_MFC0, MM_is_MFC0 : boolean;

  signal is_busError, is_nmi, is_interr, is_ovfl : boolean;
  signal busError_type : exception_type;
  
  -- MMU signals --
  signal INDEX, index_inp, RANDOM, WIRED, wired_inp : reg32;
  signal index_update, wired_update : std_logic;
  signal EntryLo0, EntryLo1, EntryLo0_inp, EntryLo1_inp : reg32;
  signal EntryHi, EntryHi_inp, v_addr, MM_v_addr : reg32;
  signal Context, PageMask, PageMask_inp : reg32;
  signal entryLo0_update, entryLo1_update, entryHi_update : std_logic;
  signal context_upd_pte, context_upd_bad, tlb_read, tlb_ex_2 : std_logic;
  signal tlb_entrylo0_mm, tlb_entrylo1_mm, tlb_entryhi : reg32;
  signal tlb_tag0_updt, tlb_tag1_updt, tlb_tag2_updt, tlb_tag3_updt : std_logic;
  signal tlb_tag4_updt, tlb_tag5_updt, tlb_tag6_updt, tlb_tag7_updt : std_logic;
  signal tlb_dat0_updt, tlb_dat1_updt, tlb_dat2_updt, tlb_dat3_updt : std_logic;
  signal tlb_dat4_updt, tlb_dat5_updt, tlb_dat6_updt, tlb_dat7_updt : std_logic;
  signal hit0_pc, hit1_pc, hit2_pc, hit3_pc, hit_pc : boolean;
  signal hit4_pc, hit5_pc, hit6_pc, hit7_pc : boolean;
  signal hit0_mm, hit1_mm, hit2_mm, hit3_mm, hit_mm : boolean;
  signal hit4_mm, hit5_mm, hit6_mm, hit7_mm: boolean;
  signal tlb_exception,MM_tlb_exception,tlb_stage_mm,MM_tlb_stage_mm : boolean;
  signal addrErr_stage_mm, MM_addrErr_stage_mm : boolean;
  signal hit_mm_v, hit_mm_d, hit_pc_v : std_logic;
  signal tlb_adr_mm : MMU_idx_bits;
  signal tlb_probe, probe_hit, hit_mm_bit : std_logic;
  signal mm, tlb_excp_VA : std_logic_vector(VA_HI_BIT downto VA_LO_BIT);
  signal tlb_adr,tlb_a0_pc,tlb_a1_pc,tlb_a2_pc : natural range 0 to (MMU_CAPACITY-1);
  signal hit_pc_adr, hit_mm_adr : natural range 0 to (MMU_CAPACITY-1);
  signal tlb_a0_mm,tlb_a1_mm,tlb_a2_mm : natural range 0 to (MMU_CAPACITY-1);
  signal tlb_ppn_pc0,tlb_ppn_pc1 : mmu_dat_reg;
  signal tlb_ppn_mm0,tlb_ppn_mm1 : mmu_dat_reg;
  signal tlb_ppn_mm, tlb_ppn_pc  : std_logic_vector(PPN_BITS - 1 downto 0);
  
  signal tlb_tag0, tlb_tag1, tlb_tag2, tlb_tag3, tlb_tag_inp : reg32;
  signal tlb_tag4, tlb_tag5, tlb_tag6, tlb_tag7, e_hi, e_hi_inp : reg32;
  signal tlb_dat0_inp, tlb_dat1_inp, e_lo0, e_lo1 : mmu_dat_reg;
  signal tlb_dat0_0, tlb_dat1_0, tlb_dat2_0, tlb_dat3_0 : mmu_dat_reg;
  signal tlb_dat0_1, tlb_dat1_1, tlb_dat2_1, tlb_dat3_1 : mmu_dat_reg;
  signal tlb_dat4_0, tlb_dat5_0, tlb_dat6_0, tlb_dat7_0 : mmu_dat_reg;
  signal tlb_dat4_1, tlb_dat5_1, tlb_dat6_1, tlb_dat7_1 : mmu_dat_reg;

  signal tlb_entryLo0, tlb_entryLo1, phy_i_addr, phy_d_addr : reg32;
  
  -- other components ------------ 
  
  component FFD is
    port(clk, rst, set, D : in std_logic; Q : out std_logic);
  end component FFD;

  component adder32 is
    port(A, B : in  std_logic_vector;
         C    : out std_logic_vector);
  end component adder32;

  component mf_alt_add_4 IS
    port(datab : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         result : OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
  end component mf_alt_add_4;

  component mf_alt_adder IS
    port(dataa  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         datab  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         result : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
  end component mf_alt_adder;

  component subtr32 IS
  port(A,B : in  std_logic_vector (31 downto 0);
       C   : out std_logic_vector (31 downto 0);
       sgnd    : in  std_logic;
       ovfl,lt : out std_logic);
  end component subtr32;
  
  component reg_bank is
    port(wrclk, rdclk, wren: in  std_logic;
         a_rs, a_rt, a_rd:   in  std_logic_vector;
         C:                  in  std_logic_vector;
         A, B:               out std_logic_vector);
  end component reg_bank;
  
  component register32 is
    generic (INITIAL_VALUE: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component register32;

  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component registerN;

  component counter32 is
    generic (INITIAL_VALUE: std_logic_vector);
    port(clk, rst, ld, en: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component counter32;
  
  component alu is
    port(clk, rst: in  std_logic;
         A, B:     in  std_logic_vector;
         C:        out std_logic_vector;
         LO:       out std_logic_vector;
         HI:       out std_logic_vector;
         wr_hilo:  in  std_logic;
         move_ok:  out std_logic;
         fun:      in  t_alu_fun;
         postn:    in  std_logic_vector;
         shamt:    in  std_logic_vector;
         ovfl:     out std_logic);
  end component alu;

  signal PC,PC_aligned : reg32;
  signal PCinp,PCinp_noExcp, PCincd : reg32;
  signal instr_fetched : reg32;
  signal PCload, IF_RF_ld : std_logic;
  signal PCsel : reg2;
  signal excp_PCsel : reg3;

  signal rom_stall, iaVal, if_stalled, mem_stall, pipe_stall : std_logic;
  signal ram_stall, daVal, mm_stalled : std_logic;
  signal br_target, br_addend, br_tgt_pl4, br_tgt_displ, j_target : reg32;
  signal RF_PCincd, RF_instruction : reg32;
  signal eq_fwd_A,eq_fwd_B : reg32;
  signal dbg_jr_stall: integer;         -- debugging only
  
  -- register fetch/read and instruction decode --  
  component reg_IF_RF is
    port(clk, rst, ld: in  std_logic;
         PCincd_d:     in  std_logic_vector;
         PCincd_q:     out std_logic_vector;
         instr:        in  std_logic_vector;
         RF_instr:     out std_logic_vector);
  end component reg_IF_RF;

  signal opcode, func: reg6;
  signal ctrl_word:  t_control_type;
  signal funct_word: t_function_type;
  signal rimm_word:  t_rimm_type;
  signal syscall_n : reg20;
  signal displ16: reg16;
  signal br_operand: reg32;
  signal br_opr: reg2;
  signal br_equal,br_negative,br_eq_zero: boolean;
  signal flush_RF_EX: boolean := FALSE;
  signal is_branch: std_logic;
  signal c_sel : reg2;
  
  -- execution and beyond --  
  signal RF_EX_ld, EX_MM_ld, MM_WB_ld: std_logic;
  signal a_rs,EX_a_rs, a_rt,EX_a_rt,MM_a_rt, a_rd: reg5;
  signal a_c,EX_a_c,MM_a_c,WB_a_c: reg5;
  signal move,EX_move,MM_move : std_logic;
  signal is_load,EX_is_load,MM_is_load : boolean;
  signal muxC,EX_muxC,MM_muxC,WB_muxC: reg3;
  signal wreg,EX_wreg_pre,EX_wreg,MM_wreg_cond,MM_wreg,WB_wreg: std_logic;
  signal aVal,EX_aVal,EX_aVal_cond,MM_aVal: std_logic;
  signal wrmem,EX_wrmem,EX_wrmem_cond,MM_wrmem, m_sign_ext: std_logic;
  signal mem_t, EX_mem_t,MM_mem_t: reg4;
  signal WB_mem_t : reg2;

  signal alu_inp_A,alu_fwd_B,alu_inp_B : reg32;
  signal alu_move_ok, MM_alu_move_ok, ovfl : std_logic;
  
  signal selB,EX_selB:  std_logic;
  signal oper,EX_oper: t_alu_fun;
  signal EX_postn, shamt,EX_shamt: reg5;
  signal regs_A,EX_A,MM_A,WB_A, regs_B,EX_B,MM_B: reg32;
  signal displ32,EX_displ32: reg32;
  signal result,MM_result,WB_result,WB_C, EX_addr,MM_addr: reg32;
  signal pc_p8,EX_pc_p8,MM_pc_p8,WB_pc_p8 : reg32;
  signal HI,MM_HI,WB_HI, LO,MM_LO,WB_LO : reg32;

  -- data memory --
  signal rd_data_raw, rd_data, WB_rd_data, WB_mem_data: reg32;
  signal MM_B_data, WB_B_data: reg32;
  signal jr_stall, br_stall, sw_stall, lw_stall : std_logic;
  signal fwd_lwlr : boolean;
  signal fwd_mem, WB_addr2: reg2;


  component reg_RF_EX is
    port(clk, rst, ld: in  std_logic;
         selB:       in  std_logic;
         EX_selB:    out std_logic;
         oper:       in  t_alu_fun;
         EX_oper:    out t_alu_fun;
         a_rs:       in  std_logic_vector;
         EX_a_rs:    out std_logic_vector;
         a_rt:       in  std_logic_vector;
         EX_a_rt:    out std_logic_vector;
         a_c:        in  std_logic_vector;
         EX_a_c:     out std_logic_vector;
         wreg:       in  std_logic;
         EX_wreg:    out std_logic;
         muxC:       in  std_logic_vector;
         EX_muxC:    out std_logic_vector;
         move:       in  std_logic;
         EX_move:    out std_logic;
         postn:      in  std_logic_vector;
         EX_postn:   out std_logic_vector;
         shamt:      in  std_logic_vector;
         EX_shamt:   out std_logic_vector;
         aVal:       in  std_logic;
         EX_aVal:    out std_logic;
         wrmem:      in  std_logic;
         EX_wrmem:   out std_logic;
         mem_t:      in  std_logic_vector;
         EX_mem_t:   out std_logic_vector;
         is_load:    in  boolean;
         EX_is_load: out boolean;
         A:          in  std_logic_vector;
         EX_A:       out std_logic_vector;
         B:          in  std_logic_vector;
         EX_B:       out std_logic_vector;
         displ32:    in  std_logic_vector;
         EX_displ32: out std_logic_vector;
         pc_p8:      in  std_logic_vector;
         EX_pc_p8:   out std_logic_vector);
  end component reg_RF_EX;
      
  component reg_EX_MM is
    port(clk, rst, ld: in  std_logic;
         EX_a_rt:    in  std_logic_vector;
         MM_a_rt:    out std_logic_vector;
         EX_a_c:     in  std_logic_vector;
         MM_a_c:     out std_logic_vector;
         EX_wreg:    in  std_logic;
         MM_wreg:    out std_logic;
         EX_muxC:    in  std_logic_vector;
         MM_muxC:    out std_logic_vector;
         EX_aVal:    in  std_logic;
         MM_aVal:    out std_logic;
         EX_wrmem:   in  std_logic;
         MM_wrmem:   out std_logic;
         EX_mem_t:   in  std_logic_vector;
         MM_mem_t:   out std_logic_vector;
         EX_is_load: in  boolean;
         MM_is_load: out boolean;
         EX_A:       in  std_logic_vector;
         MM_A:       out std_logic_vector;
         EX_B:       in  std_logic_vector;
         MM_B:       out std_logic_vector;
         EX_result:  in  std_logic_vector;
         MM_result:  out std_logic_vector;
         EX_addr:    in  std_logic_vector;
         MM_addr:    out std_logic_vector;
         HI:         in  std_logic_vector;
         MM_HI:      out std_logic_vector;
         LO:         in  std_logic_vector;
         MM_LO:      out std_logic_vector;
         EX_alu_move_ok: in  std_logic;
         MM_alu_move_ok: out std_logic;
         EX_move:    in  std_logic;
         MM_move:    out std_logic;
         EX_pc_p8:   in  std_logic_vector;
         MM_pc_p8:   out std_logic_vector);
  end component reg_EX_MM;
  
  component reg_MM_WB is
    port(clk, rst, ld: in  std_logic;
         MM_a_c:     in  std_logic_vector;
         WB_a_c:     out std_logic_vector;
         MM_wreg:    in  std_logic;
         WB_wreg:    out std_logic;
         MM_muxC:    in  std_logic_vector;
         WB_muxC:    out std_logic_vector;
         MM_A:       in  std_logic_vector;
         WB_A:       out std_logic_vector;
         MM_result:  in  std_logic_vector;
         WB_result:  out std_logic_vector;
         MM_HI:      in  std_logic_vector;
         WB_HI:      out std_logic_vector;
         MM_LO:      in  std_logic_vector;
         WB_LO:      out std_logic_vector;
         rd_data:    in  std_logic_vector;
         WB_rd_data: out std_logic_vector;
         MM_B_data:  in  std_logic_vector;
         WB_B_data:  out std_logic_vector;
         MM_addr2:   in  std_logic_vector;
         WB_addr2:   out std_logic_vector;
         MM_oper:    in  std_logic_vector;
         WB_oper:    out std_logic_vector;
         MM_pc_p8:   in  std_logic_vector;
         WB_pc_p8:   out std_logic_vector);
  end component reg_MM_WB;


-- fields of the control table
--    aVal:  std_logic;        -- addressValid, enable data-mem=0
--    wmem:  std_logic;        -- READ=1/WRITE=0 in/to memory
--    i:     instr_type;       -- instruction
--    wreg:  std_logic;        -- register write=0
--    selB:  std_logic;        -- B ALU input, reg=0 ext=1
--    fun:   std_logic;        -- check function_field=1
--    oper:  t_alu_fun;        -- ALU operation
--    muxC:  reg3;             -- select result mem=0 ula=1 jr=2 pc+8=3
--    c_sel: reg2;             -- select destination reg RD=0 RT=1 31=2
--    extS:  std_logic;        -- sign-extend=1, zero-ext=0
--    PCsel: reg2;             -- PCmux 0=PC+4 1=beq 2=j 3=jr
--    br_t:  t_comparison;     -- branch: 0=no 1=beq 2=bne
--    excp:  reg2              -- stage with exception 0=no,1=rf,2=ex,3=mm
  
  constant ctrl_table : t_control_mem := (
  --aVal wmem ins wreg selB fun oper muxC  csel extS PCsel br_t excp
    ('1','1',iALU, '1','0','1',opNOP,"001","00", '0', "00",cNOP,"00"),--ALU=0
    ('1','1',RIMM, '1','0','0',opNOP,"001","00", '1', "00",cOTH,"00"),--BR=1
    ('1','1',J,    '1','0','0',opNOP,"001","00", '0', "10",cNOP,"00"),--j=2
    ('1','1',JAL,  '0','0','0',opNOP,"011","10", '0', "10",cNOP,"00"),--jal=3
    ('1','1',BEQ,  '1','0','0',opNOP,"001","00", '1', "01",cEQU,"00"),--beq=4
    ('1','1',BNE,  '1','0','0',opNOP,"001","00", '1', "01",cNEQ,"00"),--bne=5
    ('1','1',BLEZ, '1','0','0',opNOP,"001","00", '1', "01",cLEZ,"00"),--blez=6
    ('1','1',BGTZ, '1','0','0',opNOP,"001","00", '1', "01",cGTZ,"00"),--bgtz=7
    ('1','1',ADDI, '0','1','0',opADD,"001","01", '1', "00",cNOP,"10"),--addi=8
    ('1','1',ADDIU,'0','1','0',opADD,"001","01", '1', "00",cNOP,"00"),--addiu=9
    ('1','1',SLTI, '0','1','0',opSLT,"001","01", '1', "00",cNOP,"10"),--slti=10
    ('1','1',SLTIU,'0','1','0',opSLTU,"001","01",'1', "00",cNOP,"00"),--sltiu11
    ('1','1',ANDI, '0','1','0',opAND,"001","01", '0', "00",cNOP,"00"),--andi=12
    ('1','1',ORI,  '0','1','0',opOR, "001","01", '0', "00",cNOP,"00"),--ori=13
    ('1','1',XORI, '0','1','0',opXOR,"001","01", '0', "00",cNOP,"00"),--xori=14
    ('1','1',LUI,  '0','1','0',opLUI,"001","01", '0', "00",cNOP,"00"),--lui=15
    ('1','1',COP0, '1','0','1',opNOP,"110","01", '0', "00",cNOP,"00"),--COP0=16
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--17
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--18
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--19
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--beql=20
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--bnel=21
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--blzel=22
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--bgtzl=23
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--24
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--25
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--26
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--27
    ('1','1',SPEC2,'0','0','0',opSPC,"001","00", '0', "00",cNOP,"00"),--28
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--29
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--30
    ('1','1',SPEC3,'0','0','0',opSPC,"001","00", '0', "00",cNOP,"00"),--special3
    ('0','1',LB,   '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--lb=32
    ('0','1',LH,   '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--lh=33
    ('0','1',LWL,  '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--lwl=34
    ('0','1',LW,   '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--lw=35
    ('0','1',LBU,  '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--lbu=36
    ('0','1',LHU,  '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--lhu=37
    ('0','1',LWR,  '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--lwr=38
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--39
    ('0','0',SB,   '1','1','0',opADD,"001","00", '1', "00",cNOP,"11"),--sb=40
    ('0','0',SH,   '1','1','0',opADD,"001","00", '1', "00",cNOP,"11"),--sh=41
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--swl=42
    ('0','0',SW,   '1','1','0',opADD,"001","00", '1', "00",cNOP,"11"),--sw=43
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--44
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--45
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--swr=46
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--cache=47
    ('0','1',LL,   '0','1','0',opADD,"000","01", '1', "00",cNOP,"11"),--ll=48
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--lwc1=49
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--lwc2=50
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--pref=51
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--52
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--ldc1=53
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--ldc2=54
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--55
    ('0','0',SC,   '0','1','0',opADD,"111","01", '1', "00",cNOP,"11"),--sc=56
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--swc1=57
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--swc2=58
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--59
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--60
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--sdc1=61
    ('1','1',NIL,  '1','0','0',opNOP,"001","00", '0', "00",cNOP,"00"),--sdc2=62
    ('1','1',NOP,  '1','0','0',opNOP,"000","00", '0', "00",cNOP,"00") --63
    );

-- fields of the function table (opcode=0)
--    i:     instr_type;       -- instruction
--    wreg:  std_logic;        -- register write=0
--    selB:  std_logic;        -- B ALU input, reg=0 ext=1
--    oper:  t_alu_fun;        -- ALU operation
--    muxC:  reg3;             -- select result mem=0 ula=1 jr=2 pc+8=3
--    trap:  std_logic;        -- trap on compare
--    move:  std_logic;        -- conditional move
--    sync:  std_logic;        -- synch the memory hierarchy
--    PCsel: reg2;             -- PCmux 0=PC+4 1=beq 2=j 3=jr
--    excp:  reg2              -- stage with exception 0=no,1=rf,2=ex,3=mm
  
  constant func_table : t_function_mem := (
  -- i    wreg selB oper   muxC trap mov syn PCsel excp
    (iSLL, '0','0',opSLL,  "001",'0','0','0',"00","00"),  --sll=0, EHB
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --1, FlPoint
    (iSRL, '0','0',opSRL,  "001",'0','0','0',"00","00"),  --srl=2
    (iSRA, '0','0',opSRA,  "001",'0','0','0',"00","00"),  --sra=3
    (SLLV, '0','0',opSLLV, "001",'0','0','0',"00","00"),  --sllv=4
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --5
    (SRLV, '0','0',opSRLV, "001",'0','0','0',"00","00"),  --srlv=6
    (SRAV, '0','0',opSRAV, "001",'0','0','0',"00","00"),  --srav=7
    (JR,   '1','0',opNOP,  "001",'0','0','0',"11","00"),  --jr=8
    (JALR, '0','0',opNOP,  "011",'0','0','0',"11","00"),  --jalr=9
    (MOVZ, '0','0',opMOVZ, "001",'0','1','0',"00","00"),  --movz=10
    (MOVN, '0','0',opMOVN, "001",'0','1','0',"00","00"),  --movn=11
    (SYSCALL,'1','0',trNOP,"001",'1','0','0',"00","00"),  --syscall=12
    (BREAK,'1','0',trNOP,  "001",'1','0','0',"00","00"),  --break=13
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --14
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --15
    (MFHI, '0','0',opMFHI, "100",'0','0','0',"00","00"),  --mfhi=16
    (MTHI, '1','0',opMTHI, "001",'0','0','0',"00","00"),  --mthi=17
    (MFLO, '0','0',opMFLO, "101",'0','0','0',"00","00"),  --mflo=18
    (MTLO, '1','0',opMTLO, "001",'0','0','0',"00","00"),  --mtlo=19
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --20
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --21
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --22
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --23
    (MULT, '1','0',opMULT, "001",'0','0','0',"00","00"),  --mult=24
    (MULTU,'1','0',opMULTU,"001",'0','0','0',"00","00"),  --multu=25
    (DIV,  '1','0',opDIV,  "001",'0','0','0',"00","00"),  --div=26
    (DIVU, '1','0',opDIVU, "001",'0','0','0',"00","00"),  --divu=27
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --28
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --29
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --30
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --31
    (ADD,  '0','0',opADD,  "001",'0','0','0',"00","10"),  --add=32
    (ADDU, '0','0',opADDU, "001",'0','0','0',"00","00"),  --addu=33
    (SUB,  '0','0',opSUB,  "001",'0','0','0',"00","10"),  --sub=34
    (SUBU, '0','0',opSUBU, "001",'0','0','0',"00","00"),  --subu=35
    (iAND, '0','0',opAND,  "001",'0','0','0',"00","00"),  --and=36
    (iOR,  '0','0',opOR,   "001",'0','0','0',"00","00"),  --or=37
    (iXOR, '0','0',opXOR,  "001",'0','0','0',"00","00"),  --xor=38
    (iNOR, '0','0',opNOR,  "001",'0','0','0',"00","00"),  --nor=39
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --40
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --41
    (SLT,  '0','0',opSLT,  "001",'0','0','0',"00","10"),  --slt=42
    (SLTU, '0','0',opSLTU, "001",'0','0','0',"00","00"),  --sltu=43
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --44
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --45
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --46
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --47
    (TGE,  '1','0',trGEQ,  "001",'1','0','0',"00","10"),  --tge=48
    (TGEU, '1','0',trGEU,  "001",'1','0','0',"00","10"),  --tgeu=49
    (TLT,  '1','0',trLTH,  "001",'1','0','0',"00","10"),  --tlt=50
    (TLTU, '1','0',trLTU,  "001",'1','0','0',"00","10"),  --tltu=51
    (TEQ,  '1','0',trEQU,  "001",'1','0','0',"00","10"),  --teq=52
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --53
    (TNE,  '1','0',trNEQ,  "001",'1','0','0',"00","10"),  --tne=54
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --55
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --56
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --57
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --58
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --59
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --60
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --61
    (NIL,  '1','0',opNOP,  "001",'0','0','0',"00","00"),  --62
    (NOP,  '1','0',opNOP,  "001",'0','0','0',"00","00")   --63
    );

  -- fields of the register-immediate control table (opcode=1)
  --   i:     instr_type;       -- instruction
  --   wreg:  std_logic;        -- register write=0
  --   selB:  std_logic;        -- B ALU input, reg=0 ext=1
  --   br_t:  t_comparison;     -- comparison type: ltz,gez
  --   muxC:  reg3;             -- select result mem=0 ula=1 jr=2 *al(pc+8)=3
  --   c_sel: reg2              -- select destination reg rd=0 rt=1 31=2
  --   trap:  std_logic;        -- trap on compare
  --   PCsel: reg2;             -- PCmux 0=PC+4 1=beq 2=j 3=jr
  --   excp:  reg2              -- stage with exception 0=no,1=rf,2=ex,3=mm
  
  constant rimm_table : t_rimm_mem := (
  -- i    wreg selB br_t muxC  csel trap PCsel excp
    (BLTZ, '1','0',cLTZ, "001","00",'0',"01","00"),  --0bltz
    (BGEZ, '1','0',cGEZ, "001","00",'0',"01","00"),  --1bgez
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --2
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --3
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --4
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --5
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --6
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --7
    (TGEI, '1','1',tGEQ, "001","00",'1',"00","10"),  --8tgei
    (TGEIU,'1','1',tGEU, "001","00",'1',"00","10"),  --9tgeiu
    (TLTI, '1','1',tLTH, "001","00",'1',"00","10"),  --10tlti
    (TLTIU,'1','1',tLTU, "001","00",'1',"00","10"),  --11tltiu
    (TEQI, '1','1',tEQU, "001","00",'1',"00","10"),  --12teqi
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --13
    (TNEI, '1','1',tNEQ, "001","00",'1',"00","10"),  --14tnei
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --15
    (BLTZAL,'0','0',cLTZ,"011","10",'0',"01","00"),  --16bltzal
    (BGEZAL,'0','0',cGEZ,"011","10",'0',"01","00"),  --17bgezal
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --18
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --19
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --20
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --21
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --22
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --23
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --24
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --25
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --26
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --27
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --28
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --29
    (NIL,  '1','0',cNOP, "001","00",'0',"00","00"),  --30
    (NOP,  '1','0',cNOP, "001","00",'0',"00","00")   --31
    );

  -- Table 8-30 Config Register Field Descriptions, pg 101
  constant CONFIG0 : reg32 := (
    '1'&        -- M, Config1 implemented = 1
    b"000"&     -- K23, with MMU, kseg2,kseg3 coherency algorithm
    b"000"&     -- KU, with MMU, kuseg coherency algorithm
    b"000000000"& -- Impl, implementation dependent = 0
    '0'&        -- BE, little endian = 0
    b"00"&      -- AT, MIPS32 = 0
    b"001"&     -- AR, Release 2 = 1
    b"001"&     -- MT, MMU type = 1, standard
    b"000"&     -- nil, always zero = 0
    '1'&        -- VI, Instruction Cache is virtual = 1
    b"000"      -- K0, Kseg0 coherency algorithm
    );

  -- Table 8-31 Config1 Register Field Descriptions, pg 103
  constant CONFIG1 : reg32 := (
    '0'&               -- M, Config2 not implemented = 0
    MMU_SIZE         & -- MMUsz, MMU entries minus 1
    IC_SETS_PER_WAY  & -- ICS, IC sets per way
    IC_LINE_SIZE     & -- ICL, IC line size
    IC_ASSOCIATIVITY & -- ICA, IC associativity
    DC_SETS_PER_WAY  & -- DCS, DC sets per way
    DC_LINE_SIZE     & -- DCL, DC line size = 3 16 bytes/line
    DC_ASSOCIATIVITY & -- DCA, DC associativity = 0 direct mapped
    '0'&        -- C2, No coprocessor 2 implemented = 0
    '0'&        -- MD, No MDMX ASE implemented = 0
    '0'&        -- PC, No performance counters implemented = 0
    '0'&        -- WR, No watch registers implemented = 0
    '0'&        -- CA, No code compression implemented = 0
    '0'&        -- EP, No EJTAG implemented = 0
    '0'         -- FP, No FPU implemented = 0
    );

  
-- pipeline ============================================================
begin

  -- INSTR_FETCH_STATE_MACHINE: instruction-bus control
  U_ifetch_stalled: FFD port map (clk => phi2, rst => rst, set => '1',
                                  D => mem_stall, Q => if_stalled);

  -- iaVal <= '1' when ((phi0 = '1' and if_stalled = '0')) else '0';
  
  i_aVal <= '0'; -- interface signal/port, always fetches a new instruction
  iaVal  <= '0'; -- internal signal
  
  rom_stall <= not(iaVal) and not(i_wait);

  mem_stall   <= ram_stall or rom_stall;
  not_stalled <= not(mem_stall);

  -- end INSTR_FETCH_STATE_MACHINE --------------------------
  
 
  -- PROGRAM COUNTER AND INSTRUCTION FETCH ------------------

  pipe_stall <= rom_stall or ram_stall or jr_stall or br_stall or
                sw_stall  or lw_stall  or tr_stall  or exception_stall;

  
  PCload   <= '1' when pipe_stall = '1' else '0';
  IF_RF_ld <= '1' when pipe_stall = '1' else '0';
  RF_EX_ld <= mem_stall; -- or exception_stall;
  EX_MM_ld <= mem_stall;
  MM_WB_ld <= mem_stall;

  
  excp_IF_RF_ld <= '1' when pipe_stall = '1' else '0';
  excp_RF_EX_ld <= mem_stall; -- or exception_stall;
  excp_EX_MM_ld <= mem_stall;
  excp_MM_WB_ld <= mem_stall;


  with PCsel select
  PCinp_noExcp <= PCincd    when b"00",     -- next instruction
                  br_target when b"01",     -- taken branch
                  j_target  when b"10",     -- jump
                  eq_fwd_A  when b"11",     -- jump register regs_A
                  (others => 'X') when others;

  with excp_PCsel select
    PCinp <= PCinp_noExcp     when PCsel_EXC_none, -- no exception
             EPC              when PCsel_EXC_EPC,  -- ERET
             x_EXCEPTION_0000 when PCsel_EXC_0000, -- TLBrefill entry point
             x_EXCEPTION_0180 when PCsel_EXC_0180, -- general exception handler
             x_EXCEPTION_0200 when PCsel_EXC_0200, -- separate interrupt handler
             x_EXCEPTION_BFC0 when PCsel_EXC_BFC0, -- NMI or soft-reset handler
             (others => 'X')  when others;
             -- x_EXCEPTION_0100 when PCsel_EXC_0100, -- Cache Error
  
  PC_abort <= PC(1 downto 0) /= b"00";

  IF_excp_type <= IFaddressError when PC_abort else exNOP;

  
  PIPESTAGE_PC: register32 generic map (x_INST_BASE_ADDR)
    port map (clk, rst, PCload, PCinp, PC);

  PC_aligned <= PC(31 downto 2) & b"00";
  
  -- PCincd <= std_logic_vector( 4 + signed(PC_aligned) );
  U_INCPC: mf_alt_add_4 PORT MAP( datab => PC_aligned, result => PCincd );


  -- uncomment this when NOT making use of the TLB
  -- i_addr <= PC_aligned;    -- fetch instruction from aligned address

  -- uncomment this when making use of the TLB
  i_addr <= phy_i_addr;

  nullify_fetch <= (MM_tlb_exception and not(MM_tlb_stage_mm));

  instr_fetched(25 downto 0)  <= instr(25 downto 0);
  instr_fetched(31 downto 26) <= instr(31 downto 26)
                                 when not(nullify_fetch or PC_abort
                                          or MM_addrError)
                                 else NULL_INSTRUCTION(31 downto 26); -- x"fc";

  
  PIPESTAGE_IF_RF: reg_IF_RF
    port map (clk,rst, IF_RF_ld, PCincd, RF_PCincd,
              instr_fetched, RF_instruction);


  -- INSTRUCTION DECODE AND REGISTER FETCH -----------------

  annul_1 <= BOOL2SL(nullify or MM_addrError);
  U_NULLIFY_TWICE: FFD port map (clk, rst, '1', annul_1, annul_2);
  annul_twice <= annul_1 or annul_2;
  
  opcode <= RF_instruction(31 downto 26) when annul_twice = '0' else
            NULL_INSTRUCTION (31 downto 26);
  
  a_rs      <= RF_instruction(25 downto 21);
  a_rt      <= RF_instruction(20 downto 16);
  a_rd      <= RF_instruction(15 downto 11);
  shamt     <= RF_instruction(10 downto  6);
  func      <= RF_instruction( 5 downto  0);
  displ16   <= RF_instruction(15 downto  0);
  syscall_n <= RF_instruction(25 downto  6);

  
  ctrl_word   <= ctrl_table( to_integer(unsigned(opcode)) );
  
  funct_word  <=
    func_table( to_integer(unsigned(func)) ) when opcode = b"000000" else
    func_table( 63 );                   -- null instruction (sigs inactive)
                 
  rimm_word   <= 
    rimm_table( to_integer(unsigned(a_rt)) ) when opcode = b"000001" else
    rimm_table( 31 );                   -- null instruction (sigs inactive)

  is_branch <= '1' when ((ctrl_word.br_t /= cNOP)
                         or((rimm_word.br_t /= cNOP)and(rimm_word.trap='0')))
                 else '0';

  is_trap <= '1' when ((funct_word.trap = '1')or(rimm_word.trap = '1'))
                 else '0';
  
  RF_is_delayslot <= '1' when ((ctrl_word.PCsel  /= "00") or
                               (funct_word.PCsel /= "00") or
                               (rimm_word.PCsel  /= "00"))
                     else '0';
  
  
  RF_STOP_SIMULATION: process (rst, phi2, opcode, func,
                               ctrl_word, funct_word, rimm_word,
                               RF_PC, exception, syscall_n)
  begin
    
    if rst = '1' and phi2 = '1' then

      -- normal end of simulation, instruction "wait 0"
      assert not(exception = exWAIT and syscall_n = x"80000")
        report LF & "cMIPS BREAKPOINT at PC="& SLV32HEX(RF_PC) &
        " opc="& SLV2STR(opcode) & " fun=" & SLV2STR(func) &
        " brk=" & SLV2STR(syscall_n) & 
        LF & "SIMULATION ENDED (correctly?) AT exit();"
        severity failure;

      -- simulation aborted by instruction "wait N"
      assert not(exception = exWAIT and syscall_n /= x"80000")
        report LF & " PC="& SLV32HEX(PC) &
        " EPC="& SLV32HEX(EPC) &
        " bad="& SLV32HEX(BadVAddr) &
        " opc="& SLV2STR(opcode) & " wait=" & SLV2STR(syscall_n(7 downto 0)) &
        " instr=" & SLV32HEX(RF_instruction) &
        LF & "SIMULATION ABORTED AT EXCEPTION HANDLER;"
        severity failure;

      -- abort on invalid/unimplemented opcodes
      if opcode = b"000000" and funct_word.i = NIL then
        assert (1=0)
          report LF & "INVALID OPCODE at PC="& SLV32HEX(RF_PC) &
          " opc="& SLV2STR(opcode) & " instr=" & SLV32HEX(RF_instruction) &
          LF & "SIMULATION ABORTED"
          severity failure;
      elsif opcode = b"000001" and rimm_word.i = NIL then
        assert (1=0)
          report LF & "INVALID OPCODE at PC="& SLV32HEX(RF_PC) &
          " opc="& SLV2STR(opcode) & " instr=" & SLV32HEX(RF_instruction) &
          LF & "SIMULATION ABORTED"
          severity failure;
      elsif ctrl_word.i = NIL then
        assert (1=0)
          report LF & "INVALID OPCODE at PC="& SLV32HEX(RF_PC) &
          " opc="& SLV2STR(opcode) & " instr=" & SLV32HEX(RF_instruction) &
          LF & "SIMULATION ABORTED"
          severity failure;
      end if;
        
    end if;
  end process RF_STOP_SIMULATION;

  
  move <= funct_word.move when opcode = b"000000" else '0';
  
  U_regs: reg_bank                      -- phi1=read_early, clk=write_late
    port map (clk, phi1, WB_wreg, a_rs,a_rt, WB_a_c,WB_C, regs_A,regs_B);

  
  -- U_PC_plus_8: adder32 port map (x"00000004", RF_PCincd, pc_p8); -- (PC+4)+4
  -- pc_p8 <= std_logic_vector( 4 + signed(RF_PCincd) );   -- (PC+4)+4
  U_PC_plus_8: mf_alt_add_4 PORT MAP( datab => RF_PCincd, result => pc_p8 );

  
  displ32 <= x"FFFF" & displ16 when
                         (displ16(15) = '1' and ctrl_word.extS = '1') else
             x"0000" & displ16;
  
  j_target <= RF_PCincd(31 downto 28) & RF_instruction(25 downto 0) & b"00";

  RF_JR_STALL: process (funct_word,a_rs,EX_a_c,MM_a_c,EX_wreg,MM_wreg,
                        MM_is_load)
    variable i_dbg_jr_stall : integer := 0;  -- debug only
  begin
    if ( (funct_word.PCsel = b"11")and          -- load-delay slot
            (EX_a_c /= a_rs)and(EX_wreg = '0')and
            (MM_a_c =  a_rs)and(MM_wreg = '0')and(MM_a_c /= b"00000") ) then
      jr_stall <= '1';
      i_dbg_jr_stall := 1;
    elsif ( (funct_word.PCsel = b"11")and       -- ALU hazard
         (EX_a_c =  a_rs)and(EX_wreg = '0')and(EX_a_c /= b"00000") ) then
      jr_stall <= '1';
      i_dbg_jr_stall := 2;
    elsif ( (funct_word.PCsel = b"11")and       -- 2nd load-delay slot
            MM_is_load and
            (MM_a_c = a_rs)and(MM_wreg = '0')and(MM_a_c /= b"00000") ) then
      jr_stall <= '1';
      i_dbg_jr_stall := 3;
    else
      jr_stall <= '0';
      i_dbg_jr_stall := 0;
    end if;
    dbg_jr_stall <= i_dbg_jr_stall;
  end process RF_JR_STALL;
  
  
  RF_LD_DELAY_SLOT: process (a_rs,a_rt,EX_a_c,EX_wreg,EX_is_load)
  begin
    if ( EX_is_load and
         (EX_wreg = '0') and (EX_a_c /= b"00000") and
         ( (EX_a_c =  a_rs)or(EX_a_c = a_rt) ) ) then
      lw_stall <= '1';
    else
      lw_stall <= '0';
    end if;
  end process RF_LD_DELAY_SLOT;
  

  RF_SW_STALL: process (ctrl_word,a_rs,EX_a_c,EX_wreg,EX_is_load)
    variable is_store : boolean := false;
  begin
    case ctrl_word.i is
      when LB | LH | LWL | LW | LBU | LHU | LWR =>
        is_load  <= TRUE;
        is_store := FALSE;
      when SB | SH | SW  =>
        is_store := TRUE;
        is_load  <= FALSE;
      when others =>
        is_load <= FALSE;
        is_store := FALSE;
    end case;
    if ( is_store and EX_is_load and
         (EX_a_c =  a_rs)and(EX_wreg = '0')and(EX_a_c /= b"00000") ) then
      sw_stall <= '1';
    else
      sw_stall <= '0';
    end if; 
  end process RF_SW_STALL;
  

  RF_FORWARDING_BRANCH: process (a_rs,a_rt,EX_wreg,EX_a_c,MM_wreg,MM_a_c,
                                 MM_aVal,MM_result,MM_cop0_val,MM_is_MFC0,
                                 regs_A,regs_B,is_branch,
                                 is_SC, LL_SC_abort)
    variable rs_stall, rt_stall : boolean;
  begin

    if ( (is_branch = '1') and          -- forward_A
         (EX_wreg = '0') and (EX_a_c = a_rs) and (EX_a_c /= b"00000") ) then
      if is_SC then
        eq_fwd_A <= x"0000000" & b"000" & not(LL_SC_abort);
        rs_stall := FALSE;
      else
        eq_fwd_A <= regs_A;
        rs_stall := TRUE;
      end if;
    elsif ( (MM_wreg = '0') and (MM_a_c = a_rs) and (MM_a_c /= b"00000") ) then
      if ( (MM_aVal = '0') and (is_branch = '1') ) then   -- LW load-delay slot
        eq_fwd_A <= regs_A;
        rs_stall := TRUE;
      elsif MM_is_MFC0 then          -- non-LW
        eq_fwd_A <= MM_cop0_val;
        rs_stall := FALSE;
      elsif MM_is_SC then
        eq_fwd_A <= x"00000000";
        rs_stall := FALSE;         
      else
        eq_fwd_A <= MM_result;
        rs_stall := FALSE;
      end if;
    else
      eq_fwd_A <= regs_A;
      rs_stall := FALSE;
    end if;

    if ( (is_branch = '1') and          -- forward_B
         (EX_wreg = '0') and (EX_a_c = a_rt) and (EX_a_c /= b"00000") ) then
      if is_SC then
        eq_fwd_B <= x"0000000" & b"000" & not(LL_SC_abort);
        rt_stall := FALSE;
      else
        eq_fwd_B <= regs_B;
        rt_stall := TRUE;
      end if;
    elsif ( (MM_wreg = '0') and (MM_a_c = a_rt) and (MM_a_c /= b"00000") ) then
      if ( (MM_aVal = '0') and (is_branch = '1') ) then   -- LW load-delay slot
        eq_fwd_B <= regs_B;
        rt_stall := TRUE;
      elsif MM_is_MFC0 then          -- non-LW
        eq_fwd_B <= MM_cop0_val;
        rt_stall := FALSE;
      elsif MM_is_SC then
        eq_fwd_B <= x"00000000";
        rt_stall := FALSE;
      else
        eq_fwd_B <= MM_result;
        rt_stall := FALSE;
      end if;
    else
      eq_fwd_B <= regs_B;
      rt_stall := FALSE;
    end if;

    br_stall <= BOOL2SL(rs_stall or rt_stall);
  
  end process RF_FORWARDING_BRANCH;

  
  br_equal    <= (eq_fwd_A = eq_fwd_B);
  br_negative <= (eq_fwd_A(31) = '1');
  br_eq_zero  <= (eq_fwd_A = x"00000000");
  

  RF_BR_tgt_select: process (br_equal,br_negative,br_eq_zero,
                             ctrl_word,rimm_word) 
    variable branch_type, regimm_br_type : t_comparison;
    variable i_br_opr : reg2;
  begin
    branch_type    := ctrl_word.br_t;
    regimm_br_type := rimm_word.br_t;

    i_br_opr := b"01";          -- assume not taken, PC+4 + 4 (delay slot)
    case branch_type is
      when cNOP =>              -- no branch, PC+4
        i_br_opr := b"00";
      when cEQU =>              -- beq
        if br_equal then i_br_opr := b"10";  -- br_target;
        end if;
      when cNEQ =>              -- bne
        if not(br_equal) then i_br_opr := b"10";  -- br_target;
        end if;
      when cLEZ =>
        if (br_negative or br_eq_zero) then i_br_opr := b"10";  -- br_target;
        end if;
      when cGTZ =>
        if not(br_negative or br_eq_zero) then i_br_opr := b"10";  -- br_target;
        end if;
      when cOTH =>              -- bltz,blez,bgtz,bgez
        case regimm_br_type is
          when cLTZ =>
            if br_negative then i_br_opr := b"10";  -- br_target;
            end if;
          when cGEZ =>
            if not(br_negative) then i_br_opr := b"10";  -- br_target;
            end if;
          when others => 
            i_br_opr := b"00";    -- x"00000000";
        end case;
      when others => 
        i_br_opr := b"00";        -- x"00000000";
    end case;
    br_opr <= i_br_opr;
    -- assert false report
    --   "branch_add32 A="& SLV32HEX(RF_PCincd) &" B="& SLV32HEX(br_operand) &
    --   " A+B="& SLV32HEX(br_target); -- DEBUG
  end process RF_BR_tgt_select;

  -- U_BR_ADDER: adder32 port map (RF_PCincd, br_operand, br_target);
  -- br_target <= std_logic_vector( signed(RF_PCincd) + signed(br_operand) );

  -- branch target computation is in the citical path; add early, select late
  br_addend <= displ32(29 downto 0) & b"00";
  U_BR_tgt_pl_4:     mf_alt_add_4 port map (RF_PCincd, br_tgt_pl4);
  U_BR_tgt_pl_displ: mf_alt_adder port map (RF_PCincd, br_addend, br_tgt_displ);
    
  with br_opr select
    br_target <= br_tgt_pl4    when b"01",
                 br_tgt_displ  when b"10",
                 RF_PCincd     when others;
  
  
  RF_DECODE_FUNCT: process (opcode,IF_RF_ld,ctrl_word,funct_word,rimm_word,
                            func,shamt, a_rs,a_rd, STATUS,
                            RF_excp_type,RF_instruction)
    variable i_wreg : std_logic;
    variable i_csel : reg2;
    variable i_oper : t_alu_fun := opNOP;
    variable i_exception : exception_type;
    variable i_trap : instr_type;
    variable i_cop0_reg : reg5;
    variable i_cop0_sel : reg3;
  begin

    i_wreg := '1';
    i_exception := exNOP;
    i_oper := opNOP;
    i_csel := "00";
    i_trap := NOP;
    i_cop0_reg := b"00000";
    i_cop0_sel := b"000";

    case opcode is
      when b"000000" =>                 -- ALU
        i_wreg := funct_word.wreg;
        selB   <= funct_word.selB;
        i_oper := funct_word.oper;
        muxC   <= funct_word.muxC;
        i_csel := ctrl_word.c_sel;
        PCsel  <= funct_word.PCsel;
        i_trap := funct_word.i;
        if (funct_word.trap = '1') then  -- traps
          case funct_word.i is
            when SYSCALL => i_exception := exSYSCALL;
            when BREAK   => i_exception := exBREAK;
            when iSLL    =>
              if RF_instruction = x"000000c0" then 
                i_exception := exEHB;
              end if; 
            when others  => i_exception := exNOP;
          end case;
        end if;

      when b"000001" =>                 -- register immediate
        i_wreg := rimm_word.wreg;
        selB   <= rimm_word.selB;
        muxC   <= rimm_word.muxC;
        i_csel := rimm_word.c_sel;
        PCsel  <= rimm_word.PCsel;
        i_trap := rimm_word.i;
        i_oper := opNOP;                -- no ALU operation        

        if (rimm_word.trap = '1') then  -- traps
          i_exception := exNOP;
        end if;

      when b"010000" =>                 -- COP-0
        i_cop0_reg := a_rd;
        i_cop0_sel := func(2 downto 0);
        case a_rs is
          when b"00100" =>              -- MTC0
            i_exception := exMTC0;
          when b"00000" =>              -- MFC0
            i_exception := exMFC0;
            i_wreg     := '0';
          when b"10000" =>              -- ERET
            case func is
              when b"000001" => i_exception := exTLBR;
              when b"000010" => i_exception := exTLBWI;
              when b"000110" => i_exception := exTLBWR;
              when b"001000" => i_exception := exTLBP;
              when b"011000" => i_exception := exERET;
              when b"011111" => i_exception := exDERET;
              when b"100000" => i_exception := exWAIT;
              when others =>    i_exception := exRESV_INSTR;
            end case;
          when b"01011" =>              -- EI and DI
            case func is
              when b"100000" =>    -- EI;
                i_exception := exEI;
                i_wreg := '0';
              when b"000000" =>    -- DI;
                i_exception := exDI;
                i_wreg := '0';
              when others => i_exception := exRESV_INSTR;
            end case;
          when others => i_exception := exRESV_INSTR;
        end case;
        selB   <= '0';
        i_oper := opNOP;
        muxC   <= ctrl_word.muxC;
        i_csel := ctrl_word.c_sel;
        PCsel  <= ctrl_word.PCsel;

      when b"011100" =>                 -- special2
        i_wreg := ctrl_word.wreg;
        selB   <= ctrl_word.selB;
        muxC   <= ctrl_word.muxC;
        i_csel := ctrl_word.c_sel;
        PCsel  <= ctrl_word.PCsel;
        case func is
          when b"000010" =>             -- MUL R[rd] <= R[rs]*R[rt]
            i_oper := opMUL;
          when others =>
            i_oper := opNOP;
            i_exception := exRESV_INSTR;
        end case;            

      when b"011111" =>                 -- special3
        case func is
          when b"100000" =>             -- BSHFL 
            i_csel := ctrl_word.c_sel;
            case shamt is
              when b"00010" =>          -- word swap bytes within halfwords
                i_oper := opSWAP;
              when b"10000" =>          -- sign-extend byte
                i_oper := opSEB;
              when b"11000" =>          -- sign-extend halfword
                i_oper := opSEH;
              when  others =>
                i_oper := opNOP;
            end case;
          when b"000000" =>             -- extract bit field
            i_csel := b"01";             -- dest = rt
            i_oper := opEXT;
          when b"000100" =>             -- insert bit field
            i_csel := b"01";            -- dest = rt
            i_oper := opINS;
          when others => i_exception := exRESV_INSTR;
        end case;
        i_wreg := ctrl_word.wreg;
        selB   <= ctrl_word.selB;
        muxC   <= ctrl_word.muxC;
        PCsel  <= ctrl_word.PCsel;

      when others =>
        case opcode is
          when b"110000" => i_exception := exLL;  -- not REALLY exceptions
          when b"111000" => i_exception := exSC;
          when others    => null; -- i_exception := exRESV_INSTR;
        end case;
        i_wreg := ctrl_word.wreg;
        selB   <= ctrl_word.selB;
        i_oper := ctrl_word.oper;
        muxC   <= ctrl_word.muxC;
        i_csel := ctrl_word.c_sel;
        PCsel  <= ctrl_word.PCsel;
    end case;
    oper  <= i_oper;
    c_sel <= i_csel;
    trap_instr <= i_trap;
    cop0_reg   <= i_cop0_reg;
    cop0_sel   <= i_cop0_sel;

    if IF_RF_ld = '1' then              -- bubble (OR flush_RF_EX)
      wreg      <= '1';
      aVal      <= '1';
      wrmem     <= '1';
      exception <= exNOP;
    else
      wreg      <= i_wreg;
      aVal      <= ctrl_word.aVal;
      wrmem     <= ctrl_word.wmem;
      exception <= i_exception;
    end if;
  end process RF_DECODE_FUNCT;

  -- exception_dec <= exception_type'pos(exception);  -- debugging only
 
  can_trap <= ctrl_word.excp or funct_word.excp or rimm_word.excp;
  
  RF_DECODE_MEM_REF: process (ctrl_word)
    variable i_type : reg4;
    -- bit3: LWL,LWR=1, bit2: signed=1, bits10:xx,byte,half,word
  begin
    case ctrl_word.i is
      when LB        => i_type := b"0101";  -- signed, byte (sign extend)
      when LH        => i_type := b"0110";  -- signed, half-word
      when LW | LL   => i_type := b"0011";  -- word
      when LBU       => i_type := b"0001";  -- unsigned, byte (zero extend)
      when LHU       => i_type := b"0010";  -- unsigned, half-word
      when SB        => i_type := b"0001";
      when SH        => i_type := b"0010";
      when SW | SC   => i_type := b"0011";
      when LWL       => i_type := b"1011";  -- unaligned LOADS
      when LWR       => i_type := b"1111";  -- unaligned LOADS
      when others    => i_type := b"0000";
    end case;
    mem_t <= i_type;
  end process RF_DECODE_MEM_REF;

  with c_sel select                     -- select destination register
    a_c <= a_rd when b"00",  -- type-R
           a_rt when b"01",  -- type-I
           b"11111" when b"10", -- jal
           b"00000" when others;

  PIPESTAGE_RF_EX: reg_RF_EX
    port map (clk,rst, RF_EX_ld, selB,EX_selB, oper,EX_oper,
              a_rs,EX_a_rs, a_rt,EX_a_rt, a_c,EX_a_c,
              wreg,EX_wreg_pre, muxC,EX_muxC, move,EX_move,
              a_rd,EX_postn, shamt,EX_shamt, aVal,EX_aVal,
              wrmem,EX_wrmem, mem_t,EX_mem_t, is_load,EX_is_load, 
              regs_A,EX_A, regs_B,EX_B, displ32,EX_displ32,
              pc_p8,EX_pc_p8);


  -- EXECUTION ---------------------------------------------

  EX_FORWARDING_ALU: process (EX_a_rs,EX_a_rt,EX_a_c, EX_A,EX_B,
                              MM_ll_sc_abort, MM_is_SC,
                              MM_a_c,MM_wreg,WB_a_c,WB_wreg,
                              MM_is_MFC0,MM_cop0_val, MM_result,WB_C)
    variable i_A,i_B : reg32;
  begin
    FORWARD_A:
    if ((MM_wreg = '0')and(MM_a_c /= b"00000")and(MM_a_c = EX_a_rs)) then
      if MM_is_MFC0 then
        i_A := MM_cop0_val;
      elsif MM_is_SC then
        i_A := x"0000000" & b"000" & not( BOOL2SL(MM_ll_sc_abort) );
      else 
        i_A := MM_result;
      end if;
    elsif ((WB_wreg = '0')and(WB_a_c /= b"00000")and(WB_a_c = EX_a_rs)) then
      i_A := WB_C;
    else
      i_A := EX_A;
    end if;
    alu_inp_A <= i_A;
    assert TRUE report -- DEBUG
       "FWD_A: alu_A="&SLV32HEX(alu_inp_A)&" alu_B="&SLV32HEX(alu_fwd_B);

    
    FORWARD_B:
    if ((MM_wreg = '0')and(MM_a_c /= b"00000")and(MM_a_c = EX_a_rt)) then
      if MM_is_MFC0 then
        i_B := MM_cop0_val;
      elsif MM_is_SC then
        i_B := x"0000000" & b"000" & not( BOOL2SL(MM_ll_sc_abort) );
      else 
        i_B := MM_result;
      end if;
    elsif ((WB_wreg = '0')and(WB_a_c /= b"00000")and(WB_a_c = EX_a_rt)) then
      i_B := WB_C;
    else
      i_B := EX_B;
    end if;
    alu_fwd_B <= i_B;
    assert TRUE report -- DEBUG
      "FWD_B: alu_A="&SLV32HEX(alu_inp_A)&" alu_B="&SLV32HEX(alu_fwd_B);
  end process EX_FORWARDING_ALU;
  
  alu_inp_B <= alu_fwd_B when (EX_selB = '0') else EX_displ32;

  U_ALU: alu port map(clk,rst,
                      alu_inp_A, alu_inp_B, result, LO, HI, annul_twice,
                      alu_move_ok, EX_oper,EX_postn,EX_shamt, ovfl);

  
  -- this adder performs address calculation so the TLB can be checked during
  --   EX and thus signal an exception as early as possible
  U_VIR_ADDR_ADD: mf_alt_adder port map (alu_inp_A, EX_displ32, v_addr);
  

  U_EX_ADDR_ERR_EXCP: process(EX_mem_t,EX_aVal,EX_wrmem, v_addr)
    variable i_stage_mm, i_addrError : boolean;
    variable i_excp_type : exception_type;
  begin

    case EX_mem_t(1 downto 0) is  -- xx,by,hf,wd
      when b"11" =>
        if ( EX_mem_t(3) = '0' and         -- normal LOAD, not LWL,LWR
             EX_aVal = '0' and v_addr(1 downto 0) /= b"00" ) then
          if EX_wrmem = '1' then
            i_excp_type := MMaddressErrorLD;
          else
            i_excp_type := MMaddressErrorST;
          end if;
          i_addrError := TRUE;
          i_stage_mm  := TRUE;
        else
          i_excp_type  := exNOP;
          i_addrError  := FALSE;
          i_stage_mm   := FALSE;
        end if;

      when b"10" =>                        -- LH*, SH
        if EX_aVal = '0' and v_addr(0) /= '0' then
          if EX_wrmem = '1' then
            i_excp_type := MMaddressErrorLD;
          else
            i_excp_type := MMaddressErrorST;
          end if;
          i_addrError := TRUE;
          i_stage_mm  := TRUE;
        else
          i_excp_type  := exNOP;
          i_addrError  := FALSE;
          i_stage_mm   := FALSE;
        end if;
        
      when others =>                      -- LB*, SB
        i_excp_type  := exNOP;
        i_addrError  := FALSE;
        i_stage_mm   := FALSE;
    end case;

    mem_excp_type    <= i_excp_type;
    addrErr_stage_mm <= i_stage_mm;
    addrError        <= i_addrError;
    
    -- assert mem_excp_type = exNOP  -- DEBUG
    --   report LF & "SIMULATION ERROR -- data addressing error: " &
    --   integer'image(exception_type'pos(mem_excp_type)) &
    --   " at address: " & SLV32HEX(v_addr)
    --   severity error;

  end process U_EX_ADDR_ERR_EXCP; ----------------------------------


  -- uncomment this when making use of the TLB CHANGE
  EX_addr <= phy_d_addr;                -- with TLB

  -- uncomment this when NOT making use of the TLB
  -- EX_addr <= v_addr;                    -- without TLB  

  -- assert ( (phy_d_addr = v_addr) and (EX_aVal = '0') )  -- DEBUG
  --  report LF&"mapping mismatch V:P "&SLV32HEX(v_addr)&":"&SLV32HEX(phy_d_addr);


  EX_wreg <= EX_wreg_pre                  -- movz,movn, move/DO_NOT move
             or ( BOOL2SL(nullify) and not(MM_is_delayslot) );
                                          -- abort wr if prev excep in EX

  EX_wrmem_cond <= EX_wrmem
                   or BOOL2SL(abort_ref)  -- abort write if exception in MEM
                   or LL_SC_abort         -- SC is to be killed
                   -- abort memWrite if exception in EX, but not in IF
                   or ( BOOL2SL(nullify) and
                        (MM_is_delayslot and not BOOL2SL(nullify_fetch)) )
                   or ( BOOL2SL(nullify) and not BOOL2SL(nullify_fetch) );
  -- check_this
  
  EX_aVal_cond <= EX_aVal
                  or BOOL2SL(abort_ref)  -- abort ref if exception in MEM
                  or LL_SC_abort         -- SC is to be killed
                  -- abort memWrite if exception in EX, but not in IF
                  or ( BOOL2SL(nullify) and
                       (MM_is_delayslot and not BOOL2SL(nullify_fetch)) )
                  or ( BOOL2SL(nullify) and not BOOL2SL(nullify_fetch) );
  -- check_this
  
  abort_ref <= (addrError or (tlb_exception and tlb_stage_mm));

  busFree <= EX_aVal_cond;

  -- ----------------------------------------------------------------------
  PIPESTAGE_EX_MM: reg_EX_MM
    port map (clk,rst, EX_MM_ld,
              EX_a_rt,MM_a_rt, EX_a_c,MM_a_c, EX_wreg,MM_wreg,
              EX_muxC,MM_muxC, EX_aVal_cond,MM_aVal, EX_wrmem_cond,MM_wrmem,
              EX_mem_t,MM_mem_t, EX_is_load,MM_is_load, 
              EX_A,MM_A, alu_fwd_B,MM_B,
              result,MM_result, EX_addr,MM_addr,
              HI,MM_HI, LO,MM_LO,
              alu_move_ok,MM_alu_move_ok, EX_move,MM_move,
              EX_pc_p8,MM_pc_p8);


  -- MEMORY ---------------------------------------------------------------

  -- DATA_BUS_STATE_MACHINE: data-bus control
  U_dmem_stalled: FFD port map (clk => phi2, rst => rst, set => '1',
                                D => mem_stall, Q => mm_stalled);

  d_aVal <= MM_aVal;  -- interface signal/port
  daVal  <= MM_aVal;  -- internal signal
  
  ram_stall <= not(daVal) and not(d_wait);
  -- end DATA_BUS_STATE_MACHINE -------------------------------------
 
  wr <= MM_wrmem;                -- abort write if SC fails

  
  rd_data_raw <= data_inp when (MM_wrmem = '1' and MM_aVal = '0') else
                 (others => 'X');
  
  MM_MEM_CTRL_INTERFACE: process(MM_mem_t, MM_addr)
    variable i_d_addr   : reg2;
    variable i_byte_sel : reg4;
  begin

    case MM_mem_t(1 downto 0) is                -- xx,by,hf,wd
      when b"11" =>
        i_byte_sel := b"1111";                  -- LW, SW, LWL, LWR
        i_d_addr   := b"00";                    -- align reference
        
      when b"10" =>
        i_d_addr     := MM_addr(1) & '0';       -- align reference
        if MM_addr(1) = '0' then                -- LH*, SH
          i_byte_sel := b"0011";
        else
          i_byte_sel := b"1100";
        end if;

      when b"01" =>                             -- LB*, SB
        i_d_addr := MM_addr(1 downto 0);
        case MM_addr(1 downto 0) is
          when b"00"  => i_byte_sel := b"0001";
          when b"01"  => i_byte_sel := b"0010";
          when b"10"  => i_byte_sel := b"0100";
          when others => i_byte_sel := b"1000";
        end case;
        
      when others =>
        i_d_addr   := (others => 'X');          -- MM_addr;
        i_byte_sel := b"0000";

    end case;

    d_addr     <= MM_addr(31 downto 2) & i_d_addr;
    b_sel      <= i_byte_sel;

  end process MM_MEM_CTRL_INTERFACE; ---------------------------------


  MM_MEM_DATA_INTERFACE: process(MM_mem_t, MM_addr, rd_data_raw)
    variable bytes_read : reg32;
    variable i_byte : reg8;
    variable i_half : reg16;
    constant c_24_ones  : reg24 := b"111111111111111111111111";
    constant c_24_zeros : reg24 := b"000000000000000000000000";
    constant c_16_ones  : reg16 := b"1111111111111111";
    constant c_16_zeros : reg16 := b"0000000000000000";
  begin

    case MM_mem_t(1 downto 0) is  -- 10:xx,by,hf,wd
      when b"11" =>
        bytes_read := rd_data_raw;
        
      when b"10" =>
        if MM_addr(1) = '0' then                      -- LH*, SH
          i_half     := rd_data_raw(15 downto 0);
        else
          i_half     := rd_data_raw(31 downto 16);
        end if;
        if MM_mem_t(2) = '1' and i_half(15) = '1' then  -- mem_t(2):signed=1
          bytes_read := c_16_ones  & i_half;
        else
          bytes_read := c_16_zeros & i_half;
        end if;

      when b"01" =>                                     -- LB*, SB
        case MM_addr(1 downto 0) is
          when b"00"  => i_byte := rd_data_raw(7  downto  0);
          when b"01"  => i_byte := rd_data_raw(15 downto  8);
          when b"10"  => i_byte := rd_data_raw(23 downto 16);
          when others => i_byte := rd_data_raw(31 downto 24);
        end case;
        if MM_mem_t(2) = '1' and i_byte(7) = '1' then -- mem_t(2):signed=1
          bytes_read := c_24_ones  & i_byte;
        else
          bytes_read := c_24_zeros & i_byte;
        end if;
        
      when others =>
        bytes_read := (others => 'X');

    end case;

    rd_data  <= bytes_read;

  end process MM_MEM_DATA_INTERFACE; ---------------------------------

  
  -- forwarding for LW -> SW 
  MM_FORWARDING_MEM: process (MM_aVal,MM_wrmem,MM_a_rt,WB_a_c,WB_wreg,WB_C,MM_B)
    variable f_m: reg2;
    variable i_data : reg32;
  begin
    f_m := "XX";
    if ( (MM_wrmem = '0') and (MM_aVal = '0') ) then
      if ( (MM_a_rt = WB_a_c) and (WB_wreg = '0') and (WB_a_c /= b"00000")) then
        f_m    := "01";                 -- forward from WB
        i_data := WB_C;
      else
        f_m    := "00";                 -- not forwarding
        i_data := MM_B;
      end if;
    else
      f_m    := "11";                   -- not a write, (others=>'Z')
      i_data := (others => 'X');
    end if;
    fwd_mem  <= f_m;                    -- for debugging
    data_out <= i_data;
  end process MM_FORWARDING_MEM; -------------------------------


  -- forwarding for LWL, LWR
  MM_FWD_LWLR: process (MM_aVal,MM_wreg,MM_a_rt,WB_a_c,WB_wreg,WB_C,MM_B)
    variable f_m: boolean;
    variable i_data : reg32;
  begin
    if ( (MM_wreg = '0') and (MM_aVal = '0') and
         (MM_a_rt = WB_a_c) and (WB_wreg = '0') and
         (WB_a_c /= b"00000") ) then
      f_m    := TRUE;                 -- forward from WB
      i_data := WB_C;
    else
      f_m    := FALSE;                -- not forwarding
      i_data := MM_B;
    end if;
    fwd_lwlr  <= f_m;                 -- for debugging
    MM_B_data <= i_data;
  end process MM_FWD_LWLR;

  -- if interrupt is in J/BR delaySlot, and JR was stalled, kill instr in MM
  U_NULLIFY_THRICE:
    FFD port map (clk, rst, '1', nullify_MM_pre, nullify_MM_int);
  
  MM_wreg_cond <= '1' when ( (ram_stall = '1')
                             or MM_addrError -- abort regWrite if excptn in MEM
                             or (MM_move = '1' and MM_alu_move_ok = '0')
                             or (nullify_MM_int = '1')
                           )
                  else MM_wreg;


  -- ----------------------------------------------------------------------
  PIPESTAGE_MM_WB: reg_MM_WB
    port map (clk,rst, MM_WB_ld, 
              MM_a_c,WB_a_c, MM_wreg_cond,WB_wreg, MM_muxC,WB_muxC,
              MM_A,WB_A, MM_result,WB_result, MM_HI,WB_HI,MM_LO,WB_LO,
              rd_data,WB_rd_data, MM_B_data,WB_B_data,
              MM_addr(1 downto 0),WB_addr2, MM_mem_t(3 downto 2),WB_mem_t,
              MM_pc_p8,WB_pc_p8);

  -- WRITE BACK -----------------------------------------------------------

  
  -- merge unaligned loads  LWL,LWR
  mergeLOAD: process (WB_rd_data, WB_B_data, WB_addr2, WB_mem_t)
    variable mem, reg, res : reg32;
  begin
    mem := WB_rd_data;
    reg := WB_B_data;

    case WB_mem_t is
         
      when "10" =>   -- LWL
        case WB_addr2 is
          when "00" =>
            res := mem( 7 downto  0) & reg(23 downto 0);
          when "01" =>
            res := mem(15 downto  0) & reg(15 downto 0);
          when "10" =>
            res := mem(23 downto  0) & reg( 7 downto 0);
          when others =>
            res := mem;
        end case;

      when "11" =>   -- LWR
        case WB_addr2 is
          when "01" =>
            res := reg(31 downto 24) & mem(31 downto  8);
          when "10" =>
            res := reg(31 downto 16) & mem(31 downto 16);
          when "11" =>
            res := reg(31 downto  8) & mem(31 downto 24);
          when others =>
            res := mem;
        end case;

      when others =>  -- normal LOAD
        res := mem;
    end case;
    WB_mem_data <= res;
  end process mergeLOAD;

      
  with WB_muxC select WB_C <=
    WB_mem_data  when b"000",           -- from memory
    WB_result    when b"001",           -- from ALU
    WB_A         when b"010",           -- A, for jr
    WB_pc_p8     when b"011",           -- PC+8 for jal
    WB_HI        when b"100",           -- MFHI
    WB_LO        when b"101",           -- MFLO
    WB_cop0_val  when b"110",           -- from COP0 registers
    (x"0000000" & b"000" & WB_LLbit) when b"111",  -- from LLbit
    (others => 'X') when others;           -- invalid selection

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- end of data pipeline 
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  
  
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
  -- control pipeline 
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- IF instruction fetch ---------------------------------------------
  
  PIPESTAGE_EXCP_IF_RF: reg_excp_IF_RF
    port map (clk, rst, excp_IF_RF_ld,
              IF_excp_type,RF_excp_type, PC_abort,RF_PC_abort, PC,RF_PC);


  -- RF decode & register fetch ---------------------------------------------


  RF_FORWARDING_TRAPS: process (a_rs,a_rt,rimm_word,displ32,
                                EX_wreg,EX_a_c,MM_wreg,MM_a_c,
                                MM_aVal,MM_result,regs_A,regs_B,is_trap)
  begin
    tr_stall <= '0';

    if ( (is_trap = '1') and          -- forward_A:
         (EX_wreg = '0') and (EX_a_c = a_rs) and (EX_a_c /= b"00000") ) then
      tr_stall <= '1';
      tr_fwd_A <= regs_A;
    elsif ((MM_wreg = '0') and (MM_a_c = a_rs) and (MM_a_c /= b"00000")) then
      if (MM_aVal = '0') then    -- LW load-delay slot
        if (is_trap = '1') then
          tr_stall <= '1';
        end if;
        tr_fwd_A <= regs_A;
      else    -- non-LW
        tr_fwd_A <= MM_result;
      end if;
    else
      tr_fwd_A <= regs_A;
    end if;

    if ( (is_trap = '1') and (rimm_word.selB = '1') ) then -- from immediate
         tr_fwd_B <= displ32;
    elsif ( (is_trap = '1') and          -- forward_B:
         (EX_wreg = '0') and (EX_a_c = a_rt) and (EX_a_c /= b"00000") ) then
      tr_stall <= '1';
      tr_fwd_B <= regs_B;
    elsif ((MM_wreg = '0') and (MM_a_c = a_rt) and (MM_a_c /= b"00000")) then
      if (MM_aVal = '0') then    -- LW load-delay slot
        if (is_trap = '1') then
          tr_stall <= '1';
        end if;
        tr_fwd_B <= regs_B;
      else    -- non-LW
        tr_fwd_B <= MM_result;
      end if;
    else
      tr_fwd_B <= regs_B;
    end if;
  end process RF_FORWARDING_TRAPS;

  tr_signed <= '0' when ((funct_word.trap = '1' and
                          ((funct_word.oper = trGEU)or(funct_word.oper = trLTU)))
                         or
                         (rimm_word.trap = '1' and
                          ((rimm_word.br_t = tGEU)or(rimm_word.br_t = tLTU))))
               else '1';
  
  tr_is_equal <= '1' when (tr_fwd_A = tr_fwd_B) else '0';

  U_COMP_TRAP: subtr32
    port map (tr_fwd_A, tr_fwd_B, tr_result, tr_signed, open, tr_less_than);

  trap_dec <= instr_type'pos(trap_instr);  -- debugging only
  
  RF_EVALUATE_TRAPS: process (trap_instr, tr_is_equal, tr_less_than)
    variable i_take_trap : boolean;
  begin
    case trap_instr is
      when TEQ | TEQI =>
        i_take_trap := tr_is_equal = '1';
      when TNE | TNEI =>
        i_take_trap := tr_is_equal = '0';
      when TLT | TLTI | TLTU | TLTIU =>
        i_take_trap := tr_less_than = '1';
      when TGE | TGEI | TGEU | TGEIU =>
        i_take_trap := tr_less_than = '0';
      when others =>
        i_take_trap := FALSE;
    end case;
    trap_taken <= i_take_trap;
  end process RF_EVALUATE_TRAPS;

 -- ----------------------------------------------------------------------    
  PIPESTAGE_EXCP_RF_EX: reg_excp_RF_EX
    port map (clk, rst, excp_RF_EX_ld,
              cop0_reg,EX_cop0_reg, cop0_sel,EX_cop0_sel,
              can_trap,EX_can_trap, 
              exception,EX_exception,
              RF_is_delayslot,EX_is_delayslot,
              RF_PC_abort,EX_PC_abort, RF_PC,EX_PC,
              trap_taken,EX_trapped);
  

  is_nmi     <= ( (nmi = '1') and (STATUS(STATUS_ERL) = '0') );

  int_req(5) <= (irq(5) or count_eq_compare);
  int_req(4) <= irq(4);
  int_req(3) <= irq(3);
  int_req(2) <= irq(2);
  int_req(1) <= irq(1);
  int_req(0) <= irq(0);

  interrupt <= int_req(5) or int_req(4) or int_req(3) or int_req(2) or
               int_req(1) or int_req(0) or
               CAUSE(CAUSE_IP1) or CAUSE(CAUSE_IP0);

  is_interr <= ( (interrupt = '1') and
                 (STATUS(STATUS_EXL) = '0') and
                 (STATUS(STATUS_ERL) = '0') and
                 (STATUS(STATUS_IE)  = '1') and
                 (dly_interr = '0')         and
                 (interrupt_taken = '0') );  -- single cycle exception req

  -- While returning from an exception (especially another interrupt),
  --   delay the IRQ to make sure the interrupted instruction completes;
  -- This is needed to ensure forward-progress: at least one instruction
  --   must complete before another interrupt may be taken.
  -- Also, delay the interrupt requests to avoid hazards while
  --   the interrupt-enable bit is changed in the STATUS register.
  
  -- dly_i0 <= '1' when ( (EX_exception = exERET) or  -- forward progress
  --                      (EX_exception = exEI) or    -- interrupt hazard
  --                      (EX_exception = exDI) or    -- interrupt hazard
  --                      (EX_exception = exEHB) or   -- interrupt hazard
  --                      (EX_exception = exMTC0      -- interrupt hazard
  --                       and EX_cop0_reg = cop0reg_STATUS) or
  --                      (EX_exception = exMFC0      -- interrupt hazard
  --                       and EX_cop0_reg = cop0reg_STATUS) ) else
  --           '0';

  dly_i0 <= '1' when ( EX_exception /= exNOP ) else '0';

  
  U_DLY_INT1: FFD port map (clk, rst, '1',dly_i0, dly_i1);
  U_DLY_INT2: FFD port map (clk, rst, '1',dly_i1, dly_i2);
  dly_interr <= dly_i0 or dly_i1 or dly_i2;

  
  -- check for overflow in EX, send it to MM for later processing
  is_ovfl <= (EX_can_trap = b"10" and ovfl = '1');

  is_SC   <= (EX_exception = exSC);       -- is StoreConditional?  (alu_fwd)
  is_mfc0 <= (EX_exception = exMFC0);     -- is MFC0?  (alu_fwd)

  
  -- priority is always given to events later in the pipeline
  busError_type <= exDBE when d_busErr = '0' else
                   exIBE when i_busErr = '0' else
                   exNOP;
  is_busError   <= (i_busErr = '0') or (d_busErr = '0');


  EX_is_exception <= busError_type   when is_busError   else
                     TLB_excp_type   when tlb_exception else
                     mem_excp_type   when addrError     else
                     IFaddressError  when EX_PC_abort   else
                     exTrap          when EX_trapped    else
                     exOvfl          when is_ovfl       else
                     exNMI           when is_nmi        else
                     exInterr        when is_interr     else
                     EX_exception;

  exception_dec <= exception_type'pos(EX_is_exception);  -- debugging only
  
  -- ----------------------------------------------------------------------
  PIPESTAGE_EXCP_EX_MM: reg_excp_EX_MM
    port map (clk, rst, excp_EX_MM_ld,
              EX_cop0_reg, MM_cop0_reg, EX_cop0_sel, MM_cop0_sel,
              EX_PC,MM_PC, v_addr,MM_v_addr, nullify,MM_nullify,
              addrError,MM_addrError,
              addrErr_stage_mm,MM_addrErr_stage_mm,
              EX_is_delayslot,MM_is_delayslot,
              EX_trapped,MM_trapped,
              SL2BOOL(LL_SC_abort), MM_ll_sc_abort,
              tlb_exception,MM_tlb_exception,
              tlb_stage_mm,MM_tlb_stage_mm,
              int_req,MM_int_req,
              is_SC, MM_is_SC, is_MFC0, MM_is_MFC0,
              EX_is_exception, is_exception);

  -- exception_dec <= exception_type'pos(is_exception);  -- debugging only

   
  -- STATUS -- pg 79 -- cop0_12 --------------------
  COP0_DECODE_EXCEPTION_AND_UPDATE_STATUS:
  process (MM_a_rt, is_exception, cop0_inp,
           MM_cop0_reg, MM_cop0_sel,
           RF_is_delayslot, EX_is_delayslot, MM_is_delayslot, WB_is_delayslot,
           rom_stall,ram_stall, STATUS)
    
    variable newSTATUS : reg32;
    variable i_update,i_epc_update,i_stall : std_logic;
    variable i_nullify: boolean;
    variable i_update_r : reg5;
    variable i_epc_source : reg3;

  begin

    newSTATUS    := STATUS;      
    i_epc_update := '1';
    i_epc_source := EPC_src_PC;
    i_update     := '0';
    i_update_r   := b"00000";
    i_stall      := '0';
    i_nullify    := FALSE;

    exception_taken <= '0';
    interrupt_taken <= '0';
    ExcCode         <= cop0code_NULL;
    is_delayslot    <= '0';
    nullify_MM_pre  <= '0';
    
    newSTATUS             := STATUS;    -- preserve as needed
    newSTATUS(STATUS_BEV) := '0';  -- interrupts at offset 0x200, not boot
    newSTATUS(STATUS_CU3) := '0';  -- COP-3 absent (always)
    newSTATUS(STATUS_CU2) := '0';  -- COP-2 absent (always)
    newSTATUS(STATUS_CU1) := '0';  -- COP-1 absent (always)
    newSTATUS(STATUS_CU0) := '1';  -- COP-0 present=1 (always)
    newSTATUS(STATUS_RP)  := '0';  -- reduced power (always)
    
    case is_exception is

      when exMTC0 =>            -- move to COP-0
        i_update_r := MM_cop0_reg;
        case MM_cop0_reg is
          when cop0reg_STATUS =>
            newSTATUS := cop0_inp;
            i_update   := '1';
            i_stall    := '0';
          when cop0reg_COUNT    | cop0reg_COMPARE  | cop0reg_CAUSE   |
               cop0reg_EntryLo0 | cop0reg_EntryLo1 | cop0reg_EntryHi |
               cop0reg_Index    | cop0reg_Context  | cop0reg_Wired   =>
            i_update   := '1';
            i_stall    := '0';
          when cop0reg_EPC =>
            i_epc_update := '0';
            i_epc_source := EPC_src_B;
            i_stall      := '0';
          when others =>
            i_stall  := '0';
            i_update := '0';
        end case;
        
      when exEI =>              -- enable interrupts
        newSTATUS(STATUS_IE) := '1';
        i_update   := '1';
        i_update_r := cop0reg_STATUS;
        i_stall    := '0';
        
      when exDI =>              -- disable interrupts
        newSTATUS(STATUS_IE) := '0';
        i_update   := '1';
        i_update_r := cop0reg_STATUS;
        i_stall    := '0';

      when exMFC0 =>                    -- move from COP-0
        i_stall := '0';                 -- register selection below
        
      when exERET =>                    -- EXCEPTION RETURN
        newSTATUS(STATUS_EXL) := '0';   -- leave exception level
        i_update     := '1';
        i_update_r   := cop0reg_STATUS;
        i_stall      := '0';            -- do not stall
        i_nullify    := TRUE;           -- nullify instructions in IF,RF


      -- when processor goes into exception-level, IRQs are ignored,
      --   hence disabled
        
      when exSYSCALL | exBREAK =>       -- SYSCALL, BREAK
        i_stall    := '0';
        if is_exception = exSYSCALL then
          ExcCode <= cop0code_Sys;
        else
          ExcCode <= cop0code_Bp;
        end if;  
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        newSTATUS(STATUS_UM)  := '0';   -- enter kernel mode          
        i_update   := '1';
        i_update_r := cop0reg_STATUS;
        i_stall    := '0';              -- do not stall
        i_epc_update := '0';
        i_nullify    := TRUE;           -- nullify instructions in IF,RF
        exception_taken <= '1';
        if MM_is_delayslot = '1' then   -- instr is in delay slot
          i_epc_source  := EPC_src_WB;  -- re-execute branch/jump
          is_delayslot  <= WB_is_delayslot;
        else
          i_epc_source  := EPC_src_MM;
          is_delayslot  <= MM_is_delayslot;
        end if;


      when exTRAP =>
        ExcCode <= cop0code_Tr;
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        newSTATUS(STATUS_UM)  := '0';   -- enter kernel mode          
        i_update   := '1';
        i_update_r := cop0reg_STATUS;
        i_stall    := '0';
        i_epc_update := '0';
        i_nullify    := TRUE;           -- nullify instructions in IF,RF,EX
        exception_taken <= '1';
        if MM_is_delayslot = '1' then   -- instr is in delay slot
          i_epc_source  := EPC_src_WB;  -- WB_PC, re-execute branch/jump
          is_delayslot  <= WB_is_delayslot;
        else
          i_epc_source  := EPC_src_MM;  -- MM_PC
          is_delayslot  <= MM_is_delayslot;
        end if;

        
      when exLL =>                      -- load linked (not a real exception)
        i_update   := '1';
        i_update_r := cop0reg_LLaddr;

        -- when exSC => null; if treated here, SC might delay an interrupt


      when exRESV_INSTR =>      -- reserved instruction ABORT SIMULATION
          assert FALSE                   -- invalid opcode
            report LF & "invalid opcode (resv instr) at PC="& SLV32HEX(EX_PC)
            severity failure;


      when exOvfl =>                    -- OVERFLOW happened one cycle earlier
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        exception_taken <= '1';
        i_update        := '1';
        i_update_r      := cop0reg_STATUS;
        i_epc_update    := '0';
        ExcCode         <= cop0code_Ov;
        i_nullify       := TRUE;        -- nullify instructions in IF,RF,EX
        if WB_is_delayslot = '1' then   -- instr is in delay slot
          i_epc_source := EPC_src_WB;   -- WB_PC, re-execute branch/jump
          is_delayslot <= WB_is_delayslot;
        else
          i_epc_source := EPC_src_MM;   -- offending instr PC is in MM_PC
          is_delayslot <= MM_is_delayslot;
        end if;
        
        
      when IFaddressError =>            -- fetch from UNALIGNED ADDRESS
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        exception_taken <= '1';
        i_update        := '1';
        i_update_r      := cop0reg_STATUS;
        ExcCode         <= cop0code_AdEL;
        i_nullify       := TRUE;        -- nullify instructions in IF,RF,EX
        i_epc_source    := EPC_src_MM;  -- bad address is in EXCP_MM_PC
        i_epc_update    := '0';
        is_delayslot    <= MM_is_delayslot;

        
      when MMaddressErrorLD | MMaddressErrorST =>
        -- load/store from/to UNALIGNED ADDRESS
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        exception_taken <= '1';
        i_update        := '1';
        i_update_r      := cop0reg_STATUS;
        i_epc_update    := '0';
        i_nullify       := TRUE;        -- nullify instructions in IF,RF,EX
        if is_exception = MMaddressErrorST then
          ExcCode <= cop0code_AdES;
        else
          ExcCode <= cop0code_AdEL;
        end if;
        if WB_is_delayslot = '1' then   -- instr is in delay slot
          i_epc_source := EPC_src_WB;   -- WB_PC, re-execute branch/jump
          is_delayslot <= WB_is_delayslot;
        else
          i_epc_source := EPC_src_MM;   -- offending instr PC is in MM_PC
          is_delayslot <= MM_is_delayslot;
        end if;


      when exEHB =>                     -- stall processor to clear hazards
        i_stall := '1';


      when exTLBP | exTLBR | exTLBWI | exTLBWR =>  -- TLB access
        i_stall := '0';                 -- do not stall the processor
        

      when exTLBrefillIF =>
        ExcCode <= cop0code_TLBL;
        if RF_is_delayslot = '1' then       -- instr is in delay slot
          i_epc_source := EPC_src_EX;       -- EX_PC, re-execute branch/jump
          is_delayslot <= RF_is_delayslot;
        elsif EX_is_delayslot = '1' then
          i_epc_source := EPC_src_MM;       -- MM_PC              check_this
          is_delayslot <= '0';
        else
          i_epc_source := EPC_src_RF;       -- RF_PC              check_this
          is_delayslot <= '0';
        end if;
        newSTATUS(STATUS_EXL) := '1';       -- at exception level
        i_update        := '1';
        i_update_r      := cop0reg_STATUS;
        i_epc_update    := '0';
        i_nullify       := TRUE;            -- nullify instructions in IF,RF,EX
        exception_taken <= '1';        

      when exTLBrefillRD | exTLBrefillWR =>
        case is_exception is
          when exTLBrefillRD =>
            ExcCode <= cop0code_TLBL;
          when exTLBrefillWR =>
            ExcCode <= cop0code_TLBS;
          when others => null;
        end case;
        if WB_is_delayslot = '1' then   -- instr is in delay slot
          i_epc_source := EPC_src_WB;   -- MM_PC, re-execute branch/jump
          is_delayslot <= WB_is_delayslot;
        else
          i_epc_source := EPC_src_MM;   -- EX_PC
          is_delayslot <= MM_is_delayslot;
        end if;
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        i_update     := '1';
        i_update_r   := cop0reg_STATUS;
        i_epc_update := '0';
        i_nullify    := TRUE;           -- nullify instructions in IF,RF,EX
        exception_taken <= '1';
        
      when exTLBdblFaultIF | exTLBinvalIF  =>
        ExcCode <= cop0code_TLBL;
        if RF_is_delayslot = '1' then   -- instr is in delay slot
          i_epc_source := EPC_src_RF;   -- RF_PC, re-execute branch/jump
          is_delayslot <= RF_is_delayslot;              
        else
          i_epc_source := EPC_src_PC;   -- PC
          is_delayslot <= '0';
        end if;
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        i_update     := '1';
        i_update_r   := cop0reg_STATUS;
        i_epc_update := '0';
        i_nullify    := TRUE;           -- nullify instructions in IF,RF,EX


      when exTLBdblFaultRD | exTLBdblFaultWR |
           exTLBinvalRD    | exTLBinvalWR    | exTLBmod =>
        case is_exception is
          when exTLBinvalRD | exTLBdblFaultRD =>
            ExcCode <= cop0code_TLBL;
          when exTLBinvalWR | exTLBdblFaultWR =>
            ExcCode <= cop0code_TLBS;
          when exTLBmod =>
            ExcCode <= cop0code_Mod;
          when others => null;
        end case;
        if WB_is_delayslot = '1' then   -- instr is in delay slot
          i_epc_source := EPC_src_WB;   -- MM_PC, re-execute branch/jump
          is_delayslot <= WB_is_delayslot;              
        else
          i_epc_source := EPC_src_MM;   -- EX_PC
          is_delayslot <= MM_is_delayslot;
        end if;
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        i_update     := '1';
        i_update_r   := cop0reg_STATUS;
        i_epc_update := '0';
        i_nullify    := TRUE;          -- nullify instructions in IF,RF,EX


      when exIBE | exDBE =>             -- BUS ERROR
        if is_exception = exIBE then
          ExcCode <= cop0code_IBE;
        else
          ExcCode <= cop0code_DBE;
        end if;
        newSTATUS(STATUS_EXL) := '1';   -- at exception level
        i_update   := '1';
        i_update_r := cop0reg_STATUS;
        i_nullify  := TRUE;             -- nullify instructions in IF,RF,EX
        exception_taken <= '1';
        
        
      when exInterr =>                  -- normal interrupt
        if (rom_stall = '0') and (ram_stall = '0') then
          assert TRUE report "interrupt PC="&SLV32HEX(PC) severity note;
          interrupt_taken       <= '1';
          newSTATUS(STATUS_UM)  := '0'; -- enter kernel mode          
          newSTATUS(STATUS_EXL) := '1'; -- at exception level
          ExcCode      <= cop0code_Int;
          i_update     := '1';
          i_update_r   := cop0reg_STATUS;
          i_stall      := '0';
          i_epc_update := '0';
          i_nullify    := TRUE;         -- nullify instructions in IF,RF,EX
          if MM_is_delayslot = '1' then -- instr is in delay slot
            i_epc_source   := EPC_src_MM; -- re-execute branch/jump
            is_delayslot   <= MM_is_delayslot;
            nullify_MM_pre <= '1';      -- if stalled, kill instrn in MM
          else
            i_epc_source   := EPC_src_EX;
            is_delayslot   <= EX_is_delayslot;
            nullify_MM_pre <= '0';
          end if;
        end if;

        
      when exNMI =>                   -- non maskable interrupt
        -- assert false report "NMinterrupt PC="&SLV32HEX(PC) severity note;
        exception_taken <= '1';
        newSTATUS(STATUS_BEV) := '1'; -- locationVector at bootstrap
        newSTATUS(STATUS_TS)  := '0'; -- not TLBmatchesSeveral
        newSTATUS(STATUS_SR)  := '0'; -- not softReset
        newSTATUS(STATUS_NMI) := '1'; -- non maskable interrupt
        newSTATUS(STATUS_ERL) := '1'; -- at error level
        i_update   := '1';
        i_update_r := cop0reg_STATUS;
        i_stall    := '0';
        i_epc_update := '0';
        i_nullify    := TRUE;         -- nullify instructions in IF,RF,EX
        if MM_is_delayslot = '1' then -- instr is in delay slot
          i_epc_source   := EPC_src_MM; -- re-execute branch/jump
          is_delayslot   <= MM_is_delayslot;
          nullify_MM_pre <= '1';      -- if stalled, kill instrn in MM
        else
          i_epc_source   := EPC_src_EX;
          is_delayslot   <= EX_is_delayslot;
          nullify_MM_pre <= '0';
        end if;
        
      when others => null;

    end case;

    STATUSinp       <= newSTATUS;
    update          <= i_update;
    update_reg      <= i_update_r;

    if is_exception = exMTC0 and MM_cop0_reg = cop0reg_EPC then
      epc_update    <= i_epc_update;
    else
      epc_update    <= i_epc_update OR STATUS(STATUS_EXL);
    end if;
    epc_source      <= i_epc_source;
    
    exception_stall <= i_stall;
    nullify         <= i_nullify;
    
  end process COP0_DECODE_EXCEPTION_AND_UPDATE_STATUS;


  -- Select value to be read by instruction MFC0 --------------------
  COP0_READ: process (is_exception, MM_cop0_reg, MM_cop0_sel,
                      INDEX, RANDOM, EntryLo0, EntryLo1,
                      CONTEXT, PAGEMASK, WIRED, EntryHi,
                      COUNT, COMPARE, STATUS, CAUSE, EPC, BadVAddr)
    variable i_COP0_rd : reg32;
  begin

    case is_exception is

      when exEI | exDI =>       -- enable/disable interrupts
        i_COP0_rd  := STATUS;

      when exMFC0 =>            -- move from COP-0
        case MM_cop0_reg is
            when cop0reg_Index    => i_COP0_rd := INDEX;
            when cop0reg_Random   => i_COP0_rd := RANDOM;
            when cop0reg_EntryLo0 => i_COP0_rd := EntryLo0;
            when cop0reg_EntryLo1 => i_COP0_rd := EntryLo1;
            when cop0reg_Context  => i_COP0_rd := CONTEXT;
            when cop0reg_PageMask => i_COP0_rd := PAGEMASK;
            when cop0reg_Wired    => i_COP0_rd := WIRED;
            when cop0reg_EntryHi  => i_COP0_rd := EntryHi;
            when cop0reg_COUNT    => i_COP0_rd := COUNT;
            when cop0reg_COMPARE  => i_COP0_rd := COMPARE;
            when cop0reg_STATUS   => i_COP0_rd := STATUS;
            when cop0reg_CAUSE    => i_COP0_rd := CAUSE;
            when cop0reg_EPC      => i_COP0_rd := EPC;
            when cop0reg_BadVAddr => i_COP0_rd := BadVAddr;
            when cop0reg_CONFIG   =>
              if MM_cop0_sel = b"000" then
                i_COP0_rd := CONFIG0;     -- constant
              else
                i_COP0_rd := CONFIG1;     -- constant
              end if;
            when others =>
              i_COP0_rd := STATUS;
        end case;

      when others =>
        i_COP0_rd := STATUS;
        
    end case;

    MM_cop0_val <= i_COP0_rd;
    
  end process COP0_READ;

  
  -- Select input to PC on an exception --------------------
  COP0_SEL_EPC: process (is_exception, STATUS, CAUSE, MM_trapped)
    variable i_excp_PCsel : reg3;
  begin

    case is_exception is

      when exERET =>            -- exception return
        i_excp_PCsel := PCsel_EXC_EPC;    -- PC <= EPC
        
      when exSYSCALL | exBREAK | exRESV_INSTR | exOvfl
           | IFaddressError | MMaddressErrorLD | MMaddressErrorST 
           | exTLBdblFaultIF | exTLBdblFaultRD | exTLBdblFaultWR 
           | exTLBinvalIF | exTLBinvalRD | exTLBinvalWR | exTLBmod
           | exIBE | exDBE =>
        i_excp_PCsel := PCsel_EXC_0180;    -- PC <= exception_180

       when exTRAP =>
         if MM_trapped then
           i_excp_PCsel := PCsel_EXC_0180; -- PC <= exception_180
         else
           i_excp_PCsel := PCsel_EXC_none;
         end if;
        
      when exTLBrefillIF | exTLBrefillRD | exTLBrefillWR =>
        i_excp_PCsel := PCsel_EXC_0000; -- PC <= exception_0000

      when exNMI =>                     -- non maskable interrupt
        i_excp_PCsel := PCsel_EXC_BFC0; -- PC <= 0xBFC0.0000

      when exInterr =>                  -- normal interrupt
        if CAUSE(CAUSE_IV) = '1' then
          i_excp_PCsel := PCsel_EXC_0200; -- PC <= exception_0200
        else
          i_excp_PCsel := PCsel_EXC_0180; -- PC <= exception_0180
        end if;

      -- when exNOP =>
      --   i_excp_PCsel := PCsel_EXC_none; -- no exception, do nothing to PC

      when others =>                    -- should never get here
        i_excp_PCsel := PCsel_EXC_none;

    end case;

    excp_PCsel   <= i_excp_PCsel;
    
  end process COP0_SEL_EPC;


  
  COP0_FORWARDING: process (WB_a_c,WB_wreg,MM_a_rt,WB_C,MM_B)
    variable i_B : reg32;
  begin
    if ((WB_wreg = '0')and(WB_a_c /= b"00000")and(WB_a_c = MM_a_rt)) then
      i_B := WB_C;
    else
      i_B := MM_B;
    end if;
    cop0_inp <= i_B;
  end process COP0_FORWARDING;


  -- STATUS -- pg 79 -- cop0_12 --------------------
  status_update <= '0' when (update = '1' and update_reg = cop0reg_STATUS and
                             not_stalled = '1')
                   else '1';

  COP0_STATUS: register32 generic map (RESET_STATUS)
    port map (clk, rst, status_update, STATUSinp, STATUS);


  
  U_DLY_TLB_EXCP: FFD
    port map (clk, rst, '1', BOOL2SL(tlb_exception), tlb_excp_taken);
    
  -- CAUSE -- pg 92-- cop0_13 --------------------------
  COP0_COMPUTE_CAUSE: process(rst, clk)
                              -- update, update_reg,
                              -- MM_int_req, ExcCode, cop0_inp, is_delayslot,
                              -- count_eq_compare,
                              -- interrupt_taken, exception_taken,
                              -- STATUS)
    variable branch_delay : std_logic;
    variable excp_code : reg5;
  begin

    if (STATUS(STATUS_EXL) = '1') then
      branch_delay := CAUSE(CAUSE_BD);  -- do NOT update
    else
      branch_delay := is_delayslot;     -- may update
    end if;

    if ( (interrupt_taken = '1') or (exception_taken = '1') or
         (tlb_excp_taken = '1') )
    then
      excp_code := ExcCode;             -- record new exception      
    elsif ( (is_exception = exMFC0) and (MM_cop0_reg = cop0reg_CAUSE) ) then
      excp_code := cop0code_NULL;       -- clear code when sw reads CAUSE
    else
      excp_code := CAUSE(CAUSE_ExcCodeHi downto CAUSE_ExcCodeLo);  -- hold
    end if;
    
    if rst = '0' then
      CAUSE <= RESET_CAUSE;
    elsif rising_edge(clk) then
      if (update = '1' and update_reg = cop0reg_CAUSE) then
        CAUSE <= branch_delay &         -- b31, CAUSE_BD
                 count_eq_compare &     -- b30, CAUSE_TI timer interrupt
                 b"00" &                -- b29,28, CAUSE_CE1,CAUSE_CE0
                 cop0_inp(CAUSE_DC) &   -- b27, disable COUNT register
                 '0' &                  -- b26, CAUSE_PCI
                 b"00" &                -- b25,b24, nil
                 cop0_inp(CAUSE_IV) &   -- b23, separate interrupr vector
                 cop0_inp(CAUSE_WP) &   -- b22, watch exception
                 b"000000" &            -- b21..b16, nil
                 MM_int_req(5 downto 0) &   -- b15..b10, update HW IRQs
                 cop0_inp(CAUSE_IP1 downto CAUSE_IP0) &  -- b10,b9, SW IRQs
                 '0' &                  -- b7, nil
                 excp_code &            -- b6..b2, ExcCode
                 b"00";                 -- b1,b0, nil
      else
        CAUSE <= branch_delay &         -- b31, CAUSE_BD
                 count_eq_compare &     -- b30, CAUSE_TI timer interrupt
                 b"00" &                -- b29,b28, CAUSE_CE1,CAUSE_CE0
                 CAUSE(CAUSE_DC) &      -- b27, disable COUNT register
                 '0' &                  -- b26, CAUSE(CAUSE_PCI)
                 b"00" &                -- b25,b24, nil
                 CAUSE(CAUSE_IV) &      -- b23, separate interrupr vector
                 CAUSE(CAUSE_WP) &      -- b22, watch exception
                 b"000000" &            -- b21..b16, nil
                 MM_int_req(5 downto 0) &   -- b15..b10, update HW IRQs
                 CAUSE(CAUSE_IP1 downto CAUSE_IP0) &  -- b10,b9, SW IRQs
                 '0' &                  -- b7, nil
                 excp_code &            -- b6..b2, ExcCode
                 b"00";                 -- b1,b0, nil
      end if;
    end if;

  end process COP0_COMPUTE_CAUSE;


  -- EPC -- pg 97 -- cop0_14 -------------------
  with epc_source select EPCinp <=
    PC              when EPC_src_PC,    -- instr fetch exception
    RF_PC           when EPC_src_RF,    -- invalid instr exception
    EX_PC           when EPC_src_EX,    -- interrupt, eret, overflow
    MM_PC           when EPC_src_MM,    -- data memory exception
    WB_PC           when EPC_src_WB,    -- overflow in a branch delay slot
    MM_B            when EPC_src_B,     -- mtc0
    (others => 'X') when others;        -- invalid selection
    
  COP0_EPC: register32 generic map (x"00000000")
    port map (clk, rst, epc_update, EPCinp, EPC);


  -- COUNT & COMPARE -- pg 75, 78 -----------------
  compare_update <= '0' when (update = '1' and update_reg = cop0reg_COMPARE)
                    else '1';
  
  COP0_COMPARE: register32 generic map(x"00000000")
    port map (clk, rst, compare_update, cop0_inp, COMPARE);

  count_update <= '0' when (update = '1' and update_reg = cop0reg_COUNT)
                    else '1';
  
  COP0_COUNT: counter32 generic map (x"00000001")
    port map (clk, rst, count_update, count_enable, cop0_inp, COUNT);
    -- port map (clk, rst, count_update, PCload, cop0_inp, COUNT); -- DEBUG

  compare_set <= (count_eq_compare or BOOL2SL(COUNT = COMPARE))
                 when compare_update = '1'
                 else '0';
            
  COP0_COUNT_INTERRUPT: FFD
    port map (clk, rst, '1', compare_set, count_eq_compare);
  
  disable_count <= CAUSE(CAUSE_DC) when (CAUSE(CAUSE_DC) /= count_enable)
                   else count_enable;     -- load new CAUSE(CAUSE_DC)
  COP0_DISABLE_COUNT: FFD port map (clk,'1',rst, disable_count, count_enable);

  
  -- BadVAddr -- pg 74 ---------------------------

  U_BadVAddr_UPDATE: process(is_exception, RF_is_delayslot, RF_PC, EX_PC,
                             MM_v_addr)
    variable i_update : std_logic;
  begin
    case is_exception is    
      when IFaddressError | exTLBrefillIF | exTLBdblFaultIF | exTLBinvalIF =>
        if RF_is_delayslot = '1' then       -- instr is in delay slot
          BadVAddr_inp <= EX_PC;
        else
          BadVAddr_inp <= RF_PC;
        end if;
        i_update       := '0';

      when MMaddressErrorLD | MMaddressErrorST | exTLBrefillRD | exTLBrefillWR
           | exTLBdblFaultRD | exTLBdblFaultWR | exTLBinvalRD | exTLBinvalWR
           | exTLBmod =>
        BadVAddr_inp <= MM_v_addr;
        i_update     := '0';
        
      when others =>
        BadVAddr_inp <= (others => 'X');
        i_update       := '1';
    end case;
    BadVAddr_update <= i_update;
  end process U_BadVAddr_UPDATE;

  COP0_BadVAddr: register32 generic map(x"00000000")
    port map (clk, rst, BadVAddr_update, BadVAddr_inp, BadVAddr);


  -- LLaddr & LLbit --------------------------------------------------
  -- check address of SC at stage EX, in time to kill memory reference
  
  LL_update <= '0' when (update = '1' and update_reg = cop0reg_LLAddr)
               else '1';

  COP0_LLaddr: register32 generic map(x"00000000")      -- update at MM
    port map (clk, rst, LL_update, MM_v_addr, LLaddr);

  LL_SC_differ <= '0' when (v_addr = LLaddr) else '1';  -- check at EX

  LL_SC_abort  <= (LL_SC_differ or not(ll_sc_bit))
                  when (EX_exception = exSC) --  and pipe_stall = '0')
                  else '0';
  
  COP0_LLbit: process(rst,clk)
  begin
    if rst = '0' then
      ll_sc_bit <= '0';
    elsif rising_edge(clk) then
      case is_exception is
        when exERET =>
          ll_sc_bit <= '0';            -- break SC -> LL
        when exLL =>
          ll_sc_bit <= not LL_update;  -- update only if instr is an LL
        when others =>
          null;
      end case;
    end if;
  end process COP0_LLbit;

  MM_llbit <= ll_sc_bit and not(BOOL2SL(MM_ll_sc_abort));

  
  -- MMU-TLB ===============================================================

  -- assert false -- true                          -- DEBUG
  --   report "pgSz " & integer'image(PAGE_SZ_BITS) &
  --          " va-1 "& integer'image(VABITS-1) &
  --          " pg+1 "& integer'image(PAGE_SZ_BITS+1) &
  --          " add " & integer'image(VABITS-1 - PAGE_SZ_BITS+1) &
  --          " lef "&integer'image( PC(VABITS-1 downto PAGE_SZ_BITS+1)'left)&
  --          " rig "&integer'image(PC(VABITS-1 downto PAGE_SZ_BITS+1)'right);

  
  -- MMU Index -- cop0_0 -------------------------

  index_update <= '0' when (update = '1' and update_reg = cop0reg_Index)
                  else not(tlb_probe);

  hit_mm_bit <= '0' when (hit_mm = TRUE) else '1';

  with hit_mm_adr select tlb_adr_mm <= "000" when 0,
                                       "001" when 1,
                                       "010" when 2,
                                       "011" when 3,
                                       "100" when 4,
                                       "101" when 5,
                                       "110" when 6,
                                       "111" when 7,
                                       "XXX" when others;
  
  index_inp  <= hit_mm_bit & MMU_IDX_0s & tlb_adr_mm when tlb_probe = '1' else 
                hit_mm_bit & MMU_IDX_0s & cop0_inp(MMU_CAPACITY_BITS-1 downto 0);

  MMU_Index: register32 generic map(x"00000000")
    port map (clk, rst, index_update, index_inp, INDEX);


  -- MMU Wired -- pg 72 -- cop0_6 ----------------

  wired_update <= '0' when (update = '1' and update_reg = cop0reg_Wired)
                  else '1';
  
  wired_inp <= '0' & MMU_IDX_0s & cop0_inp(MMU_CAPACITY_BITS-1 downto 0);

  MMU_Wired: register32 generic map(MMU_WIRED_INIT)
    port map (clk, rst, wired_update, wired_inp, WIRED);

  
  -- MMU Random -- cop0_1 ------------------------

  MMU_Random: process(clk, rst, WIRED, wired_update)
    variable count : integer range -1 to MMU_CAPACITY-1 := MMU_CAPACITY-1;
  begin
    if rst = '0' then
      count := MMU_CAPACITY - 1;
    elsif rising_edge(clk) then
      count := count - 1;
      if count = to_integer(unsigned(WIRED))-1 or wired_update = '0' then
        count := MMU_CAPACITY - 1;
      end if;
      end if;
    RANDOM <= std_logic_vector(to_signed(count, 32));
  end process MMU_Random;

  
  -- MMU EntryLo0 -- pg 63 -- cop0_2 ------------

  entryLo0_update <= '0' when (update = '1' and update_reg = cop0reg_EntryLo0)
                     else not(tlb_read);
  
  entryLo0_inp <= cop0_inp when tlb_read = '0' else tlb_entryLo0;
  
  MMU_EntryLo0: register32 generic map(x"00000000")
    port map (clk, rst, entryLo0_update, entryLo0_inp, EntryLo0);


  -- MMU EntryLo1 -- pg 63 -- cop0_3 ------------  
  
  entryLo1_update <= '0' when (update = '1' and update_reg = cop0reg_EntryLo1)
                  else not(tlb_read);
  
  entryLo1_inp <= cop0_inp when tlb_read = '0' else tlb_entryLo1;
  
  MMU_EntryLo1: register32 generic map(x"00000000")
    port map (clk, rst, entryLo1_update, entryLo1_inp, EntryLo1);


  -- MMU Context -- pg 67 -- cop0_4 ------------

  context_upd_pte <= '0' when (update = '1' and update_reg = cop0reg_Context)
                     else '1';

  --
  -- these registers are non-compliant so the Page Table can be set
  --   at low addresses
  --
  
  -- MMU_ContextPTE: registerN generic map(9, ContextPTE_init)
  --   port map (clk, rst, context_upd_pte,
  --             cop0_inp(31 downto 23), Context(31 downto 23));
  MMU_ContextPTE: registerN generic map(16, b"0000000000000000")
    port map (clk, rst, context_upd_pte,
              cop0_inp(31 downto 16), Context(31 downto 16));

  context_upd_bad <= '0' when MM_tlb_exception else '1';
  
  -- MMU_ContextBAD: registerN generic map(19, b"0000000000000000000")
  --   port map (clk, rst, context_upd_bad, tlb_context_inp, Context(22 downto 4));
  MMU_ContextBAD: registerN generic map(12, b"000000000000")
    port map (clk, rst, context_upd_bad,
              tlb_excp_VA(VA_HI_BIT-7 downto VA_LO_BIT), Context(15 downto 4));

  Context(3 downto 0) <= b"0000";

  
  -- MMU Pagemask -- pg 68 -- cop0_5 ----------- 
  -- page size is fixed = 4k, thus PageMask is not register
  
  -- pageMask_update <= '0' when (update='1' and update_reg=cop0reg_PageMask)
  --                else '1';
  
  -- pageMask_inp <= cop0_inp when tlb_read = '0' else tlb_pageMask_mm;
  
  -- MMU_PageMask: register32 generic map(x"00000000")
  --  port map (clk, rst, pageMask_update, pageMask_inp, PageMask);

  PageMask <= mmu_PageMask;

  
  -- MMU EntryHi -- pg 76 -- cop0_10 -----------  
  -- EntryHi holds the ASID of the current process, to check for a match

  entryHi_update <= '0' when ( (update = '1' and update_reg = cop0reg_EntryHi)
                               or ( MM_tlb_exception ) )
                    else not(tlb_read);
  
  entryHi_inp <= tlb_excp_VA & EHI_ZEROS & EntryHi(EHI_G_BIT) & EntryHi(EHI_ASIDHI_BIT downto EHI_ASIDLO_BIT) when MM_tlb_exception  else
                 cop0_inp  when tlb_read = '0' else
                 tlb_entryhi;
  
  MMU_EntryHi: register32 generic map(x"00000000")
    port map (clk, rst, entryHi_update, entryHi_inp, EntryHi);



  -- == MMU ===============================================================
  
  -- -- pg 41 ----------------------------------
  MMU_exceptions: process(iaVal, EX_wrmem, EX_aVal, hit_mm, hit_pc,
                          hit_mm_v, hit_mm_d, hit_pc_v, STATUS, tlb_ex_2)
    variable i_stage_mm, i_exception, i_miss_mm, i_miss_pc : boolean;
    variable i_excp_type : exception_type;
  begin

    i_miss_pc := not(hit_pc) and (iAval = '0');

    i_miss_mm := not(hit_mm) and (EX_aval = '0');
  
    -- check first for events later in the pipeline: LOADS and STORES

    if i_miss_mm then

      if EX_wrmem = '0' then
        if STATUS(STATUS_EXL) = '1' then
          i_excp_type := exTLBdblFaultWR;
        else
          i_excp_type := exTLBrefillWR;
        end if;
      else
        if STATUS(STATUS_EXL) = '1' then
          i_excp_type := exTLBdblFaultRD;
        else
          i_excp_type := exTLBrefillRD;
        end if;
      end if;
      i_stage_mm  := TRUE;
      i_exception := TRUE;
    
    elsif i_miss_pc then

      if STATUS(STATUS_EXL) = '1' then
        i_excp_type := exTLBdblFaultIF;
      else
        i_excp_type := exTLBrefillIF;
      end if;
      i_exception := TRUE;
      i_stage_mm  := FALSE;
    
    elsif hit_mm and EX_aVal = '0' then

      if hit_mm_v = '0' then      -- check for TLBinvalid
        if EX_wrmem = '0' then
          i_excp_type := exTLBinvalWR;
        else
          i_excp_type := exTLBinvalRD;
        end if;
        i_exception := TRUE;
      elsif (EX_wrmem = '0' and hit_mm_d = '0') then  -- check for TLBmodified
        i_excp_type := exTLBmod;
        i_exception := TRUE;
      else
        i_excp_type := exNOP;
        i_exception := FALSE;
      end if;
      i_stage_mm := TRUE;
      
    elsif (hit_pc and hit_pc_v = '0' and iaVal = '0') then -- TLBinvalid IF?
    
      i_excp_type := exTLBinvalIF;
      i_stage_mm  := FALSE;
      i_exception := TRUE;
    
    else
      i_excp_type := exNOP;
      i_stage_mm  := FALSE;
      i_exception := FALSE;
    end if;

    -- uncomment when making use of the TLB
    TLB_excp_type <= i_excp_type;
    tlb_stage_MM  <= i_stage_mm;
    tlb_exception <= i_exception and not(SL2BOOL(tlb_ex_2));

    -- uncomment when NOT making use of the TLB
    -- TLB_excp_type <= exNOP;
    -- tlb_stage_MM  <= FALSE;
    -- tlb_exception <= FALSE;

  end process MMU_exceptions; -- -----------------------------------------

  -- catch only first exception, if there are two in consecutive cycles
  U_TLB_EXCP_ONCE: FFD port map (clk, rst, '1',
                                 BOOL2SL(tlb_exception), tlb_ex_2);
  
  TLB_excp_num  <= exception_type'pos(TLB_excp_type); -- for debugging only
  
  
  -- MMU TLB TAG-DATA array -- pg 17 ------------------------------------

  -- TLB_tag: 31..13 = VPN, 12..9 = 0, 8 = G, 7..0 = ASID
  -- TLB_dat: 29..6 = PPN, 5..3 = C, 2 = D, 1 = V, 0 = G
  
  MMU_CONTROL: process(is_exception, INDEX, RANDOM)
    variable i_tlb_adr : integer range MMU_CAPACITY-1 downto 0;
  begin

    tlb_tag0_updt <= '1';
    tlb_tag1_updt <= '1';
    tlb_tag2_updt <= '1';
    tlb_tag3_updt <= '1';
    tlb_tag4_updt <= '1';
    tlb_tag5_updt <= '1';
    tlb_tag6_updt <= '1';
    tlb_tag7_updt <= '1';
    
    tlb_dat0_updt <= '1';
    tlb_dat1_updt <= '1';
    tlb_dat2_updt <= '1';
    tlb_dat3_updt <= '1';
    tlb_dat4_updt <= '1';
    tlb_dat5_updt <= '1';
    tlb_dat6_updt <= '1';
    tlb_dat7_updt <= '1';
    
    case is_exception is
      when exTLBP =>
        
        tlb_probe <= '1';
        tlb_read  <= '0';
        i_tlb_adr := 0;

      when exTLBR => 

        tlb_probe <= '0';
        tlb_read  <= '1';
        i_tlb_adr := to_integer(unsigned(INDEX(MMU_CAPACITY-1 downto 0)));

      when exTLBWI | exTLBWR => 

        tlb_probe <= '0';
        tlb_read  <= '0';
        if is_exception = exTLBWI then
          i_tlb_adr := to_integer(unsigned(INDEX(MMU_CAPACITY-1 downto 0)));
        else
          i_tlb_adr := to_integer(unsigned(RANDOM));
        end if;
        case i_tlb_adr is
          when 0 => tlb_tag0_updt <= '0'; tlb_dat0_updt <= '0';
          when 1 => tlb_tag1_updt <= '0'; tlb_dat1_updt <= '0';
          when 2 => tlb_tag2_updt <= '0'; tlb_dat2_updt <= '0';
          when 3 => tlb_tag3_updt <= '0'; tlb_dat3_updt <= '0';
          when 4 => tlb_tag4_updt <= '0'; tlb_dat4_updt <= '0';
          when 5 => tlb_tag5_updt <= '0'; tlb_dat5_updt <= '0';
          when 6 => tlb_tag6_updt <= '0'; tlb_dat6_updt <= '0';
          when 7 => tlb_tag7_updt <= '0'; tlb_dat7_updt <= '0';
          when others => null;
        end case;
          
      when others => 
        tlb_probe <= '0';
        tlb_read  <= '0';
        i_tlb_adr := 0;

    end case;    
    
    tlb_adr <= i_tlb_adr;
    
  end process MMU_CONTROL;  ------------------------------------------------


  with tlb_adr select
    e_hi <= tlb_tag0 when 0,
            tlb_tag1 when 1,
            tlb_tag2 when 2,
            tlb_tag3 when 3,
            tlb_tag4 when 4,
            tlb_tag5 when 5,
            tlb_tag6 when 6,
            tlb_tag7 when others;

  with tlb_adr select
    e_lo0 <= tlb_dat0_0 when 0,
             tlb_dat1_0 when 1,
             tlb_dat2_0 when 2,
             tlb_dat3_0 when 3,
             tlb_dat4_0 when 4,
             tlb_dat5_0 when 5,
             tlb_dat6_0 when 6,
             tlb_dat7_0 when others;

  with tlb_adr select
    e_lo1 <= tlb_dat0_1 when 0,
             tlb_dat1_1 when 1,
             tlb_dat2_1 when 2,
             tlb_dat3_1 when 3,
             tlb_dat4_1 when 4,
             tlb_dat5_1 when 5,
             tlb_dat6_1 when 6,
             tlb_dat7_1 when others;
  
  -- assert false
  -- report "e_hi="&SLV32HEX(e_hi)&" adr="&natural'image(tlb_adr);--DEBUG
  
  -- tlb_entryhi(EHI_AHI_BIT downto EHI_ALO_BIT)
  tlb_entryhi(31 downto PAGE_SZ_BITS + 1)
    <= e_hi(TAG_AHI_BIT downto TAG_ALO_BIT);
  tlb_entryhi(PAGE_SZ_BITS downto EHI_ASIDHI_BIT+1) <= (others => '0');
  tlb_entryhi(EHI_ASIDHI_BIT downto EHI_ASIDLO_BIT)
    <= e_hi(TAG_ASIDHI_BIT downto TAG_ASIDLO_BIT);

  tlb_entryLo0(31 downto ELO_AHI_BIT+1) <= (others => '0');
  tlb_entryLo0(ELO_AHI_BIT downto ELO_ALO_BIT)
    <= e_lo0(DAT_AHI_BIT downto DAT_ALO_BIT);
  tlb_entryLo0(ELO_CHI_BIT  downto ELO_CLO_BIT)
    <= e_lo0(DAT_CHI_BIT  downto DAT_CLO_BIT);
  tlb_entryLo0(ELO_D_BIT) <= e_lo0(DAT_D_BIT);
  tlb_entryLo0(ELO_V_BIT) <= e_lo0(DAT_V_BIT);
  tlb_entryLo0(ELO_G_BIT) <= e_lo0(DAT_G_BIT);
  
  tlb_entryLo1(31 downto ELO_AHI_BIT+1) <= (others => '0');
  tlb_entryLo1(ELO_AHI_BIT downto ELO_ALO_BIT)
    <= e_lo1(DAT_AHI_BIT downto DAT_ALO_BIT);
  tlb_entryLo1(ELO_CHI_BIT  downto ELO_CLO_BIT)
    <= e_lo1(DAT_CHI_BIT  downto DAT_CLO_BIT);
  tlb_entryLo1(ELO_D_BIT) <= e_lo1(DAT_D_BIT);
  tlb_entryLo1(ELO_V_BIT) <= e_lo1(DAT_V_BIT);
  tlb_entryLo1(ELO_G_BIT) <= e_lo1(DAT_G_BIT);


  e_hi_inp <= EntryHi(EHI_AHI_BIT downto EHI_ALO_BIT) & EHI_ZEROS &
              (EntryLo0(ELO_G_BIT) and EntryLo1(ELO_G_BIT)) &
              EntryHi(EHI_ASIDHI_BIT downto EHI_ASIDLO_BIT);  -- pg64

  tlb_tag_inp <= e_hi_inp;

  tlb_dat0_inp <= EntryLo0(ELO_AHI_BIT downto ELO_G_BIT);
        
  tlb_dat1_inp <= EntryLo1(ELO_AHI_BIT downto ELO_G_BIT);


  
  -- MMU TLB TAG+DATA array -------------------------

  mm <= entryHi(EHI_AHI_BIT downto EHI_ALO_BIT) when tlb_probe = '1' else
        v_addr(VA_HI_BIT downto VA_LO_BIT);

  tlb_excp_VA <= MM_v_addr(VA_HI_BIT downto VA_LO_BIT) when MM_tlb_stage_mm else
                 PC(VA_HI_BIT downto VA_LO_BIT);


  -- TLB entry 0 -- initialized to 1st,2nd pages of ROM
  --   this mapping must be pinned down at all times (Wired >= 2, see next entry)
  
  MMU_TAG0: register32 generic map(MMU_ini_tag_ROM0)
    port map (clk, rst, tlb_tag0_updt, tlb_tag_inp, tlb_tag0);

  MMU_DAT0_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_ROM0)
    port map (clk, rst, tlb_dat0_updt, tlb_dat0_inp, tlb_dat0_0);  -- d=1,v=1,g=1
  MMU_DAT0_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_ROM1)
    port map (clk, rst, tlb_dat0_updt, tlb_dat1_inp, tlb_dat0_1);  -- d=1,v=1,g=1

  hit0_pc <= TRUE when (tlb_tag0(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag0(TAG_G_BIT) = '1') OR
                              tlb_tag0(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit0_mm <= TRUE when (tlb_tag0(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag0(TAG_G_BIT) = '1') OR
                              tlb_tag0(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  

  -- TLB entry 1 -- initialized to page with I/O devices
  --   this mapping must be pinned down at all times (Wired >= 2)

  MMU_TAG1: register32 generic map(MMU_ini_tag_IO)
    port map (clk, rst, tlb_tag1_updt, tlb_tag_inp, tlb_tag1);

  MMU_DAT1_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_IO0)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat1_updt, tlb_dat0_inp, tlb_dat1_0);
  MMU_DAT1_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_IO1)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat1_updt, tlb_dat1_inp, tlb_dat1_1);

  hit1_pc <= TRUE when (tlb_tag1(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag1(TAG_G_BIT) = '1') OR
                              tlb_tag1(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit1_mm <= TRUE when (tlb_tag1(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag1(TAG_G_BIT) = '1') OR
                              tlb_tag1(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;


  
  -- TLB entry 2 -- initialized to 3rd,4th pages of ROM
  
  MMU_TAG2: register32 generic map(MMU_ini_tag_ROM2)
    port map (clk, rst, tlb_tag2_updt, tlb_tag_inp, tlb_tag2);

  MMU_DAT2_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_ROM2)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat2_updt, tlb_dat0_inp, tlb_dat2_0);
  MMU_DAT2_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_ROM3)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat2_updt, tlb_dat1_inp, tlb_dat2_1);

  hit2_pc <= TRUE when (tlb_tag2(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag2(TAG_G_BIT) = '1') OR
                              tlb_tag2(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit2_mm <= TRUE when (tlb_tag2(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag2(TAG_G_BIT) = '1') OR
                              tlb_tag2(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;



  -- TLB entry 3 -- initialized to 5th,6th pages of ROM
  
  MMU_TAG3: register32 generic map(MMU_ini_tag_ROM4)
    port map (clk, rst, tlb_tag3_updt, tlb_tag_inp, tlb_tag3);

  MMU_DAT3_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_ROM5)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat3_updt, tlb_dat0_inp, tlb_dat3_0);
  MMU_DAT3_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_ROM6)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat3_updt, tlb_dat1_inp, tlb_dat3_1);

  hit3_pc <= TRUE when (tlb_tag3(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag3(TAG_G_BIT) = '1') OR
                              tlb_tag3(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit3_mm <= TRUE when (tlb_tag3(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag3(TAG_G_BIT) = '1') OR
                              tlb_tag3(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;


  
  -- TLB entry 4 -- initialized to 1st,2nd pages of RAM

  MMU_TAG4: register32 generic map(MMU_ini_tag_RAM0)
    port map (clk, rst, tlb_tag4_updt, tlb_tag_inp, tlb_tag4);

  MMU_DAT4_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM0)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat4_updt, tlb_dat0_inp, tlb_dat4_0);
  MMU_DAT4_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM1)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat4_updt, tlb_dat1_inp, tlb_dat4_1);

  hit4_pc <= TRUE when (tlb_tag4(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag4(TAG_G_BIT) = '1') OR
                              tlb_tag4(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit4_mm <= TRUE when (tlb_tag4(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag4(TAG_G_BIT) = '1') OR
                              tlb_tag4(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;


  
  -- TLB entry 5 -- initialized to 3rd,4th pages of RAM
  
  MMU_TAG5: register32 generic map(MMU_ini_tag_RAM2)
    port map (clk, rst, tlb_tag5_updt, tlb_tag_inp, tlb_tag5);

  MMU_DAT5_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM2)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat5_updt, tlb_dat0_inp, tlb_dat5_0);
  MMU_DAT5_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM3)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat5_updt, tlb_dat1_inp, tlb_dat5_1);

  hit5_pc <= TRUE when (tlb_tag5(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag5(TAG_G_BIT) = '1') OR
                              tlb_tag5(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit5_mm <= TRUE when (tlb_tag5(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag5(TAG_G_BIT) = '1') OR
                              tlb_tag5(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;



  -- TLB entry 6 -- initialized to RAM 5th, 6th (1st,2nd pages of SDRAM)
  
  MMU_TAG6: register32 generic map(MMU_ini_tag_RAM4)
    port map (clk, rst, tlb_tag6_updt, tlb_tag_inp, tlb_tag6);

  MMU_DAT6_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM4)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat6_updt, tlb_dat0_inp, tlb_dat6_0);
  MMU_DAT6_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM5)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat6_updt, tlb_dat1_inp, tlb_dat6_1);

  hit6_pc <= TRUE when (tlb_tag6(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag6(TAG_G_BIT) = '1') OR
                              tlb_tag6(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit6_mm <= TRUE when (tlb_tag6(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                        and ( (tlb_tag6(TAG_G_BIT) = '1') OR
                              tlb_tag6(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;


  -- TLB entry 7 -- initialized to 7th,8th pages of RAM = stack
  
  MMU_TAG7: register32 generic map(MMU_ini_tag_RAM6)
    port map (clk, rst, tlb_tag7_updt, tlb_tag_inp, tlb_tag7);

  MMU_DAT7_0: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM6)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat7_updt, tlb_dat0_inp, tlb_dat7_0);
  MMU_DAT7_1: registerN generic map(DAT_REG_BITS, MMU_ini_dat_RAM7)  -- d=1,v=1,g=1
    port map (clk, rst, tlb_dat7_updt, tlb_dat1_inp, tlb_dat7_1);

  hit7_pc <= TRUE when (tlb_tag7(VA_HI_BIT downto VA_LO_BIT) = PC(VA_HI_BIT downto VA_LO_BIT)
                       and ( (tlb_tag7(TAG_G_BIT) = '1') OR
                             tlb_tag7(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  hit7_mm <= TRUE when (tlb_tag7(VA_HI_BIT downto VA_LO_BIT) = mm(VA_HI_BIT downto VA_LO_BIT)
                    and ( (tlb_tag7(TAG_G_BIT) = '1') OR
                          tlb_tag7(ASID_HI_BIT downto 0) = EntryHi(ASID_HI_BIT downto 0) ) )
             else FALSE;

  -- end of TLB TAG+DATA ARRAY ----------------------------------------

  
  -- select mapping for IF --------------------------------------------
  
  tlb_a2_pc <= 4 when (hit4_pc or hit5_pc or hit6_pc or hit7_pc) else 0;
  tlb_a1_pc <= 2 when (hit2_pc or hit3_pc or hit6_pc or hit7_pc) else 0;
  tlb_a0_pc <= 1 when (hit1_pc or hit3_pc or hit5_pc or hit7_pc) else 0;
  
  hit_pc    <= hit0_pc or hit1_pc or hit2_pc or hit3_pc or
               hit4_pc or hit5_pc or hit6_pc or hit7_pc;

  hit_pc_adr <= (tlb_a2_pc + tlb_a1_pc + tlb_a0_pc);

  with hit_pc_adr select
    tlb_ppn_pc0 <= tlb_dat0_0 when 0,
                   tlb_dat1_0 when 1,
                   tlb_dat2_0 when 2,
                   tlb_dat3_0 when 3,
                   tlb_dat4_0 when 4,
                   tlb_dat5_0 when 5,
                   tlb_dat6_0 when 6,
                   tlb_dat7_0 when others;

  with hit_pc_adr select
    tlb_ppn_pc1 <= tlb_dat0_1 when 0,
                   tlb_dat1_1 when 1,
                   tlb_dat2_1 when 2,
                   tlb_dat3_1 when 3,
                   tlb_dat4_1 when 4,
                   tlb_dat5_1 when 5,
                   tlb_dat6_1 when 6,
                   tlb_dat7_1 when others;

  tlb_ppn_pc <= tlb_ppn_pc0(DAT_AHI_BIT downto DAT_ALO_BIT)
                     when PC(PAGE_SZ_BITS) = '0'
                else tlb_ppn_pc1(DAT_AHI_BIT downto DAT_ALO_BIT);

  hit_pc_v   <= tlb_ppn_pc0(DAT_V_BIT) when PC(PAGE_SZ_BITS) = '0' else
                tlb_ppn_pc1(DAT_V_BIT);
  
  phy_i_addr <= tlb_ppn_pc(PPN_BITS-1 downto 0) & PC(PAGE_SZ_BITS-1 downto 0);


  -- select mapping for MM --------------------------------------------

  tlb_a2_mm <= 4 when (hit4_mm or hit5_mm or hit6_mm or hit7_mm) else 0;
  tlb_a1_mm <= 2 when (hit2_mm or hit3_mm or hit6_mm or hit7_mm) else 0;
  tlb_a0_mm <= 1 when (hit1_mm or hit3_mm or hit5_mm or hit7_mm) else 0;
  
  hit_mm    <= (hit0_mm or hit1_mm or hit2_mm or hit3_mm or
                hit4_mm or hit5_mm or hit6_mm or hit7_mm); 
               -- and EX_mem_t /= b"0000";  -- hit AND is load or store

  hit_mm_adr <= (tlb_a2_mm + tlb_a1_mm + tlb_a0_mm);
  
  with hit_mm_adr select
    tlb_ppn_mm0 <= tlb_dat0_0 when 0,
                   tlb_dat1_0 when 1,
                   tlb_dat2_0 when 2,
                   tlb_dat3_0 when 3,
                   tlb_dat4_0 when 4,
                   tlb_dat5_0 when 5,
                   tlb_dat6_0 when 6,
                   tlb_dat7_0 when others;

  with hit_mm_adr select
    tlb_ppn_mm1 <= tlb_dat0_1 when 0,
                   tlb_dat1_1 when 1,
                   tlb_dat2_1 when 2,
                   tlb_dat3_1 when 3,
                   tlb_dat4_1 when 4,
                   tlb_dat5_1 when 5,
                   tlb_dat6_1 when 6,
                   tlb_dat7_1 when others;

  tlb_ppn_mm <= tlb_ppn_mm0(DAT_AHI_BIT downto DAT_ALO_BIT) when v_addr(PAGE_SZ_BITS) = '0' else
                tlb_ppn_mm1(DAT_AHI_BIT downto DAT_ALO_BIT);
  
  hit_mm_v   <= tlb_ppn_mm0(DAT_V_BIT) when v_addr(PAGE_SZ_BITS) = '0' else
                tlb_ppn_mm1(DAT_V_BIT);

  hit_mm_d   <= tlb_ppn_mm0(DAT_D_BIT) when v_addr(PAGE_SZ_BITS) = '0' else
                tlb_ppn_mm1(DAT_D_BIT);

  phy_d_addr <= tlb_ppn_mm(PPN_BITS-1 downto 0) & v_addr(PAGE_SZ_BITS-1 downto 0);

  
  -- MMU-TLB == end =======================================================

    


  -- ----------------------------------------------------------------------    
  PIPESTAGE_EXCP_MM_WB: reg_excp_MM_WB
    port map (clk, rst, excp_MM_WB_ld,
              MM_PC,WB_PC, MM_LLbit,WB_LLbit, 
              MM_is_delayslot,WB_is_delayslot,
              MM_cop0_val,WB_cop0_val);


  -- WB is shared with datapath -------------------------------------------  
  -- nothing to do here

  
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- end of control pipeline 
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
end rtl;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

