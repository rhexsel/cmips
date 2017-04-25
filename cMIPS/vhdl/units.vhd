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
-- Altera's design for a dual-port RAM that can be synthesized
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library ieee;
use ieee.std_logic_1164.all;

entity ram_dual is
  generic (N_WORDS : integer := 64;
           WIDTH : integer := 8);
  port (data  : in std_logic_vector(WIDTH - 1 downto 0);
    raddr : in natural range 0 to N_WORDS - 1;
    waddr : in natural range 0 to N_WORDS - 1;
    we    : in std_logic;
    rclk  : in std_logic;
    wclk  : in std_logic;
    q     : out std_logic_vector(WIDTH - 1 downto 0));
end ram_dual;

architecture rtl of ram_dual is

  -- Build a 2-D array type for the RAM
  subtype word_t is std_logic_vector(WIDTH - 1 downto 0);
  type memory_t is array(N_WORDS - 1 downto 0) of word_t;
  
  -- Declare the RAM signal.
  signal ram : memory_t; --  := (others => (others => '0'));

begin

  process(wclk)
  begin
    if(rising_edge(wclk)) then 
      if(we = '1') then
        ram(waddr) <= data;
      end if;
    end if;
  end process;

  process(rclk)
  begin
    if(rising_edge(rclk)) then
      q <= ram(raddr);
    end if;
  end process;
  
end rtl;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- register bank, reg(0) always 0, write-enable=0
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_Logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity reg_bank is
  port(wrclk, rdclk, wren : in  std_logic;
       a_rs, a_rt, a_rd   : in  reg5;
       C                  : in  reg32;
       A, B               : out reg32);
end reg_bank;


-- -----------------------------------------------------------------------
-- RTL with implicit memory
-- -----------------------------------------------------------------------
architecture rtl of reg_bank is

  type reg_file is array(0 to 31) of reg32;
  signal reg_file_A : reg_file;
  signal reg_file_B : reg_file;
  signal int_rs, int_rt, int_rd : integer range 0 to 31;
  signal pre_A, pre_B : reg32;
begin

  int_rs <= to_integer(unsigned(a_rs));
  int_rt <= to_integer(unsigned(a_rt));
  int_rd <= to_integer(unsigned(a_rd));

  -- forwarding WB -> RF, external to RAM
  A <= C  when (a_rd = a_rs) and (wren = '0') and (a_rs /= b"00000")
       else pre_A when a_rs /= b"00000"
       else x"00000000";                        -- reg0 always zero
  B <= C  when (a_rd = a_rt) and (wren = '0') and (a_rt /= b"00000")
       else pre_B when a_rt /= b"00000"
       else x"00000000";

  WRITE_REG_BANKS: process(wrclk, rdclk)
  begin
    if rising_edge(rdclk) then          -- read early
      pre_A <= reg_file_A( int_rs );
      pre_B <= reg_file_B( int_rt );
    end if;

    -- write to enforce setup (forwarding is external to RAM)
    if rising_edge(wrclk) then
      if wren = '0' and int_rd /= 0 then
        reg_file_A( int_rd ) <= C;
        reg_file_B( int_rd ) <= C;
      end if;
    end if;
  end process WRITE_REG_BANKS;
  
end rtl;
-- -----------------------------------------------------------------------


-- -----------------------------------------------------------------------
-- RTL with explicitly declared dual-port RAMs (FPGA friendly)
-- -----------------------------------------------------------------------
architecture dual_port_ram of reg_bank is

  component ram_dual is
    generic (N_WORDS : integer;
             WIDTH : integer);
    port (data  : in std_logic_vector;
          raddr : in natural range 0 to N_WORDS-1;
          waddr : in natural range 0 to N_WORDS-1;
          we    : in std_logic;
          rclk  : in std_logic;
          wclk  : in std_logic;
          q     : out std_logic_vector);
  end component ram_dual;

  signal int_rs, int_rt, int_rd : integer range 0 to 31;
  signal pre_A, pre_B : reg32;
  signal update : std_logic;
begin

  int_rs <= to_integer(unsigned(a_rs));
  int_rt <= to_integer(unsigned(a_rt));
  int_rd <= to_integer(unsigned(a_rd));

  update <= '1' when wren = '0' and int_rd /= 0 else '0';
  
  PORT_A: ram_dual generic map (32, 32)
    port map (C, int_rs, int_rd, update, rdclk, wrclk, pre_A);
  
  PORT_B: ram_dual generic map (32, 32)
    port map (C, int_rt, int_rd, update, rdclk, wrclk, pre_B);

  -- internal forwarding WB -> RF
  A <= C  when (a_rd = a_rs) and (wren = '0') and (a_rs /= b"00000") else
       pre_A when a_rs /= b"00000"
       else x"00000000";                        -- reg0 always zero
  B <= C  when (a_rd = a_rt) and (wren = '0') and (a_rt /= b"00000") else
       pre_B when a_rt /= b"00000"
       else x"00000000";
  
end architecture dual_port_ram;
-- -----------------------------------------------------------------------



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ALU
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity alu is
  port(clk,rst: in  std_logic;
       A, B:    in  reg32;
       C:       out reg32;
       LO:      out reg32;
       HI:      out reg32;
       wr_hilo: in  std_logic;          -- write to HI & LO, active high
       move_ok: out std_logic;
       fun:     in  t_alu_fun;
       postn:   in  reg5;
       shamt:   in  reg5;
       ovfl:    out std_logic);
end alu;

architecture functional of alu is

  component register32 is
    generic (INITIAL_VALUE: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component register32;

  component mf_alt_add_sub is
    port(add_sub         : IN STD_LOGIC;  -- add=1, sub=0
         dataa           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         datab           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         overflow        : OUT STD_LOGIC;
         result          : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
  end component mf_alt_add_sub;
  
  component mf_alt_add_sub_u is
    port(add_sub         : IN STD_LOGIC;  -- add=1, sub=0
         dataa           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         datab           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         result          : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
  end component mf_alt_add_sub_u;
  
  component mask_off_bits is
    port(B : in  std_logic_vector;
         X : out std_logic_vector);
  end component mask_off_bits;
  
  component shift_left32 is
    port(inp :   in  reg32;
         shamt : in  reg5;
         otp :   out reg32);
  end component shift_left32;

  component shift_right32 is
    port(inp :   in  reg32;
         arith:  in  std_logic;
         shamt : in  reg5;
         otp :   out reg32);
  end component shift_right32;

  signal operation : integer;
  signal s_HI,s_LO, loc_HI,loc_LO, inp_HI,inp_LO, mask,mask_and : reg32;
  signal sh_left, sh_right, sh_inp, sh_lft_ins, summ_diff, summ_diff_u : reg32;
  signal addition, overflow, overflow_u, shift_arith,  wr_hi,wr_lo : std_logic;
  signal size,index, shift_amnt : reg5;
  
begin

  assert fun /= invalid_op
    report "INVALID ALU OPERATION: " & integer'image(operation)
    severity failure;

  operation <= t_alu_fun'pos(fun);   -- for debugging only
  
  U_alu: process (A,B, fun, sh_left,sh_right,sh_lft_ins,
                  mask, loc_HI,loc_LO, summ_diff, summ_diff_u, overflow)
    variable i_C, i_and, i_or: reg32;
    variable i_prod : reg64;
    variable i_move_ok, B_is_zero : std_logic := 'L';
  begin

    ovfl      <= '0';
    addition  <= '0';
    i_move_ok := '0';

    if (B = x"00000000") then B_is_zero := '1'; else B_is_zero := '0'; end if;
    
    i_C  := (others => '0');

    case fun is
      when opSLL  | opSLLV  => i_C := sh_left;
      when opSRL  | opSRA | opSRLV | opSRAV => i_C := sh_right;
      when opMOVZ  =>                   -- reg_update handled at EX_stage
        if (B_is_zero = '1')  then
          i_C := A;
          i_move_ok := '1';
        end if;
      when opMOVN  =>                   -- reg_update handled at EX_stage
        if (B_is_zero /= '1') then
          i_C := A;
          i_move_ok := '1';
        end if;
      when opMFHI  => i_C := loc_HI;
      when opMFLO  => i_C := loc_LO;
      when opADD   => addition <= '1';
                      i_C  := summ_diff;
                      ovfl <= overflow;
      when opADDU  => addition <= '1';
                      i_C  := summ_diff_u;
                      ovfl <= '0';
      when opSUB   => addition <= '0';
                      i_C  := summ_diff;
                      ovfl <= overflow;
      when opSUBU  => addition <= '0';
                      i_C  := summ_diff_u;
                      ovfl <= '0';
      when opAND   => i_C := A and B;
      when opOR    => i_C := A or  B;
      when opXOR   => i_C := A xor B;
      when opNOR   => i_C := A nor B;
      when opSLT   => addition <= '0';
        if ( overflow = '1' ) then  -- ovfl
          i_C := x"0000000" & b"000" & not(summ_diff(31));
        else
          i_C := x"0000000" & b"000" & summ_diff(31);
        end if;
        -- this instr cannot cause an exception
      when opSLTU  => addition <= '0';  -- ignore overflow/signal
                      i_C := x"0000000" & b"000" & summ_diff_u(31);
                      ovfl <= '0';
      when opLUI   => i_C := B(15 downto 0) & x"0000";
      when opSWAP  =>                   -- word swap bytes within halfwords
        i_C := B(23 downto 16)&B(31 downto 24)&B(7 downto 0) &B(15 downto 8);
      when opEXT   =>                   -- extract bit field
        i_C := sh_right and mask;
      when opINS   =>                   -- insert bit field
        i_and := B and not(sh_left);
        i_or  := sh_lft_ins;
        i_C   := i_and or i_or;
      when opSEB   =>                   -- sign-extend byte
        if B(7) = '0' then
          i_C := x"000000" & B(7 downto 0);
        else
          i_C := x"FFFFFF" & B(7 downto 0);
        end if;
      when opSEH   =>                   -- sign-extend halfword
        if B(15) = '0' then
          i_C := x"0000" & B(15 downto 0);
        else
          i_C := x"FFFF" & B(15 downto 0);
        end if;
      when opMUL   =>
        i_prod := std_logic_vector(signed(A) * signed(B));
        i_C    := i_prod(31 downto 0);
      when others  =>
        i_C  := (others => 'X');
    end case;

    --assert false report "alu: " &
    --  "A="& SLV32HEX(A) &" ["& natural'image(operation) &"] B="&
    --  SLV32HEX(B) &" ="& SLV32HEX( i_C ); -- DEBUG

    move_ok <= i_move_ok;
    C <= i_C;
    
  end process U_alu; -- -------------------------------------------

  U_ADD_SUB: mf_alt_add_sub             -- signed add/subtract
    port map (add_sub => addition, overflow => overflow,
              dataa  => A, datab => B, result => summ_diff);

  U_ADD_SUB_U: mf_alt_add_sub_u         -- UNsigned add/subtract, no overflow
    port map (add_sub => addition,
              dataa  => A, datab => B, result => summ_diff_u);


  U_HILO: process (A,B, fun, loc_HI,loc_LO)
    variable i_hi,i_lo, i_quoc,i_rem: reg32;
    variable i_prod : reg64;
    variable s_quoc, s_rem : unsigned(31 downto 0);
  begin
    i_LO   := (others => '0');
    i_HI   := (others => '0');
    s_quoc := (others => '0');
    s_rem  := (others => '0');

    case fun is
      when opMULT | opMULTU  =>
        i_prod := std_logic_vector(signed(A) * signed(B));
        i_LO := i_prod(31 downto 0);
        i_HI := i_prod(63 downto 32);
      when opDIV | opDIVU =>
        if ( B = x"00000000" ) then     -- NO exceptions caused by division
          assert true report
            "div by zero A="& SLV32HEX(A) &"["& integer'image(operation)&"]"
            & SLV32HEX(B); -- DEBUG
          i_quoc := x"FFFFFFFF";
          i_rem  := x"FFFFFFFF";
        else
          -- divmod(unsigned(A),unsigned(B),s_quoc,s_rem);
          s_quoc := unsigned(A) / unsigned(B);
          s_rem  := unsigned(A) rem unsigned(B);
        end if;
        i_quoc := std_logic_vector(s_quoc);
        i_rem  := std_logic_vector(s_rem);
        i_LO := i_quoc;
        i_HI := i_rem;
      when others  =>
        i_hi := (others => 'X');        -- to help synthesis
        i_lo := (others => 'X');        -- to help synthesis
        s_quoc := (others => 'X');      -- to help synthesis
        s_rem  := (others => 'X');      -- to help synthesis
    end case;
    s_HI <= i_hi;
    s_LO <= i_lo;
  end process U_HILO; -- -------------------------------------------
  
  
  U_hilo_inp: process (A, fun, s_HI, s_LO, wr_hilo)
  begin
    wr_lo <= '1';
    wr_hi <= '1';
    case fun is
      when opMULT | opMULTU | opDIV | opDIVU =>
        wr_lo  <= wr_hilo;
        wr_hi  <= wr_hilo;
        inp_HI <= s_HI;
        inp_LO <= s_LO;
      when opMTLO =>
        wr_lo  <= wr_hilo;
        inp_LO <= A;
        wr_hi  <= '1';
        inp_HI <= (others => 'X');                 
      when opMTHI =>
        wr_hi  <= wr_hilo;
        inp_HI <= A;
        wr_lo  <= '1';
        inp_LO <= (others => 'X');
      when others  =>
        wr_lo  <= '1';
        wr_hi  <= '1';
        inp_LO <= (others => 'X');
        inp_HI <= (others => 'X');
    end case;
  end process U_hilo_inp;  -- -------------------------------------------
  
  U_HI: register32 generic map (x"00000000")
    port map(clk, rst, wr_hi, inp_HI, loc_HI);
  U_LO: register32 generic map (x"00000000")
    port map(clk, rst, wr_lo, inp_LO, loc_LO);

  HI <= loc_HI;
  LO <= loc_LO;

  
  U_shifts: process (A,B, fun, shamt, mask)
  begin
    case fun is
      when opSLL  | opSRL  =>
        sh_inp <= B;
        shift_arith <= '0';
        shift_amnt <= shamt;
      when opSRA  =>
        sh_inp <= B;
        shift_arith <= '1';
        shift_amnt <= shamt;
      when opSLLV | opSRLV =>   -- operators RS and RT exchanged!!
        sh_inp <= B;
        shift_arith <= '0';
        shift_amnt <= A(4 downto 0);
      when opSRAV =>            -- operators RS and RT exchanged!!
        sh_inp <= B;
        shift_arith <= '1';
        shift_amnt <= A(4 downto 0);
      when opEXT  =>
        sh_inp <= A;
        shift_arith <= '0';
        shift_amnt <= shamt;
      when opINS  =>
        sh_inp <= mask;
        shift_arith <= '0';
        shift_amnt <= shamt;
      when others =>
        -- sh_inp <= B;
        -- shift_arith <= '0';
        -- shift_amnt <= b"00000";
        sh_inp <= (others => 'X');
        shift_arith <= '0';
        shift_amnt  <= (others => 'X');
    end case;
  end process U_shifts;  -- -------------------------------------------

  
  U_sh_left:  shift_left32  port map (sh_inp,shift_amnt, sh_left);
  U_sh_right: shift_right32 port map (sh_inp,shift_arith,shift_amnt, sh_right);

  U_sh_left_ins: shift_left32 port map (mask_and,shift_amnt, sh_lft_ins);
  
  size  <= std_logic_vector(unsigned(postn) - unsigned(shamt));  
  index <= size when (fun = opINS) else postn;
  U_mask: mask_off_bits port map (index, mask);
  mask_and <= A and mask;

end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  sel32: select bit field (right aligned)
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE; use IEEE.std_logic_1164.all; use IEEE.numeric_std.all;
use work.p_wires.all;

entity mask_off_bits is
  port(B : in  reg5;
       X : out reg32);
end mask_off_bits;

architecture table of mask_off_bits is
  type sel_vector is array (0 to 31) of reg32;
  constant sel_array : sel_vector := (
    x"00000001",--0
    x"00000003",
    x"00000007",
    x"0000000f",
    x"0000001f",--4
    x"0000003f",
    x"0000007f",
    x"000000ff",
    x"000001ff",--8
    x"000003ff",
    x"000007ff",
    x"00000fff",
    x"00001fff",--12
    x"00003fff",
    x"00007fff",
    x"0000ffff",
    x"0001ffff",--16
    x"0003ffff",
    x"0007ffff",
    x"000fffff",
    x"001fffff",--20
    x"003fffff",
    x"007fffff",
    x"00ffffff",
    x"01ffffff",--24
    x"03ffffff",
    x"07ffffff",
    x"0fffffff",
    x"1fffffff",--28
    x"3fffffff",
    x"7fffffff",
    x"ffffffff");
begin
  X <= sel_array(to_integer(unsigned(B)));
end table;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  shift-left32: shift left a specified number of bits
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE; use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity shift_left32 is
  port(inp :   in  reg32;
       shamt : in  reg5;
       otp :   out reg32);
end shift_left32;

architecture functional of shift_left32 is
begin

  U_shift_left: process (inp, shamt)
    variable i_1, i_2, i_4, i_8, i_16 : reg32;
  begin
    if shamt(0) = '1' then i_1  := inp(30 downto 0) & b"0";
    else                   i_1  := inp;
    end if;
    if shamt(1) = '1' then i_2  := i_1(29 downto 0) & b"00";
    else                   i_2  := i_1;
    end if;
    if shamt(2) = '1' then i_4  := i_2(27 downto 0) & b"0000";
    else                   i_4  := i_2;
    end if;
    if shamt(3) = '1' then i_8  := i_4(23 downto 0) & b"00000000";
    else                   i_8  := i_4;
    end if;
    if shamt(4) = '1' then i_16 := i_8(15 downto 0) & b"0000000000000000";
    else                   i_16 := i_8;
    end if;
    
    otp <= i_16;

  end process U_shift_left;

end functional;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  shift-right32: shift right a specified number of bits
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE; use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity shift_right32 is
  port(inp :   in  reg32;
       arith:  in  std_logic;
       shamt : in  reg5;
       otp :   out reg32);
end shift_right32;

architecture functional of shift_right32 is
begin
  
  U_shift_right: process (inp, arith, shamt)
    variable i_1, i_2, i_4, i_8, i_16, sign_ext : reg32;
  begin  -- process U_shift_right
    if arith = '1' then  sign_ext := (others => inp(31));
    else                 sign_ext := (others => '0');
    end if;

    if shamt(0) = '1' then i_1 := sign_ext(31) & inp(31 downto 1);
    else                   i_1 := inp;
    end if;
    if shamt(1) = '1' then i_2 := sign_ext(31 downto 30) & i_1(31 downto 2);
    else                   i_2 := i_1;
    end if;
    if shamt(2) = '1' then i_4 := sign_ext(31 downto 28) & i_2(31 downto 4);
    else                   i_4 := i_2;
    end if;
    if shamt(3) = '1' then i_8 := sign_ext(31 downto 24) & i_4(31 downto 8);
    else                   i_8 := i_4;
    end if;
    if shamt(4) = '1' then i_16 := sign_ext(31 downto 16) & i_8(31 downto 16);
    else                   i_16 := i_8;
    end if;

    otp <= i_16;

  end process U_shift_right;

end functional;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  bus interface: generates ONE wait-state request
--             peripheral/mem must generate additional waits, if needed
--   "waiting" is active only for the first clock cycle of reference
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE; use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity wait_states is
  generic (NUM_WAIT_STATES :integer := 0);
  port(rst     : in  std_logic;
       clk     : in  std_logic;
       sel     : in  std_logic;         -- active in '0'
       waiting : out std_logic);        -- active in '1'
end wait_states;

architecture structural of wait_states is

  component FFD is
    port(clk, rst, set, D : in std_logic; Q : out std_logic);
  end component FFD;

  component FFT is
    port(clk, rst, T : in std_logic; Q : out std_logic);
  end component FFT;

  signal will_wait, w, w_d, n_sel, cycle, this : std_logic;

begin

  n_sel <= not(sel);

  will_wait <= '0' when NUM_WAIT_STATES = 0 else '1';

  -- modulo 2 reference counter, changes at every reference  
  U_DO_WAIT: FFT port map
    (clk => clk, rst => rst, T => n_sel, Q => cycle);

  -- ref counter delayed, so will deactivate "waiting" at end of 1st clock
  U_OLD_CYCLE: FFD port map
    (clk => clk, rst => rst, set => '1', D => cycle, Q => this);

  -- w_d <= this xor cycle;                -- active for ONE cycle only

  waiting <= not(this xor cycle) and n_sel and will_wait;

end;
-- ++ wait_states +++++++++++++++++++++++++++++++++++++++++++++++++++++
