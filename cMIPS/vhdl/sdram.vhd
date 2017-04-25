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
-- SDRAM controller for Macnica's development board Mercurio IV
--       IS42S16320B, 512Mbit SDRAM, 146MHz, 32Mx16bit
--
-- design premise: banks are not interleaved; BA0,BA1 are MS address bits
--
-- TODO: 
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;

entity SDRAM_controller is
  port (rst      : in    std_logic;     -- FPGA reset (=0)
        clk      : in    std_logic;     -- CPU clock
        clk2x    : in    std_logic;     -- 100MHz clock

        sel      : in    std_logic;     -- host side chip select (=0)
        rdy      : out   std_logic;     -- tell CPU to wait (=0)
        wr       : in    std_logic;     -- host side write enable (=0)
        bsel     : in    reg4;          -- byte select
        haddr    : in    reg26;         -- host side address
        hDinp    : in    reg32;         -- host side data input
        hDout    : out   reg32;         -- host side data output

        cke      : out   std_logic;     -- ram side clock enable
        scs      : out   std_logic;     -- ram side chip select
        ras      : out   std_logic;     -- ram side RAS
        cas      : out   std_logic;     -- ram side CAS
        we       : out   std_logic;     -- ram side write enable
        dqm0     : out   std_logic;     -- ram side byte0 output enable
        dqm1     : out   std_logic;     -- ram side byte0 output enable
        ba0      : out   std_logic;     -- ram side bank select 0
        ba1      : out   std_logic;     -- ram side bank select 1
        saddr    : out   reg12;         -- ram side address
        sdata    : inout  reg16);       -- ram side data

--  constant RESET_INTERVAL : integer := 5000; -- reset after 100us = 5.000*20n
--  constant REFRESH_INTERVAL : integer := 704;-- do a refresh every 704 cycles
  constant RESET_INTERVAL : integer := 5; -- reset after 100us = 5.000*20n
  constant REFRESH_INTERVAL : integer := 7;-- do a refresh every 704 cycles


  
  subtype cmd_index is integer range 0 to 13;
  
  constant cDSL  : cmd_index := 0;
  constant cNOP  : cmd_index := 1;
  constant cBST  : cmd_index := 2;
  constant cRD   : cmd_index := 3;
  constant cRDA  : cmd_index := 4;
  constant cWR   : cmd_index := 5;
  constant cWRA  : cmd_index := 6;
  constant cACT  : cmd_index := 7;
  constant cPRE  : cmd_index := 8;
  constant cPALL : cmd_index := 9;
  constant cREF  : cmd_index := 10;
  constant cSELF : cmd_index := 11;
  constant cMRS  : cmd_index := 12;
  constant cinv  : cmd_index := 13;

  type t_cmd_type is record
    cmd: cmd_index;
    cs:  std_logic;
    ras: std_logic;
    cas: std_logic;
    we:  std_logic;
    a10: std_logic;
  end record;

  type t_cmd_mem is array (0 to 12) of t_cmd_type;
  
end entity SDRAM_controller;


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- real SDRAM controller for Macnica's development board Mercurio IV
--       IS42S16320B, 512Mbit SDRAM, 146MHz, 32Mx16bit
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture simple of SDRAM_controller is

  constant cmd_table : t_cmd_mem := (  -- page 9
  -- cmd    cs ras cas we  a10
    (cDSL, '1','1','1','1','1'),        -- DESL device deselect
    (cNOP, '0','1','1','1','1'),        -- NOP no operation
    (cBST, '0','1','1','0','1'),        -- BST burst stop
    (cRD,  '0','1','0','1','0'),        -- RD read
    (cRDA, '0','1','0','1','1'),        -- RDA read with auto precharge
    (cWR,  '0','1','0','0','0'),        -- WR write
    (cWRA, '0','1','0','0','1'),        -- WR write with auto precharge
    (cACT, '0','0','1','1','1'),        -- ACT bank activate
    (cPRE, '0','0','1','0','0'),        -- PRE precharge selected bank
    (cPALL,'0','0','1','0','1'),        -- PALL precharge all banks
    (cREF, '0','0','0','1','1'),        -- REF CBR auto-refresh
    (cSELF,'0','0','0','1','1'),        -- SELF self-refresh
    (cMRS, '0','0','0','0','0')         -- MRS mode register set
);

  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component registerN;

  component wait_states is
    generic (NUM_WAIT_STATES :integer);
    port(rst   : in  std_logic;
       clk     : in  std_logic;
       sel     : in  std_logic;         -- active in '0'
       waiting : out std_logic);        -- active in '1'
  end component wait_states;

  component FFDsimple is
    port(clk, rst, D : in std_logic; Q : out std_logic);
  end component FFDsimple;


  -- state machine
  type ctrl_state is
    (st_noreset,                        -- 0
     st_in0, st_in1, st_ipre, st_in2,   -- 4
     st_aref1, st_1n0, st_1n1, st_1n2, st_1n3, st_1n4, st_1n5,  -- 11
     st_aref2, st_2n0, st_2n1, st_2n2, st_2n3, st_2n4, st_2n5,  -- 18
     st_aref3, st_3n0, st_3n1, st_3n2, st_3n3, st_3n4, st_3n5,  -- 25
     st_aref4, st_4n0, st_4n1, st_4n2, st_4n3, st_4n4, st_4n5,  -- 32
     st_lmr, st_ln0, st_ln1,            -- 35
     st_pall, st_pn0, st_pn1,           -- 38
     st_refr, st_rn0, st_rn1, st_rn2, st_rn3, st_rn4, st_rn5,  -- 45
     st_idle2,                          -- 46
     st_act, st_an0, st_an1,            -- 49
     st_rdcol, st_rdn0, st_rd_done,     -- 52
     st_wrcol,                          -- 53
     st_idle);                          -- 54
  
  signal curr_st, next_st : ctrl_state;
  signal ctrl_dbg_st, cmd_dbg : integer;      -- for debugging only
  
  signal reset_done, same_row, do_refresh, refresh_done : boolean := FALSE;
  signal is_accs, is_rd, is_wr : boolean := FALSE;
  signal addr : reg26;
  signal row_bits, last_row : reg13;
  signal col_bits : reg10;
  signal rwo_bits : reg13;
  signal ld_old : std_logic;
  signal command : t_cmd_type;
  signal doit : cmd_index;

  signal wait1, wait2, waiting : std_logic;
  
begin  -- simple

  
  U_WAIT_ON_READS: wait_states generic map (1)
    port map (rst, clk, sel, wait1);

  U_WAIT2: FFDsimple port map (clk, rst, wait1, wait2);

  rdy <= not BOOL2SL((sel = '0') and
                     ((wait1 = '1') or (wait2 = '1')  or (waiting = '1')));

  is_accs <= (sel = '0');
  is_rd   <= (sel = '0') and (wr = '1');
  is_wr   <= (sel = '0') and (wr = '0');
  
  command  <= cmd_table(doit);
  scs  <= command.cs;
  ras  <= command.ras;
  cas  <= command.cas;
  we   <= command.we;

  cmd_dbg <= command.cmd;               -- DEBUG only
  
  saddr(10) <= addr(10) when command.cmd = cACT else
               command.a10;

  saddr(9 downto 0) <= b"1000100000" when command.cmd = cMRS else
                       addr(9 downto 0);
  
  U_address: registerN  generic map (26, b"00"&x"000000")
    port map (clk2x, rst, sel, haddr, addr);

  row_bits <= addr(23 downto 11);
  col_bits <= addr(10 downto 1);
  ba0 <= addr(24);
  ba1 <= addr(25);

  
  ld_old <= sel and not(BOOL2SL(same_row));
  U_last_row: registerN  generic map (13, '1'&x"fff")
    port map (clk2x, rst, ld_old, haddr(23 downto 11), last_row);
--   same_row <= (last_row = row_bits) and (command.cmd /= cPALL);

  same_row <= FALSE;

  

  -- this state machine contols the SDRAM interface -----------------------
  U_CTRL_st_reg: process(rst,clk2x)
  begin
    if rst = '0' then
      curr_st <= st_noreset;
    elsif rising_edge(clk2x) then
      curr_st <= next_st;
    end if;
  end process U_CTRL_st_reg; ----------------------------------------------

  ctrl_dbg_st <= integer(ctrl_state'pos(curr_st)); -- for debugging

    
  U_CTRL_st_transitions: process(curr_st, reset_done, do_refresh, -------
                                 same_row, is_accs, is_rd, is_wr)
  begin
    case curr_st is

      -- WAIT FOR POWER-ON RESET TO COMPLETE
      when st_noreset =>                -- 0
        if reset_done then
          next_st <= st_in0;
        else
          next_st <= st_noreset;
        end if;
        
      -- INITIALIZATION SEQUENCE
      when st_in0 =>                    -- 1 nop
        next_st <= st_in1;
      when st_in1 =>                    -- 2 nop
        next_st <= st_ipre;
      when st_ipre =>                   -- 3 precharge all banks
        next_st <= st_in2;
      when st_in2 =>                    -- 4 nop
        next_st <= st_aref1;

      when st_aref1 =>                  -- 5 auto refresh 1 + 60ns delay
        next_st <= st_1n0;
      when st_1n0 =>                    -- 6 nop
        next_st <= st_1n1;
      when st_1n1 =>                    -- 7 nop
        next_st <= st_1n2;
      when st_1n2 =>                    -- 8 nop
        next_st <= st_1n3;
      when st_1n3 =>                    -- 9 nop
        next_st <= st_1n4;
      when st_1n4 =>                    -- 10 nop
        next_st <= st_1n5;
      when st_1n5 =>                    -- 11 nop
        next_st <= st_aref2;
      
      when st_aref2 =>                  -- 12 auto refresh 2 + 60ns delay
        next_st <= st_2n0;
      when st_2n0 =>                    -- 13 nop
        next_st <= st_2n1;
      when st_2n1 =>                    -- 14 nop
        next_st <= st_2n2;
      when st_2n2 =>                    -- 15 nop
        next_st <= st_2n3;
      when st_2n3 =>                    -- 16 nop
        next_st <= st_2n4;
      when st_2n4 =>                    -- 17 nop
        next_st <= st_2n5;
      when st_2n5 =>                    -- 18 nop
        next_st <= st_aref3;
      
      when st_aref3 =>                  -- 19 auto refresh 3 + 60ns delay
        next_st <= st_3n0;
      when st_3n0 =>                    -- 20 nop
        next_st <= st_3n1;
      when st_3n1 =>                    -- 21 nop
        next_st <= st_3n2;
      when st_3n2 =>                    -- 22 nop
        next_st <= st_3n3;
      when st_3n3 =>                    -- 23 nop
        next_st <= st_3n4;
      when st_3n4 =>                    -- 24 nop
        next_st <= st_3n5;
      when st_3n5 =>                    -- 25 nop
        next_st <= st_aref4;
      
      when st_aref4 =>                  -- 26 auto refresh 4 + 60ns delay
        next_st <= st_4n0;
      when st_4n0 =>                    -- 27 nop
        next_st <= st_4n1;
      when st_4n1 =>                    -- 28 nop
        next_st <= st_4n2;
      when st_4n2 =>                    -- 29 nop
        next_st <= st_4n3;
      when st_4n3 =>                    -- 30 nop
        next_st <= st_4n4;
      when st_4n4 =>                    -- 31 nop
        next_st <= st_4n5;
      when st_4n5 =>                    -- 32 nop
        next_st <= st_lmr;
      
      when st_lmr =>                    -- 33 load mode register + 2 nops
        next_st <= st_ln0;
      when st_ln0 =>                    -- 34 nop
        next_st <= st_ln1;
      when st_ln1 =>                    -- 35 nop
        next_st <= st_idle;

      -- AUTO-REFRESH SEQUENCE 
      when st_pall =>                   -- 36 precharge all banks + 2 nops
        next_st <= st_pn0;
      when st_pn0 =>                    -- 37 nop
        next_st <= st_pn1;
      when st_pn1 =>                    -- 38 nop
        next_st <= st_refr;
        
      when st_refr =>                   -- 39 auto refresh + 60ns delay
        next_st <= st_rn0;
      when st_rn0 =>                    -- 40 nop
        next_st <= st_rn1;
      when st_rn1 =>                    -- 41 nop
        next_st <= st_rn2;
      when st_rn2 =>                    -- 42 nop
        next_st <= st_rn3;
      when st_rn3 =>                    -- 43 nop
        next_st <= st_rn4;
      when st_rn4 =>                    -- 44 nop
        next_st <= st_rn5;
      when st_rn5 =>                    -- 45 nop; sameRow was cleared
        next_st <= st_idle2;

      when st_idle2 =>                  -- 46
        if is_accs then                 -- is post-refresh access, activate row
          next_st <= st_act;
        else
          next_st <= st_idle2;
        end if;

      -- ACTIVATE NEW ROW
      when st_act =>                    -- 47 activate row + 2 nops
        next_st <= st_an0;
      when st_an0 =>                    -- 48 nop
        next_st <= st_an1;
      when st_an1 =>                    -- 49 nop
        if is_rd then
          next_st <= st_rdcol;          -- access is a read, set column
        else
          next_st <= st_wrcol;          -- access is a write, set column
        end if;

      -- READ FROM COLUMN
      when st_rdcol =>                  -- 50 set column for RD + 2 nops
        next_st <= st_rdn0;
      when st_rdn0 =>                   -- 51 nop
        next_st <= st_rd_done;
      when st_rd_done =>                -- 52 nop
        if do_refresh then
          next_st <= st_pall;           -- go to refresh sequence
        else
          next_st <= st_idle;           -- wait for next access to same row
        end if;

      -- WRITE TO COLUMN
      when st_wrcol =>                  -- 53 set column for WR
        if do_refresh then
          next_st <= st_pall;           -- go to refresh sequence
        else
          next_st <= st_idle;           -- wait for next access to same row
        end if;
        
      when st_idle =>                   -- 54
        if is_accs and not(same_row) then
          next_st <= st_act;
        elsif is_rd then
          next_st <= st_rdcol;
        elsif is_wr then
          next_st <= st_wrcol;
        else
          next_st <= st_idle;
        end if;
      when others =>
        assert false report "CTRL stateMachine broken"
          & integer'image(ctrl_state'pos(curr_st)) severity failure;
    end case;
  end process U_CTRL_st_transitions;   ---------------------------

  
  U_CTRL_outputs: process(curr_st)  ------------------------------
  begin
    case curr_st is
      when st_rdcol =>
        doit <= cRD;                    -- read from column
        
      when st_wrcol =>
        doit <= cWR;                    -- write to column
        
      when st_ipre | st_pall =>
        doit <= cPALL;                  -- precharge all banks

      when st_aref1 | st_aref2 | st_aref3 | st_aref4 =>
        doit <= cREF;                   -- auto-refresh

      when st_lmr =>
        doit <= cMRS;                   -- load mode register

      when st_act =>
        doit <= cACT;                   -- activate row

      when others =>
        doit <= cNOP;
    end case;
  end process U_CTRL_outputs;   ----------------------------------

  U_CTRL_waiting: process(curr_st)  ------------------------------
  begin
    case curr_st is
      when st_rdcol | st_rdn0 =>
        waiting <= '0';                    -- read from column
        
      when st_wrcol =>
        waiting <= '0';                    -- write to column
        
      when st_ipre | st_pall =>
        waiting <= '0';                  -- precharge all banks

      when st_aref1 | st_aref2 | st_aref3 | st_aref4 =>
        waiting <= '0';                   -- auto-refresh

      when st_lmr =>
        waiting <= '0';                   -- load mode register

      when st_act | st_an0 | st_an1 =>
        waiting <= '0';                   -- activate row

      when others =>
        waiting <= '1';
    end case;
  end process U_CTRL_waiting;  -----------------------------------

  

  -- do a refresh in less than 7,8us (8192 in 64ms @ 100MHz)
  U_do_refresh: process (rst, clk2x, refresh_done)
    variable cnt : integer range 0 to 1023:= 0;
  begin
    if rst = '0' then
      do_refresh <= FALSE;
      cnt := 0;
    elsif rising_edge(clk2x) then
      if cnt > REFRESH_INTERVAL then
        if refresh_done then
          do_refresh <= FALSE;
          cnt := 0;
        else
          do_refresh <= TRUE;           -- add some hysteresis
          if cnt = 1023 then
            cnt := 0;
          else
            cnt := cnt + 1;               --   to accomodate slow commands
          end if;
        end if;
      else
        do_refresh <= FALSE;
        cnt := cnt + 1;
      end if;
    end if;
  end process U_do_refresh;
  

  -- do wait for 100us after reset
  U_rst_100us: process(rst, clk2x)
    variable cnt : integer range 0 to (8*1024 - 1):= 0;
  begin
    if rst = '0' then
      reset_done <= FALSE;
      cnt := 0;
    elsif rising_edge(clk2x) then
      if cnt >= RESET_INTERVAL then     -- 100us elapsed
        reset_done <= TRUE;
        cnt := 0;
      else
        cnt := cnt + 1;
      end if;
    end if;
  end process U_rst_100us;
 

end simple;
-- ---------------------------------------------------------------------
    


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- fake SDRAM controller for Macnica's development board Mercurio IV
--       IS42S16320B, 512Mbit SDRAM, 146MHz, 32Mx16bit
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture fake of SDRAM_controller is
begin
  
  rdy <= '1';
  hDout <= (others => 'X');

  cke      <= '1';
  scs      <= '1';
  ras      <= '1';
  cas      <= '1';
  we       <= '1';
  dqm0     <= '1';
  dqm1     <= '1';
  ba0      <= '1';
  ba1      <= '1';
  saddr    <= (others => 'X');
  sdata    <= (others => 'X');

end architecture fake;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

