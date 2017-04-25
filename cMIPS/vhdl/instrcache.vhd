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
-- instruction cache, word-indexed, FPGA version, with early restart
-- TODO: associativity
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;

entity I_CACHE_fpga is
  port (rst      : in    std_logic;
        clk4x    : in    std_logic;
        ic_reset : out   std_logic;         -- active in '0'
        cpu_sel  : in    std_logic;         -- active in '0'
        cpu_rdy  : out   std_logic;         -- active in '0'
        cpu_addr : in    reg32;
        cpu_data : out   reg32;
        mem_sel  : out   std_logic;         -- active in '0'
        mem_rdy  : in    std_logic;         -- active in '0'
        mem_addr : out   reg32;
        mem_data : in    reg32;
        ref_cnt  : out   integer;
        hit_cnt  : out   integer);

  constant IC_TAG_BITS  : natural :=
    IC_BTS_PER_WORD - (IC_INDEX_BITS + IC_WORD_SEL_BITS + IC_BYTE_SEL_BITS);
  constant IC_TOP_TAG   : natural := 31;
  constant IC_BOT_TAG   : natural := 32 - IC_TAG_BITS;
  constant IC_TOP_INDEX : natural := 32 - (IC_TAG_BITS + 1);
  constant IC_BOT_INDEX : natural := 32 - (IC_TAG_BITS + IC_INDEX_BITS);
  constant IC_TOP_W_SEL : natural := 32 - (IC_TAG_BITS + IC_INDEX_BITS + 1);
  constant IC_BOT_W_SEL : natural :=
    32 - (IC_TAG_BITS + IC_INDEX_BITS + IC_WORD_SEL_BITS);

  constant TAG_IDX_REG_INI: std_logic_vector(IC_TAG_BITS + IC_INDEX_BITS - 1 downto 0) :=
    (others => '0');
  subtype tag_address is integer range 0 to (IC_NUM_BLOCKS - 1);
  subtype ram_address is integer range 0 to (IC_NUM_WORDS - 1);
  subtype tag_sel_width  is std_logic_vector((IC_TAG_BITS - 1) downto 0);
  subtype index_width    is std_logic_vector((IC_INDEX_BITS - 1) downto 0);
  subtype word_sel_width is std_logic_vector((IC_WORD_SEL_BITS - 1) downto 0);
  subtype tag_d_width    is std_logic_vector(IC_TAG_BITS - 1 downto 0);
  subtype v_tag_d_width  is std_logic_vector(IC_TAG_BITS downto 0);
  subtype tag_index_width is
    std_logic_vector((IC_TAG_BITS+IC_INDEX_BITS - 1) downto 0);
end entity I_CACHE_fpga;

architecture structural of I_CACHE_fpga is

  component sr_latch is
    port(set,clr : in  std_logic;
         q : out std_logic);
  end component sr_latch;

  component sr_latch_rst is
    port(rst,set,clr : in  std_logic;
         q : out std_logic);
  end component sr_latch_rst;

  component register32 is
    generic (INITIAL_VALUE: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component register32;

  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector(NUM_BITS-1 downto 0);
         Q:            out std_logic_vector(NUM_BITS-1 downto 0));
  end component registerN;

  component countNup is
    generic (NUM_BITS: integer);
    port(clk, rst, ld, en: in  std_logic;
         D:            in  std_logic_vector(NUM_BITS-1 downto 0);
         Q:            out std_logic_vector(NUM_BITS-1 downto 0);
         co:           out std_logic);
  end component countNup;

  component ram_dual is
    generic (N_WORDS : integer;
             WIDTH : integer);
    port (data  : in std_logic_vector;
          raddr : in natural range 0 to N_WORDS - 1;
          waddr : in natural range 0 to N_WORDS - 1;
          we    : in std_logic;
          rclk  : in std_logic;
          wclk  : in std_logic;
          q     : out std_logic_vector);
  end component ram_dual;

  signal fetch, found, update_tags, hit, d_str_rd : std_logic;
  signal t_str_rd, t_str_wr, t_we, d_str_wr, d_we : std_logic := '0';
  signal full, filled, ld_addr, ld_cnt, en_cnt, check_addr : std_logic := '0';
  signal fetching, s_fetching, r_fetching, en_wd_incr : std_logic;
  signal reseting, s_reseting, r_reseting : std_logic;
  signal init_done, init_incr, init_ld : std_logic;
  signal tag_update, tag_invalidate, valid, miss_under_miss : std_logic := '0';
  
  type cpu_ic_state is (st_idle, st_check, st_waiting, st_done, st_sync);
  attribute SYN_ENCODING of cpu_ic_state : type is "safe";
  signal cpu_ic_curr_st,cpu_ic_next_st : cpu_ic_state;
  signal cpu_ic_curr : integer;      -- DEBUGging only

  type ic_ram_state is (st_idle, st_start1, st_wait1, st_found, 
                        st_startn, st_waitn, st_done,
                        st_istart, st_iload, st_idelay1, st_idelay2,
                        st_inext, st_istop);
  attribute SYN_ENCODING of ic_ram_state : type is "safe";
  signal ic_ram_curr_st,ic_ram_next_st : ic_ram_state;
  signal ic_ram_curr : integer;      -- DEBUGging only

  signal cached_data, hold_data : reg32;
  signal t_rd_addr, t_wr_addr : tag_address;
  signal d_rd_addr, d_wr_addr : ram_address;
  signal cpu_tag, old_tag, tag : tag_d_width;
  signal v_tag, old_v_tag, new_v_tag : v_tag_d_width;
  signal cpu_index, old_index, init_index, wr_index : index_width;
  signal cpu_word, old_word : word_sel_width;
  signal cpu_tag_index, tag_index : tag_index_width;
  constant word_sel_zero : word_sel_width := (others => '0');
  constant index_sel_zero : index_width := (others => '0');
  constant v_tag_zero : v_tag_d_width := (others => '0');
  
begin

  cpu_tag   <= cpu_addr(IC_TOP_TAG downto IC_BOT_TAG) when cpu_sel = '0'
               else (others => 'X');
  cpu_index <= cpu_addr(IC_TOP_INDEX downto IC_BOT_INDEX) when cpu_sel = '0'
               else (others => 'X');
  cpu_word  <= cpu_addr(IC_TOP_W_SEL downto IC_BOT_W_SEL) when cpu_sel = '0'
               else (others => 'X');

  t_rd_addr <= to_integer(unsigned(cpu_index));
  t_str_rd  <= not(cpu_sel);

  t_wr_addr  <= to_integer(unsigned(wr_index));

  -- t_we <= '1'; -- fetching,
  t_we <= (tag_update or tag_invalidate) when reseting = '0' else
          init_incr;
  tag_update <= CONVERT_BOOLEAN( ic_ram_curr_st = st_done );
  tag_invalidate <= CONVERT_BOOLEAN( ic_ram_curr_st = st_found ) ;
  
  -- tag memory: valid (MS) & IC_TAG_BITS (ms)
  U_TAGS: ram_dual generic map (IC_NUM_BLOCKS, IC_TAG_BITS+1)
    port map (new_v_tag, t_rd_addr, t_wr_addr, t_we, 
              clk4x, clk4x, v_tag);

  new_v_tag <= old_v_tag when (reseting = '0' and tag_update = '1') else
               v_tag_zero;

  valid <= v_tag(IC_TAG_BITS);
  tag   <= v_tag(IC_TAG_BITS-1 downto 0);
  hit   <= not(cpu_sel) and valid and CONVERT_BOOLEAN( tag = cpu_tag );

  old_v_tag <= full & old_tag;
  
  d_rd_addr <= to_integer(unsigned( cpu_index & cpu_word ) );
  d_str_rd  <= hit and not(cpu_sel);

  wr_index <= old_index when reseting = '0' else init_index;
  d_wr_addr <= to_integer(unsigned( wr_index & old_word ) );
  
  -- instruction memory: physically organized as words, not blocks
  U_RAM: ram_dual generic map (IC_NUM_WORDS, IC_BTS_PER_WORD)
    port map (mem_data, d_rd_addr, d_wr_addr, fetching,
              d_str_rd, mem_rdy, cached_data);

  cpu_data <= hold_data when ( hit = '0' ) else cached_data;  
  U_HOLD_INSTR: registerN  generic map ( 32, x"00000000" )
    port map (mem_rdy, rst, '0', mem_data, hold_data);

  
  en_wd_incr <= CONVERT_BOOLEAN( ic_ram_curr_st = st_startn );
  
  -- block-fill circuitry for early restart: fill from address of miss
  U_FILL_ADDR: countNup generic map (IC_WORD_SEL_BITS)  -- clk,rst,ld,en
    port map (clk4x, rst, s_fetching, en_wd_incr, cpu_word, old_word, open);

  -- count number of words fetched from memory
  U_FILL_COUNTER: countNup generic map (IC_WORD_SEL_BITS)
    port map (clk4x, rst, s_fetching, en_wd_incr, word_sel_zero,
              open, full);

  old_tag   <= tag_index((IC_TAG_BITS+IC_INDEX_BITS - 1) downto IC_INDEX_BITS);
  old_index <= tag_index((IC_INDEX_BITS - 1) downto 0);
  mem_addr  <= old_tag & old_index & old_word & b"00";

  cpu_tag_index <= cpu_tag & cpu_index;
  
  ld_addr <= not(fetching);
  
  U_TAG_INDEX_REGISTER: registerN            -- clk,rst,ld=0
    generic map ( IC_TAG_BITS + IC_INDEX_BITS, TAG_IDX_REG_INI)
    port map (fetching, rst, '0', cpu_tag_index, tag_index);

  miss_under_miss <= '1' when ( cpu_tag_index /= tag_index ) else '0';

  
  update_tags <= '1' when ic_ram_curr_st = st_done else '0';
  
  s_fetching <= CONVERT_BOOLEAN( ic_ram_curr_st = st_start1 );
  r_fetching <= CONVERT_BOOLEAN( ic_ram_curr_st = st_done );
  
  U_FETCHING: sr_latch_rst port map (rst, s_fetching, r_fetching, fetching);

  
  -- scan I_cache during reset and clear valid bit in all blocks
  U_RESET_COUNTER: countNup generic map (IC_INDEX_BITS)  -- clk,rst,ld,en
    port map (clk4x, rst, init_ld, init_incr,
              index_sel_zero, init_index, init_done);

  init_ld   <= ( CONVERT_BOOLEAN( ic_ram_curr_st = st_iload ) );
  init_incr <= ( CONVERT_BOOLEAN( ic_ram_curr_st = st_idelay2 ) );
  
  s_reseting <= not( CONVERT_BOOLEAN( ic_ram_curr_st = st_istart ) );
  r_reseting <= not( CONVERT_BOOLEAN( ic_ram_curr_st = st_istop ) );

  U_RESSETING: sr_latch port map (s_reseting, r_reseting, reseting);

  ic_reset <= not(reseting);
  
  -- CPU-IC interface --------------------------------------------------
  U_cpu_st_reg: process(rst,clk4x)
  begin
    if rst = '0' then
      cpu_ic_curr_st <= st_idle;
    elsif rising_edge(clk4x) then
      cpu_ic_curr_st <= cpu_ic_next_st;
    end if;
  end process U_cpu_st_reg;

  cpu_ic_curr <= cpu_ic_state'pos(cpu_ic_curr_st);  -- debugging only
    
  U_cpu_st_transitions: process(cpu_ic_curr_st, cpu_sel,hit,found,
                                miss_under_miss,fetching)
  begin
    case cpu_ic_curr_st is
      when st_idle =>                   -- 0
        cpu_rdy <= '1';
        fetch   <= '0';
        if cpu_sel = '0' then
          cpu_ic_next_st <= st_check;
        else
          cpu_ic_next_st <= st_idle;
        end if;
      when st_check =>                  -- 1
        cpu_rdy <= '0';
        fetch   <= '0';          
        if hit = '1' then
          cpu_ic_next_st <= st_done;
        else
          cpu_ic_next_st <= st_waiting;
        end if;
      when st_waiting =>                -- 2
        cpu_rdy <= '0';
        fetch   <= '1';
        if found = '0' then
          cpu_ic_next_st <= st_waiting;
        else
          if miss_under_miss = '1' then
            cpu_ic_next_st <= st_sync;
          else
            cpu_ic_next_st <= st_done;
          end if;
        end if;
      when st_sync =>                  -- 4
        cpu_rdy <= '0';
        fetch   <= '1';
        if fetching = '1' then
          cpu_ic_next_st <= st_sync;
        else
          cpu_ic_next_st <= st_check;
        end if;
      when st_done =>                   -- 3
        cpu_rdy <= '1';
        fetch   <= '0';          
        if cpu_sel = '0' then           -- MEM stalled, wait
          cpu_ic_next_st <= st_done;
        else
          cpu_ic_next_st <= st_idle;
        end if;
      when others =>
        cpu_rdy <= 'X';
        fetch   <= 'X';
        assert false report "I_CACHE_CPU stateMachine broken" &
          integer'image(cpu_ic_state'pos(cpu_ic_curr_st)) severity failure;
    end case;
  end process U_cpu_st_transitions; -- CPU-IC interface ---------------


  -- IC-RAM interface -------------------------------------------------
  U_ram_st_reg: process(rst,clk4x)
  begin
    if rst = '0' then
      ic_ram_curr_st <= st_istart;      -- initizlize cache tags
    elsif falling_edge(clk4x) then
      ic_ram_curr_st <= ic_ram_next_st;
    end if;
  end process U_ram_st_reg;

  ic_ram_curr <= ic_ram_state'pos(ic_ram_curr_st);  -- debugging only
    
  U_ram_st_transitions: process(ic_ram_curr_st,check_addr,fetch,full,
                                mem_rdy,cpu_sel,init_done)
  begin
    case ic_ram_curr_st is
      when st_idle =>                   -- 0
        mem_sel <= '1';
        found   <= '0';
        if fetch = '1' then
          ic_ram_next_st <= st_start1;
        else
          ic_ram_next_st <= st_idle;
        end if;
      when st_start1 =>                 -- 1
        mem_sel <= '0';
        found   <= '0';          
        ic_ram_next_st <= st_wait1;
      when st_wait1 =>                  -- 2
        mem_sel <= '0';
        found   <= '0';
        if mem_rdy = '0' then
          ic_ram_next_st <= st_wait1;
        else
          ic_ram_next_st <= st_found;
        end if;

      when st_found =>                  -- 3
        found   <= '1';
        mem_sel <= '1';
        if cpu_sel = '0' then
          ic_ram_next_st <= st_found;
        else
          ic_ram_next_st <= st_startn;
        end if;
        
      when st_startn =>                 -- 4 invalidate tag to avoid false-hit
        mem_sel <= '1';
        found   <= '0';
        if full = '1' then
          ic_ram_next_st <= st_done;
        else
          ic_ram_next_st <= st_waitn;
        end if;
      when st_waitn =>                  -- 5
        mem_sel <= '0';
        found <= '0';
        if mem_rdy = '0' then
          ic_ram_next_st <= st_waitn;
        else
          ic_ram_next_st <= st_startn;
        end if;
        
      when st_done =>                   -- 6 mark tag as valid
        mem_sel <= '1';
        found   <= '1';
        ic_ram_next_st <= st_idle;

      when st_istart =>                 -- 7 initialize cache tags
        mem_sel <= '1';
        found   <= '0';
        ic_ram_next_st <= st_iload;

      when st_iload =>                  -- 8
        mem_sel <= '1';
        found   <= '0';
        ic_ram_next_st <= st_idelay1;

      when st_idelay1 =>                -- 9 give some time to SRAM
        mem_sel <= '1';
        found   <= '0';
        ic_ram_next_st <= st_idelay2;

      when st_idelay2 =>                -- 10
        mem_sel <= '1';
        found   <= '0';
        ic_ram_next_st <= st_inext;

      when st_inext =>                  -- 11
        mem_sel <= '1';
        found   <= '0';
        if init_done = '1' then
          ic_ram_next_st <= st_istop;
        else
          ic_ram_next_st <= st_idelay1;
        end if;

      when st_istop =>                  -- 12 initialization done
        mem_sel <= '1';
        found   <= '0';
        ic_ram_next_st <= st_idle;      --   go to normal operation
        
      when others =>
        mem_sel <= 'X';
        found   <= 'X';
        assert false report "I_CACHE_RAM stateMachine broken" &
          integer'image(ic_ram_state'pos(ic_ram_curr_st)) severity failure;
    end case;
  end process U_ram_st_transitions; -- IC-RAM interface ---------------


  ref_cnt  <= 0;
  hit_cnt  <= 0;
  
end structural;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--c -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--c -- Altera's design for a dual-port RAM that can be synthesized
--c -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--c library ieee;
--c use ieee.std_logic_1164.all;
--c 
--c entity ram_dual is
--c   generic (N_WORDS : integer := 64;
--c            WIDTH : integer := 8);
--c   port (data  : in std_logic_vector(WIDTH - 1 downto 0);
--c     raddr : in natural range 0 to N_WORDS - 1;
--c     waddr : in natural range 0 to N_WORDS - 1;
--c     we    : in std_logic;
--c     rclk  : in std_logic;
--c     wclk  : in std_logic;
--c     q     : out std_logic_vector(WIDTH - 1 downto 0));
--c end ram_dual;
--c 
--c architecture rtl of ram_dual is
--c 
--c   -- Build a 2-D array type for the RAM
--c   subtype word_t is std_logic_vector(WIDTH - 1 downto 0);
--c   type memory_t is array(N_WORDS - 1 downto 0) of word_t;
--c   
--c   -- Declare the RAM signal.
--c   signal ram : memory_t; --  := (others => (others => '0'));
--c 
--c begin
--c 
--c   process(wclk)
--c   begin
--c     if(rising_edge(wclk)) then 
--c       if(we = '1') then
--c         ram(waddr) <= data;
--c       end if;
--c     end if;
--c   end process;
--c 
--c   process(rclk)
--c   begin
--c     if(rising_edge(rclk)) then
--c       q <= ram(raddr);
--c     end if;
--c   end process;
--c   
--c end rtl;
--c -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
