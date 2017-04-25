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
-- These components are replacements for Altera's Megafunctions.
-- They are meant to be used only in simulation; for synthesis, the
--   real Megafunctions must be used instead of these 'fakes'.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- -----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity mf_alt_add_4 is
  port(datab : in std_logic_vector (31 downto 0);
       result : out std_logic_vector (31 downto 0) );
end mf_alt_add_4;

architecture functional of mf_alt_add_4 is
begin
  result <= std_logic_vector( 4 + signed(datab) );
end architecture functional;
-- -----------------------------------------------------------------------


-- -----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity mf_alt_adder is
  port(dataa  : in std_logic_vector (31 downto 0);
       datab  : in std_logic_vector (31 downto 0);
       result : out std_logic_vector (31 downto 0));
end mf_alt_adder;
  
architecture functional of mf_alt_adder is
begin
  result <= std_logic_vector( signed(dataa) + signed(datab) );
end architecture functional;
-- -----------------------------------------------------------------------


-- -----------------------------------------------------------------------
-- add/subtract SIGNED numbers
-- -----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity mf_alt_add_sub is
  port(add_sub         : IN STD_LOGIC;  -- add=1, sub=0
       dataa           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
       datab           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
       overflow        : OUT STD_LOGIC;
       result          : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
end mf_alt_add_sub;
  
architecture functional of mf_alt_add_sub is
  signal ext_a,ext_b, ext_add_C,ext_sub_C : STD_LOGIC_VECTOR (32 DOWNTO 0);
  signal ovfl_add,ovfl_sub : std_logic;
begin

  ext_A  <= dataa(31) & dataa;
  ext_B  <= datab(31) & datab;
  ext_add_C <= std_logic_vector(signed(ext_A) + signed(ext_B));
  ovfl_add  <= '1' when (ext_add_C(32) /= ext_add_C(31)) else '0';
    
  ext_sub_C <= std_logic_vector(signed(ext_A)+signed(signed(not ext_B)+1));
  ovfl_sub  <= '1' when (ext_sub_C(32) /= ext_sub_C(31)) else '0';

  result <= ext_add_C(31 downto 0) when add_sub='1' else
            ext_sub_C(31 downto 0);

  overflow <= ovfl_add when add_sub='1' else
              ovfl_sub;
  
end architecture functional;
-- -----------------------------------------------------------------------


-- -----------------------------------------------------------------------
-- add/subtract UN-SIGNED numbers, does not signal overflow
-- -----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity mf_alt_add_sub_u is
  port(add_sub         : IN STD_LOGIC;  -- add=1, sub=0
       dataa           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
       datab           : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
       result          : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
end mf_alt_add_sub_u;
  
architecture functional of mf_alt_add_sub_u is
  signal add_C, sub_C : STD_LOGIC_VECTOR (31 DOWNTO 0);
begin

  add_C <= std_logic_vector(unsigned(dataa) + unsigned(datab));
    
  sub_C <= std_logic_vector(unsigned(dataa)+unsigned(unsigned(not datab)+1));

  result <= add_C(31 downto 0) when add_sub='1' else
            sub_C(31 downto 0);
  
end architecture functional;
-- -----------------------------------------------------------------------


-- -----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity mf_ram1port is
  generic (N_WORDS : integer; ADDRS_BITS : integer);
  port (address : in  std_logic_vector (ADDRS_BITS-1 downto 0);
        clken   : in  std_logic;
        clock   : in  std_logic;
        data    : in  std_logic_vector (7 downto 0);
        wren    : in  std_logic;
        q       : out std_logic_vector (7 downto 0));
end mf_ram1port;
  
architecture rtl of mf_ram1port is

  -- Build a 2-D array type for the RAM
  subtype word_t is std_logic_vector(7 downto 0);
  type memory_t is array(0 to N_WORDS - 1) of word_t;

  -- Declare the RAM signal.
  signal ram : memory_t;
  
  -- Register to hold the address
  signal addr, addr_reg : natural range 0 to N_WORDS - 1;

begin

  addr <= to_integer(unsigned(address));

  U_addr: process(clock)
  begin
    if rising_edge(clock) then
      -- Register the address for reading
      addr_reg <= addr;
    end if;
  end process U_addr;
  
  U_write: process(clock)
  begin
    if (clken = '1') and rising_edge(clock) then
      if (wren = '1') then
        ram(addr) <= data;
      end if;
    end if;
  end process U_write;
  
  q <= ram(addr_reg);
  
end architecture rtl;
-- -----------------------------------------------------------------------



-- fake ROM megafunction = not used in simulation, only on the FPGA ------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;

entity alt_mf_rom is port (
  address         : IN STD_LOGIC_VECTOR ((INST_ADDRS_BITS-1) DOWNTO 0);
  clken           : IN STD_LOGIC  := '1';
  clock           : IN STD_LOGIC  := '1';
  q               : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
end alt_mf_rom;
  
architecture fake of alt_mf_rom is
begin  -- fake
  q <= (others => 'X');
end fake;
-- -----------------------------------------------------------------------



-- PLL for CPU clocks ----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity mf_altpll is port (
    areset          : IN  STD_LOGIC;
    inclk0          : IN  STD_LOGIC;    -- 50MHz input
    c0              : OUT STD_LOGIC;    -- 50MHz, 25% duty cycle, phase 0
    c1              : OUT STD_LOGIC;    -- 50MHz, 25% duty cycle, phase 120
    c2              : OUT STD_LOGIC;    -- 50MHz, 25% duty cycle, phase 180
    c3              : OUT STD_LOGIC;    -- 50MHz, 25% duty cycle, phase 270
    c4              : OUT STD_LOGIC);   -- 50MHz, 50% duty cycle, phase 0
end mf_altpll;

architecture functional of mf_altpll is

  component count4phases is
    port(clk, rst    : in  std_logic;
         p0,p1,p2,p3 : out std_logic);
  end component count4phases;

  component FFD is
    port(clk, rst, set, D : in std_logic; Q : out std_logic);
  end component FFD;

  signal clk4x, phi0,phi1,phi2,phi3, phi2_dlyd : std_logic;
  
begin

  U_clock4x: process  --  clk and clk4x MUST start in opposite phases
  begin
    clk4x <= '0';
    wait for CLOCK_PER / 8;
    clk4x <= '1';
    wait for CLOCK_PER / 8;
  end process;
  
  U_4PHASE_CLOCK: count4phases
    port map (clk4x, areset, phi0,phi1,phi2,phi3);

  -- U_DELAY_PHI2: FFD port map (clk4x, areset, '1', phi2, phi2_dlyd);

  c0 <= phi3;
  c1 <= phi0;
  c2 <= phi1;
  c3 <= phi2;
  c4 <= inclk0;
  
end architecture functional;
-- -----------------------------------------------------------------------




-- PLL for I/O devices ---------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity mf_altpll_io is port (
    areset          : IN  STD_LOGIC;
    inclk0          : IN  STD_LOGIC;    -- 50 MHz
    c0              : OUT STD_LOGIC;    -- 100MHz, in phase
    c1              : OUT STD_LOGIC;    -- 200MHz, in phase
    c2              : OUT STD_LOGIC);   -- 200MHz, opposite phase
end mf_altpll_io;

architecture functional of mf_altpll_io is
  signal clk2x, clk4x0, clk4x180 : std_logic;
begin

  U_clock2x: process  --  in phase with inclk0
  begin
    clk2x <= '1';
    wait for CLOCK_PER / 4;
    clk2x <= '0';
    wait for CLOCK_PER / 4;
  end process;

  U_clock4x: process  --  clk and clk4x180 MUST start in opposite phases
  begin
    clk4x180 <= '0';
    wait for CLOCK_PER / 8;
    clk4x180 <= '1';
    wait for CLOCK_PER / 8;
  end process;

  clk4x0 <= not(clk4x180);

  c0 <= clk2x;
  c1 <= clk4x0;
  c2 <= clk4x180;
  
end architecture functional;
-- -----------------------------------------------------------------------


-- -----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity mf_altclkctrl is port (
  inclk     : IN  STD_LOGIC;
  outclk    : OUT STD_LOGIC); 
end mf_altclkctrl;

architecture functional of mf_altclkctrl is
begin
  outclk <= inclk;
end architecture functional;
-- -----------------------------------------------------------------------
