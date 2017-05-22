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
-- syncronous ROM; FPGA version, word-indexed
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;

entity ROM is
  generic (LOAD_FILE_NAME : string := "prog.bin");  -- not used with FPGA
  port (rst    : in    std_logic;
        clk    : in    std_logic;
        sel    : in    std_logic;         -- active in '0'
        rdy    : out   std_logic;         -- active in '0'
        strobe : in    std_logic;
        addr   : in    reg32;
        data   : out   reg32);
  
  -- FPGA version
  constant INST_ADDRS_BITS : natural := log2_ceil(INST_MEM_SZ);
  subtype rom_address is natural range 0 to ((INST_MEM_SZ / 4) - 1);
end entity ROM;

architecture rtl of ROM is

  component wait_states is
    generic (NUM_WAIT_STATES :integer := 0);
    port(rst     : in  std_logic;
         clk     : in  std_logic;
         sel     : in  std_logic;         -- active in '0'
         waiting : out std_logic);        -- active in '1'
  end component wait_states;

  component single_port_rom is
    generic (N_WORDS : integer);
    port (address : in rom_address;
          clken   : in std_logic;
          clock   : in std_logic;
          q       : out std_logic_vector);
  end component single_port_rom;

  component alt_mf_rom 
    port (address         : IN STD_LOGIC_VECTOR ((INST_ADDRS_BITS-1) DOWNTO 0);
          clken           : IN STD_LOGIC  := '1';
          clock           : IN STD_LOGIC  := '1';
          q               : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
  end component alt_mf_rom;
  
  signal instrn : reg32;
  signal index  : rom_address := 0;
  signal waiting, clken : std_logic;
  signal raw_addr : std_logic_vector((INST_ADDRS_BITS-1) downto 0);
  
begin  -- rtl

  U_BUS_WAIT: wait_states generic map (ROM_WAIT_STATES)
    port map (rst, clk, sel, waiting);

  rdy <= not(waiting);

  clken  <= not(sel);
    
  -- >>2 = /4: byte addressed but word indexed
  index <= to_integer(unsigned(addr((INST_ADDRS_BITS-1)+2 downto 2)));

  -- U_ROM: single_port_rom generic map (INST_MEM_SZ / 4)
  --  port map (index, clken, strobe, instrn);

  
  raw_addr <= addr((INST_ADDRS_BITS-1)+2 downto 2);
  U_RTL_ROM: alt_mf_rom port map (raw_addr, clken, strobe, instrn);

  
  U_ROM_ACCESS: process (instrn, sel, index)
  begin
    if sel = '0' then
      data <= instrn;
      assert (index >= 0) and (index < INST_MEM_SZ/4)
        report "rom index out of bounds: " & natural'image(index)
        severity failure;
      assert TRUE -- DEBUG
        report "romRD["& natural'image(index) &"]="& SLV32HEX(instrn); 
    else
      data <= (others => 'X');
    end if;
  end process U_ROM_ACCESS;

end architecture rtl;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Adapted from Altera's design for a ROM that may be synthesized
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.p_wires.all;

entity single_port_rom is
  generic (N_WORDS : integer := 32);
  port (address : in natural range 0 to (N_WORDS - 1);
        clken   : in std_logic;
        clock   : in std_logic;
        q       : out reg32);
end entity;

architecture rtl of single_port_rom is

  -- Build a 2-D array type for the RoM
  subtype word_t is std_logic_vector(31 downto 0);
  type memory_t is array(0 to (N_WORDS-1)) of word_t;

  -- assemble.sh -v mac_lcd.s |\
  -- sed -e '1,6d' -e '/^$/d' -e '/^ /!d' -e 's:\t: :g' \
  -- -e 's#\(^ *[a-f0-9]*:\) *\(........\)  *\(.*\)$#x"\2", -- \1 \3#' \
  -- -e '$s:,: :' 
  
  constant test_prog : memory_t := (others => (others => '0'));

  function init_rom
    return memory_t is
    variable tmp : memory_t := (others => (others => '0'));
    variable i_addr : integer;
  begin
    for addr_pos in test_prog'range loop
      tmp(addr_pos) := test_prog(addr_pos);
      -- i_addr := addr_pos;
    end loop;

    for addr_pos in test_prog'high to (N_WORDS - 1) loop
      tmp(addr_pos) := x"00000000";      -- nop
    end loop;
    return tmp;
  end init_rom;

  -- Declare the ROM signal and specify a default value. Quartus II
  -- will create a memory initialization file (ROM.mif) based on the 
  -- default value.
  signal rom : memory_t := init_rom;

begin
  
  process(clock,clken)
  begin
    if(clken = '1' and rising_edge(clock)) then
      q <= rom(address);
    end if;
  end process;
  
end architecture rtl;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- syncronous ROM; MIPS executable loaded into ROM at CPU reset, wd-indexed
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture simulation of ROM is

  component wait_states is
    generic (NUM_WAIT_STATES :integer := 0);
    port(rst     : in  std_logic;
         clk     : in  std_logic;
         sel     : in  std_logic;         -- active in '0'
         waiting : out std_logic);        -- active in '1'
  end component wait_states;
  
  component FFT is
    port(clk, rst, T : in std_logic; Q : out std_logic);
  end component FFT;
  
  constant WAIT_COUNT : max_wait_states := (NUM_MAX_W_STS - ROM_WAIT_STATES);
  constant WAIT_FOR : reg10 := std_logic_vector(to_signed(WAIT_COUNT, 10));

  signal waiting, do_wait : std_logic;

begin  -- behavioral

  U_BUS_WAIT: wait_states generic map (ROM_WAIT_STATES)
     port map (rst, clk, sel, waiting);
 
  rdy <= not(waiting);
  
  U_ROM: process (rst, sel, strobe, addr)

    subtype t_address is unsigned((INST_ADDRS_BITS - 1) downto 0);
    variable u_addr : t_address;
    
    subtype word is std_logic_vector(data'length - 1 downto 0);
    type storage_array is
      array( natural range 0 to (INST_MEM_SZ - 1) ) of word;
    variable storage : storage_array;
    variable index, latched : natural;
    
    type binary_file is file of integer;
    file load_file: binary_file open read_mode is LOAD_FILE_NAME;
    variable instr: integer; -- := to_integer(unsigned(NULL_INSTRUCTION));
    variable s_instr : signed(31 downto 0);
    
  begin

    if rst = '0' then                   -- reset, read binary executable
      
      index := 0;                       -- indexed by word
      for i in 0 to (INST_MEM_SZ - 1)  loop

        if not endfile(load_file) then
          read(load_file, instr);
          s_instr := to_signed(instr, 32);
          assert TRUE report "romINIT["& natural'image(index*4) &"]= " &
            SLV32HEX(std_logic_vector(s_instr)); -- DEBUG
          storage(index) := std_logic_vector(s_instr);
          index := index + 1;
        end if;

      end loop;  -- i
      
    else                                -- normal operation

      u_addr := unsigned(addr((2+(INST_ADDRS_BITS-1)) downto 2)); -- >>2 = /4
      index  := to_integer(u_addr);     -- indexed by word, not by byte

      assert (index >= 0) and (index < INST_MEM_SZ/4)
        report "romRDindex out of bounds: " & SLV32HEX(addr) & " = " &
               natural'image(index)  severity warning; -- failure;

      if sel = '0' and rising_edge(strobe) then 
        latched := index;
      end if;  
      
      if sel = '0' then
        data <= storage(latched);
        assert TRUE -- DEBUG
          report "romRD["& natural'image(index) &"]="& SLV32HEX(storage(index)); 
      else
        data <= (others => 'X');
      end if;

    end if;

  end process;

end architecture simulation;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

