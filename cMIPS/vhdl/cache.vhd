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
-- data cache, byte-indexed, write-through, no write-allocate on wr-miss
-- TODO: critical-word first, store-buffer, write-buffer, associativity
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;

entity D_CACHE is
  port (rst      : in    std_logic;
        clk4x    : in    std_logic;
        cpu_sel  : in    std_logic;         -- active in '0'
        cpu_rdy  : out   std_logic;         -- active in '0'
        cpu_wr   : in    std_logic;         -- active in '0'
        cpu_addr : in    reg32;
        cpu_data_inp : in  reg32;           -- data from CPU
        cpu_data_out : out reg32;           -- data to CPU
        cpu_xfer : in    reg4;
        mem_sel  : out   std_logic;         -- active in '0'
        mem_rdy  : in    std_logic;         -- active in '0'
        mem_wr   : out   std_logic;         -- active in '0'
        mem_addr : out   reg32;
        mem_data_inp : in  reg32;           -- data from memory
        mem_data_out : out reg32;           -- data to memory
        mem_xfer : out   reg4;
        ref_cnt  : out   integer;
        rd_hit_cnt : out integer;
        wr_hit_cnt : out integer;
        flush_cnt  : out integer);          -- for write-back caches

  constant DC_TAG_BITS  : natural :=
    DC_BTS_PER_WORD - (DC_INDEX_BITS + DC_WORD_SEL_BITS + DC_BYTE_SEL_BITS);
  constant DC_TOP_TAG   : natural := 31;
  constant DC_BOT_TAG   : natural := 32 - DC_TAG_BITS;
  constant DC_TOP_INDEX : natural := 32 - (DC_TAG_BITS + 1);
  constant DC_BOT_INDEX : natural := 32 - (DC_TAG_BITS + DC_INDEX_BITS);
  constant DC_TOP_W_SEL : natural := 32 - (DC_TAG_BITS + DC_INDEX_BITS + 1);
  constant DC_BOT_W_SEL : natural :=
    32-(DC_TAG_BITS + DC_INDEX_BITS + DC_WORD_SEL_BITS);
  constant DC_TOP_B_SEL : natural := DC_BYTE_SEL_BITS - 1;
  constant DC_BOT_B_SEL : natural := 0;
  
end entity D_CACHE;


architecture behavioral of D_CACHE is

  type dc_block is array (natural range 0 to (DC_WORDS_PER_BLOCK-1)) of reg32;
  type dc_data is array  (natural range 0 to (DC_NUM_BLOCKS-1)) of dc_block;
  signal dc_data_matrix : dc_data;

  type dc_tag is record
    val : std_logic;
    tag : std_logic_vector((DC_TAG_BITS-1) downto 0);
  end record;
  type dc_tags is array (natural range 0 to (DC_NUM_BLOCKS-1)) of dc_tag;
  signal dc_tags_matrix : dc_tags;
  
  signal miss,blk_filled,next_word,ref_mem : std_logic := '0';

  type dc_state is (st_idle, st_check, st_hit, st_start, st_waiting, st_done);
  attribute SYN_ENCODING of dc_state : type is "safe";
  signal dc_current_st,dc_next_st :dc_state;
  signal dc_current : integer;

  signal dbg_index  : std_logic_vector(DC_INDEX_BITS-1 downto 0);
  signal dbg_wd_sel : std_logic_vector(DC_WORD_SEL_BITS-1 downto 0);

  signal data_rdy : std_logic;
  
begin

  U_bus_protocol: block
  begin
    U_st_reg: process(rst,clk4x)
    begin
      if rst = '0' then
        dc_current_st <= st_idle;
      elsif rising_edge(clk4x) then
        dc_current_st <= dc_next_st;
      end if;
    end process U_st_reg;

    dc_current <= dc_state'pos(dc_current_st);  -- for debugging only
    
    U_st_transitions: process(dc_current_st,cpu_sel,miss,mem_rdy,blk_filled)
    begin
      case dc_current_st is
        when st_idle =>                 -- 0
          cpu_rdy <= '1';
          mem_sel <= '1';
          data_rdy <= '1';
          ref_mem <= '0';
          next_word <= '0';
          if cpu_sel = '0' then
            dc_next_st <= st_check;
          else
            dc_next_st <= st_idle;
          end if;
        when st_check =>                -- 1
          cpu_rdy <= '0';
          if cpu_wr = '1' and miss = '0' then
            dc_next_st <= st_hit;
          else
            dc_next_st <= st_start;     -- miss or write-through
          end if;
        when st_hit =>                  -- 2
          cpu_rdy <= '1';
          if cpu_sel = '0' then         -- IF or MEM stalled
            dc_next_st <= st_hit;
          else
            dc_next_st <= st_idle;
          end if;
       when st_start =>                 -- 3
          cpu_rdy <= '0';
          mem_sel <= '0';
          data_rdy <= '1';
          ref_mem <= '1';
          next_word <= '0';
          dc_next_st <= st_waiting;
        when st_waiting =>              -- 4
          data_rdy <= '0';
          if mem_rdy = '0' then
            dc_next_st <= st_waiting;
          else
            dc_next_st <= st_done;
          end if;
        when st_done =>                 -- 5
          mem_sel <= '1';
          data_rdy <= '1';
          ref_mem <= '0';
          next_word <= '1';
          if blk_filled = '1' then
            dc_next_st <= st_hit;
          else
            dc_next_st <= st_start;
          end if;
        when others =>
          assert false report "DATA_CACHE stateMachine broken" &
            integer'image(dc_state'pos(dc_current_st)) severity failure;
      end case;
    end process U_st_transitions;
  end block U_bus_protocol;

  
  U_access: process
    variable inp_tag   : std_logic_vector(DC_TAG_BITS-1 downto 0);
    variable inp_index : std_logic_vector(DC_INDEX_BITS-1 downto 0);
    variable inp_w_sel : std_logic_vector(DC_WORD_SEL_BITS-1 downto 0);
    variable inp_b_sel : std_logic_vector(DC_BYTE_SEL_BITS-1 downto 0);
    
    variable i_index, i_w_sel : integer;
    variable u_w_sel : signed(DC_WORD_SEL_BITS-1 downto 0);
    variable s_w_sel : std_logic_vector(DC_WORD_SEL_BITS-1 downto 0);
    variable tag     : dc_tag;
    variable blk     : dc_block;
    variable wd_sel  : integer;
    variable d_word  : reg32;
    variable i_ref_cnt, i_rd_hit_cnt, i_wr_hit_cnt, i_flush_cnt: integer := 0;
    variable v_miss : std_logic := '0';
  begin

    if rst = '1' then           -- not reset, normal operation

      wait until cpu_sel = '0';

      inp_tag   := cpu_addr(DC_TOP_TAG   downto DC_BOT_TAG);
      inp_index := cpu_addr(DC_TOP_INDEX downto DC_BOT_INDEX);
      inp_w_sel := cpu_addr(DC_TOP_W_SEL downto DC_BOT_W_SEL);
      inp_b_sel := cpu_addr(DC_TOP_B_SEL downto DC_BOT_B_SEL);
      
      i_index := to_integer(unsigned(inp_index));
      i_w_sel := to_integer(unsigned(inp_w_sel));

      tag := dc_tags_matrix(i_index);

      i_ref_cnt := i_ref_cnt + 1;

      -- assert false report "cache val=" & SL2STR(tag.val) &
      --    " tag=" & SLV2STR(tag.tag) & " idx=" & integer'image(i_index) &
      --    " wr=" & SL2STR(cpu_wr); -- DEBUG
      
      if (tag.val = '1') and (tag.tag = inp_tag) then
        v_miss := '0';                  -- HIT: fetch word from block
        miss   <= '0';
      else
        v_miss := '1';
        miss   <= '1';
      end if;

      if cpu_wr = '1' then              -- READ
      
        if v_miss = '0' then            -- READ-hit

          blk := dc_data_matrix(i_index);
          d_word := blk(i_w_sel);

          dbg_index  <= inp_index;
          dbg_wd_sel <= inp_w_sel;
          i_rd_hit_cnt := i_rd_hit_cnt + 1;

          -- assert false report "cache val=" & SL2STR(tag.val) &
          --   " idx=" & integer'image(i_index) &"["& integer'image(i_w_sel)&
          --   "] wr=" & SL2STR(cpu_wr) &" "& SLV32HEX(d_word); -- DEBUG

        else                            -- READ-miss; fill block from RAM

          mem_wr <= '1';
          mem_xfer <= b"1111";
          blk_filled <= '0';
          for i in 0 to DC_WORDS_PER_BLOCK-1 loop

            -- cpu_data_out <= (others => 'X');

            wd_sel := (i_w_sel + i) mod DC_WORDS_PER_BLOCK;
            u_w_sel := to_signed(wd_sel, DC_WORD_SEL_BITS);
            s_w_sel := std_logic_vector(signed(u_w_sel));
            mem_addr <= inp_tag & inp_index & s_w_sel & inp_b_sel;

            dbg_index  <= inp_index;
            dbg_wd_sel <= s_w_sel;

            wait until rising_edge(data_rdy);
            blk(wd_sel) := mem_data_inp;
 
          end loop;  -- i;
          blk_filled <= '1';
          
          tag.tag := inp_tag;
          tag.val := '1';
          dc_tags_matrix(i_index) <= tag;
          dc_data_matrix(i_index) <= blk;
          d_word  := blk(i_w_sel);

          -- assert false report "cache val=" & SL2STR(tag.val) &
          --   " idx=" & integer'image(i_index) &"["& integer'image(i_w_sel)&
          --   "] wr=" & SL2STR(cpu_wr) &" "& SLV32HEX(d_word); -- DEBUG
          
        end if;                         -- READ-miss

        cpu_data_out <= d_word;         -- block filled, send to CPU
        -- case cpu_xfer is             -- partial word-write, handled by RAM
        --   when b"1111"  =>                              -- LW
        --     cpu_data <= d_word;
        --   when b"1100" =>                               -- LH top-half
        --     cpu_data(31 downto 16) <= d_word(31 downto 16);
        --     cpu_data(15 downto  0) <= (others => 'X');
        --   when b"0011" =>                               -- LH bottom-half
        --     cpu_data(31 downto 16) <= (others => 'X');
        --     cpu_data(15 downto  0) <= d_word(15 downto 0);
        --   when b"0001" =>                               -- LB top byte
        --     cpu_data(31 downto  8) <= (others => 'X');
        --     cpu_data(7  downto  0) <= d_word(7 downto 0);
        --   when b"0010" =>                               -- LB mid-top byte
        --     cpu_data(31 downto 16) <= (others => 'X');
        --     cpu_data(15 downto  8) <= d_word(15 downto 8);
        --     cpu_data(7  downto  0) <= (others => 'X');
        --   when b"0100" =>                               -- LB mid-bot byte
        --     cpu_data(31 downto 24) <= (others => 'X');
        --     cpu_data(23 downto 16) <= d_word(23 downto 16);
        --     cpu_data(15 downto  0) <= (others => 'X');
        --   when b"1000" =>                               -- LB bottom byte
        --     cpu_data(31 downto 24) <= d_word(31 downto 24);
        --     cpu_data(23 downto  0) <= (others => 'X');
        --   when others => cpu_data  <= (others => 'X');
        -- end case;
        mem_wr <= '1';
        mem_xfer     <= b"0000";
        mem_data_out <= (others => 'X');
        mem_addr     <= (others => 'X');

        wait until rising_edge(cpu_sel);
        cpu_data_out <= (others => 'X');

      else                              -- WRITE

        if v_miss = '0' then            -- WRITE-hit

          blk := dc_data_matrix(i_index);
          d_word := blk(i_w_sel);       -- merge partial writes in-cache
          case cpu_xfer is
            when b"1111"  =>                              -- LW
              d_word := cpu_data_inp;
            when b"1100" =>                               -- LH top-half
              d_word(31 downto 16) := cpu_data_inp(15 downto 0);
            when b"0011" =>                               -- LH bottom-half
              d_word(15 downto  0) := cpu_data_inp(15 downto 0);
            when b"0001" =>                               -- LB top byte
              d_word(7  downto  0) := cpu_data_inp(7 downto 0);
            when b"0010" =>                               -- LB mid-top byte
              d_word(15 downto  8) := cpu_data_inp(7 downto 0);
            when b"0100" =>                               -- LB mid-bot byte
              d_word(23 downto 16) := cpu_data_inp(7 downto 0);
            when b"1000" =>                               -- LB bottom byte
              d_word(31 downto 24) := cpu_data_inp(7 downto 0);
            when others => d_word  := (others => 'X');
          end case;

          blk(i_w_sel) := d_word;
          dc_data_matrix(i_index) <= blk;

          -- assert false report "wrHIT val=" & SL2STR(tag.val) &
          --   " idx=" & integer'image(i_index) &"["& integer'image(i_w_sel)&
          --   "] wr=" & SL2STR(cpu_wr) &" "& SLV32HEX(d_word); -- DEBUG
          
          dbg_index  <= inp_index;
          dbg_wd_sel <= s_w_sel;
          i_wr_hit_cnt := i_wr_hit_cnt + 1;
          
        end if;

        -- write through to memory
        wd_sel := i_w_sel;
        u_w_sel := to_signed(wd_sel, DC_WORD_SEL_BITS);
        s_w_sel := std_logic_vector(signed(u_w_sel));
        mem_addr <= inp_tag & inp_index & s_w_sel & inp_b_sel;

        dbg_index  <= inp_index;
        dbg_wd_sel <= s_w_sel;
        
        blk_filled <= '0';
        mem_wr     <= '0';
        mem_xfer     <= cpu_xfer;
        mem_data_out <= cpu_data_inp;

        -- assert false report "wrMEM val=" & SL2STR(tag.val) &
        --   " idx=" & integer'image(i_index) &"["& integer'image(i_w_sel)&
        --   "] wr=" & SL2STR(cpu_wr) &" "& SLV32HEX(cpu_data); -- DEBUG

        wait until falling_edge(ref_mem);

        blk_filled <= '1';
        mem_wr     <= '1';
        mem_xfer   <= b"0000";
        mem_data_out <= (others => 'X');
        mem_addr     <= (others => 'X');
      end if;                           -- READ/WRITE
      
    else  -- reset: initialize cache tags, all interfaces in tri-state

      cpu_data_out <= (others => 'X');
      mem_data_out <= (others => 'X');
      mem_addr   <= (others => 'X');
      mem_xfer   <= b"0000";
      mem_wr     <= '1';
      miss       <= '0';
      blk_filled <= '0';
      d_word   := (others => 'X');
      inp_tag   := (others => 'X');
      inp_index := (others => 'X');
      inp_w_sel := (others => 'X');
      
      tag.val := '0';
      tag.tag := (others => 'X');
      for i in dc_tags_matrix'range loop
        dc_tags_matrix(i) <= tag;
      end loop;

      i_ref_cnt    := 0;
      i_rd_hit_cnt := 0;
      i_wr_hit_cnt := 0;
      i_flush_cnt  := 0;
    end if;  -- reset

    ref_cnt    <= i_ref_cnt;
    rd_hit_cnt <= i_rd_hit_cnt;
    wr_hit_cnt <= i_wr_hit_cnt;
    flush_cnt  <= i_flush_cnt;
    wait on rst, cpu_sel, cpu_wr, ref_mem, data_rdy, dc_current_st;
    
  end process U_access; ---------------------------------------------------
    
end behavioral;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- fake data cache -- pass along all signals unchanged
-- TODO: 
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture fake of D_CACHE is
begin
  mem_sel  <= cpu_sel;
  cpu_rdy  <= mem_rdy;
  mem_wr   <= cpu_wr;
  mem_addr <= cpu_addr;
  mem_xfer <= cpu_xfer;

  mem_data_out <= cpu_data_inp when (cpu_sel = '0') and (cpu_wr = '0') else
                  (others => 'X');

  cpu_data_out <= mem_data_inp when (cpu_sel = '0') and (cpu_wr = '1') else
                  (others => 'X');
          
  ref_cnt    <= 0;
  rd_hit_cnt <= 0;
  wr_hit_cnt <= 0;
  flush_cnt  <= 0;
end fake;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++






-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- instruction cache, word-indexed
-- TODO: early restart, associativity
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;

entity I_CACHE is
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
  
end entity I_CACHE;


architecture behavioral of I_CACHE is
  
  type ic_block is array (natural range 0 to (IC_WORDS_PER_BLOCK-1)) of reg32;
  type ic_data is array  (natural range 0 to (IC_NUM_BLOCKS-1)) of ic_block;
  signal ic_data_matrix : ic_data;

  type ic_tag is record
    val : std_logic;
    tag : std_logic_vector((IC_TAG_BITS-1) downto 0);
  end record;
  type ic_tags is array (natural range 0 to (IC_NUM_BLOCKS-1)) of ic_tag;
  signal ic_tags_matrix : ic_tags;

  signal miss,blk_filled,next_word : std_logic := '0';

  type ic_state is(st_idle, st_check, st_hit, st_start, st_waiting, st_done);
  attribute SYN_ENCODING of ic_state : type is "safe";
  signal ic_current_st,ic_next_st : ic_state;
  signal ic_current : integer;

  signal dbg_index  : std_logic_vector(IC_INDEX_BITS-1 downto 0);
  signal dbg_wd_sel : std_logic_vector(IC_WORD_SEL_BITS-1 downto 0);
  
begin

  ic_reset <= '1';
  
  U_st_reg: process(rst,clk4x)
  begin
    if rst = '0' then
      ic_current_st <= st_idle;
    elsif rising_edge(clk4x) then
      ic_current_st <= ic_next_st;
    end if;
  end process U_st_reg;

  ic_current <= ic_state'pos(ic_current_st);  -- for debugging only
  
  U_st_transitions: process(ic_current_st,cpu_sel,miss,mem_rdy,blk_filled)
  begin
    case ic_current_st is
      when st_idle =>
        cpu_rdy <= '1';
        mem_sel <= '1';
        next_word <= '0';
        if cpu_sel = '0' then
          ic_next_st <= st_check;
        else
          ic_next_st <= st_idle;
        end if;
      when st_check =>
        cpu_rdy <= '1';
        mem_sel <= '1';
        if miss = '0' then
          ic_next_st <= st_hit;
        else
          ic_next_st <= st_start;
        end if;
      when st_hit =>
        cpu_rdy <= '1';
        mem_sel <= '1';
        if cpu_sel = '0' then         -- IFetch or MEM stalled
          ic_next_st <= st_hit;
        else
          ic_next_st <= st_idle;
        end if;
      when st_start =>
        cpu_rdy <= '0';
        mem_sel <= '0';
        next_word <= '0';
        ic_next_st <= st_waiting;
      when st_waiting =>
        cpu_rdy <= '0';
        mem_sel <= '0';
        if mem_rdy = '0' then
          ic_next_st <= st_waiting;
        else
          ic_next_st <= st_done;
        end if;
      when st_done =>
        cpu_rdy <= '0';
        mem_sel <= '1';
        next_word <= '1';
        if blk_filled = '1' then
          ic_next_st <= st_hit;
        else
          ic_next_st <= st_start;
        end if;
      when others =>
        cpu_rdy <= 'X';
        mem_sel <= 'X';
        assert false report "I_CACHE stateMachine broken" &
          integer'image(ic_state'pos(ic_current_st)) severity failure;
    end case;
  end process U_st_transitions;

  
  U_access: process
    variable inp_tag   : std_logic_vector(IC_TAG_BITS-1 downto 0);
    variable inp_index : std_logic_vector(IC_INDEX_BITS-1 downto 0);
    variable inp_w_sel : std_logic_vector(IC_WORD_SEL_BITS-1 downto 0);
    -- variable byte_sel  : std_logic_vector(IC_BYTE_SEL_BITS-1 downto 0)
    --   := (others => '0');

    variable i_ref_cnt, i_hit_cnt: integer := 0;
    variable i_index, i_w_sel : integer;
    variable u_w_sel : signed(IC_WORD_SEL_BITS-1 downto 0);
    variable s_w_sel : std_logic_vector(IC_WORD_SEL_BITS-1 downto 0);
    variable tag     : ic_tag;
    variable blk     : ic_block;
    variable wd_sel  : integer;
    variable d_word  : reg32;
  begin

    if rst = '1' then           -- not reset, normal operation

      wait until cpu_sel = '0';

      inp_tag   := cpu_addr(IC_TOP_TAG   downto IC_BOT_TAG);
      inp_index := cpu_addr(IC_TOP_INDEX downto IC_BOT_INDEX);
      inp_w_sel := cpu_addr(IC_TOP_W_SEL downto IC_BOT_W_SEL);

      dbg_index <= inp_index;
      
      i_index := to_integer(unsigned(inp_index));
      i_w_sel := to_integer(unsigned(inp_w_sel));

      tag := ic_tags_matrix(i_index);

      i_ref_cnt := i_ref_cnt + 1;
      
      -- assert false report "cache val=" & SL2STR(tag.val) & " tag="
      --   & SLV2STR(tag.tag)  severity note;  -- DEBUG
      
      if (tag.val = '1') and (tag.tag = inp_tag) then

        miss <= '0';
        blk := ic_data_matrix(i_index);
        d_word := blk(i_w_sel);
        i_hit_cnt := i_hit_cnt + 1;
        
      else

        miss <= '1';
        blk_filled <= '0';

        for i in 0 to IC_WORDS_PER_BLOCK-1 loop

          cpu_data <= (others => 'X');
          
          wd_sel := (i_w_sel + i) mod IC_WORDS_PER_BLOCK;
          u_w_sel := to_signed(wd_sel, IC_WORD_SEL_BITS);
          s_w_sel := std_logic_vector(signed(u_w_sel));
          mem_addr <= inp_tag & inp_index & s_w_sel & b"00"; -- byte_sel;
          dbg_wd_sel <= s_w_sel;
          
          wait until rising_edge(mem_rdy);
          blk(wd_sel) := mem_data;
          wait until rising_edge(next_word);
          
        end loop;  -- i;
        blk_filled <= '1';
        
        tag.tag := inp_tag;
        tag.val := '1';
        ic_tags_matrix(i_index) <= tag;
        ic_data_matrix(i_index) <= blk;
        d_word  := blk(i_w_sel);

      end if;

    else  -- reset: initialize cache tags, interface signals in tri-state

      miss       <= '0';
      blk_filled <= '0';
      d_word    := (others => 'X');
      inp_tag   := (others => 'L');
      inp_index := (others => 'L');
      inp_w_sel := (others => 'L');
      
      tag.val   := '0';
      tag.tag   := (others => 'X');
      for i in ic_tags_matrix'range loop
        ic_tags_matrix(i) <= tag;
      end loop;

      i_ref_cnt := 0;
      i_hit_cnt := 0;
    end if;  -- reset

    cpu_data <= d_word;

    ref_cnt <= i_ref_cnt;
    hit_cnt <= i_hit_cnt;
    
    wait on rst, cpu_sel, mem_rdy, next_word;
    
  end process U_access; ---------------------------------------------------
    
end behavioral;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- fake instruction cache -- pass along all signals unchanged
-- TODO: 
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture fake of I_CACHE is
begin
  ic_reset <= '1';
  mem_sel  <= cpu_sel;
  cpu_rdy  <= mem_rdy;
  mem_addr <= cpu_addr;
  cpu_data <= mem_data;

  ref_cnt  <= 0;
  hit_cnt  <= 0;
end fake;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
