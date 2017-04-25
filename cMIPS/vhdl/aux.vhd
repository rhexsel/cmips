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



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- 32-bit register, synchronous load active in '0'
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;

entity register32 is
  generic (INITIAL_VALUE: reg32 := x"00000000");
  port(clk, rst, ld: in  std_logic;
        D:           in  reg32;
        Q:           out reg32);
end register32;

architecture functional of register32 is
begin
  process(clk, rst)
    variable state: reg32;
  begin
    if rst = '0' then
      state := INITIAL_VALUE;
    elsif rising_edge(clk) then
      if ld = '0' then
        state := D;
      end if;
    end if;
    Q <= state;
  end process;
  
end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- N-bit register, synchronous load active in '0', asynch reset
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
entity registerN is
  generic (NUM_BITS: integer := 16;
           INIT_VAL: std_logic_vector);
  port(clk, rst, ld: in  std_logic;
       D:            in  std_logic_vector(NUM_BITS-1 downto 0);
       Q:            out std_logic_vector(NUM_BITS-1 downto 0));
end registerN;

architecture functional of registerN is
begin
  process(clk, rst)
    variable state: std_logic_vector(NUM_BITS-1 downto 0);
  begin
    if rst = '0' then
      state := INIT_VAL;
    elsif rising_edge(clk) then
      if ld = '0' then
        state := D;
      end if;
    end if;
    Q <= state;
  end process;
  
end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- 32-bit UP counter, {load,enable} synchronous, active in '0'
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_WIRES.all;
entity counter32 is
  generic (INITIAL_VALUE: reg32 := x"00000000");
  port(clk, rst, ld, en: in  std_logic;
        D:               in  reg32;
        Q:               out reg32);
end counter32;

architecture functional of counter32 is
  signal count: reg32;
begin

  process(clk, rst)
  begin
    if rst = '0' then
      count <= INITIAL_VALUE;
    elsif rising_edge(clk) then
      if ld = '0' then 
        count <= D;
      elsif en = '0' then
        count <= std_logic_vector(unsigned(count) + 1);
      end if;
    end if;
  end process;

  Q <= count;

end functional;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- N-bit counter, synch load (=1), synch enable (=1), asynch reset (=0)
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity countNup is
  generic (NUM_BITS: integer := 16);
  port(clk, rst, ld, en: in  std_logic;
       D:                in  std_logic_vector((NUM_BITS - 1) downto 0);
       Q:                out std_logic_vector((NUM_BITS - 1) downto 0);
       co:               out std_logic);
end countNup;

architecture functional of countNup is
  signal count: std_logic_vector(NUM_BITS downto 0);
begin

  process(clk, rst)
    constant ZERO : std_logic_vector(NUM_BITS downto 0) := (others => '0');
  begin
    if rst = '0' then
      count <= ZERO;
    elsif rising_edge(clk) then
      if ld = '1' then
        count <= '0' & D;
      elsif en = '1' then
        count <= std_logic_vector(unsigned(count) + 1);
      end if;
    end if;
  end process;

  Q  <= count((NUM_BITS - 1) downto 0);
  co <= count(NUM_BITS);
  
end functional;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++





-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ring-counter, generates four-phase internal clock, on falling-edge
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_WIRES.all;
entity count4phases is
  port(clk, rst    : in  std_logic;
       p0,p1,p2,p3 : out std_logic);
  -- attribute ASYNC_SET_RESET of rst : signal is true;
  -- attribute CLOCK_SIGNAL of clk : signal is "yes";
end count4phases;

architecture functional of count4phases is
  signal count: reg4 := b"1000";
begin

  process(clk, rst)
  begin
    if rst = '0' then
      count <= b"1000";
    elsif falling_edge(clk) then
      count <= count(2 downto 0) & count(3);
    end if;
  end process;

  p0 <= count(0);
  p1 <= count(1);
  p2 <= count(2);
  p3 <= count(3);

end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- D-type flip-flop with set and reset
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE; use IEEE.std_logic_1164.all;

entity FFD is
  port(clk, rst, set : in std_logic;
        D : in  std_logic;
        Q : out std_logic);
end FFD;

architecture functional of FFD is
begin

  process(clk, rst, set)
    variable state: std_logic;
  begin
    if rst = '0' then
      state := '0';
    elsif set = '0' then
      state := '1';
    elsif rising_edge(clk) then
      state := D;
    end if;
    Q <= state;
  end process;

end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- D-type flip-flop with reset
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE; use IEEE.std_logic_1164.all;

entity FFDsimple is
  port(clk, rst : in std_logic;
        D : in  std_logic;
        Q : out std_logic);
end FFDsimple;

architecture functional of FFDsimple is
begin

  process(clk, rst)
    variable state: std_logic;
  begin
    if rst = '0' then
      state := '0';
    elsif rising_edge(clk) then
      state := D;
    end if;
    Q <= state;
  end process;

end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- T-type flip-flop with reset (active 0)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE; use IEEE.std_logic_1164.all;

entity FFT is
  port(clk, rst : in std_logic;
        T : in  std_logic;
        Q : out std_logic);
end FFT;

architecture functional of FFT is
begin

  process(clk, rst)
    variable state: std_logic;
  begin
    if rst = '0' then
      state := '0';
    elsif rising_edge(clk) then
      state := T xor state;
    end if;
    Q <= state;
  end process;

end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity subtr32 IS
  port(A, B : in  std_logic_vector (31 downto 0);
       C    : out std_logic_vector (31 downto 0);
       sgnd     : in  std_logic;
       ovfl, lt : out std_logic);
end subtr32;
  
architecture functional of subtr32 is
  signal extA,extB,extC,negB : std_logic_vector (32 downto 0);
begin

  extA <= A(31) & A when sgnd = '1'
          else '0' & A;
  extB <= B(31) & B when sgnd = '1'
          else '0' & B;
  negB <= not(extB);
  extC <= std_logic_vector( signed(extA) + signed(negB) + 1);

  C    <= extC(31 downto 0);
  ovfl <= '1' when extC(32) /= extC(31) else '0';
  lt   <= not(extC(31)) when (extC(32) /= extC(31)) else extC(31);
  
end architecture functional;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



