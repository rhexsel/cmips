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




-- To simplify (and accelerate) internal address decoding,
--  the BASE of the RAM addresses MUST be allocated at an
--  address that is larger the RAM capacity.  Otherwise, the
--  base must be subtracted from the address on every reference,
--  which means having an adder in the critical path.  Bad idea.



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- syncronous RAM for synthesis; NON-initialized, byte-indexed
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
use work.p_memory.all;

entity RAM is
  generic (LOAD_FILE_NAME : string := "data.bin";
           DUMP_FILE_NAME : string := "dump.data");
  port (rst      : in    std_logic;
        clk      : in    std_logic;
        sel      : in    std_logic;         -- active in '0'
        rdy      : out   std_logic;         -- active in '0'
        wr       : in    std_logic;         -- active in '0'
        strobe   : in    std_logic;         -- active in '1'
        addr     : in    reg32;
        data_inp : in    reg32;
        data_out : out   reg32;
        byte_sel : in    reg4;
        dump_ram : in    std_logic);        -- dump RAM contents

  -- simulation version
  constant DATA_ADDRS_BITS : natural := log2_ceil(DATA_MEM_SZ);

  -- FPGA version
  constant N_WORDS : natural := 8192;
  constant ADDRS_BITS : natural := log2_ceil(N_WORDS);
  subtype ram_address is integer range 0 to N_WORDS-1;
  subtype ram_addr_bits is std_logic_vector(ADDRS_BITS-1 downto 0);
end entity RAM;

architecture rtl of RAM is

  component mf_ram1port
    generic (N_WORDS : integer; ADDRS_BITS : integer);
    port (address    : in  std_logic_vector (ADDRS_BITS-1 downto 0);
          clken      : in  std_logic;
          clock      : in  std_logic;
          data       : in  std_logic_vector (7 downto 0);
          wren       : in  std_logic;
          q          : out std_logic_vector (7 downto 0));
  end component mf_ram1port;

  component wait_states is
    generic (NUM_WAIT_STATES :integer);
    port(rst     : in  std_logic;
         clk     : in  std_logic;
         sel     : in  std_logic;         -- active in '0'
         waiting : out std_logic);        -- active in '1'
  end component wait_states;
  
  signal we0,we1,we2,we3 : std_logic := '0';
  signal di,do : reg32;

  signal r_addr : ram_address := 0;
  signal r_address : ram_addr_bits;

  signal waiting, enable : std_logic;
  
begin  -- rtl

  U_BUS_WAIT: wait_states generic map (RAM_WAIT_STATES)
    port map (rst, clk, sel, waiting);

  rdy <= not(waiting);

  enable <= not(sel);
 
  -- CPU acesses are word-addressed; RAM is byte-addressed, 4-bytes wide
  r_addr <= to_integer( unsigned(addr( (ADDRS_BITS-1+2) downto 2 ) ) );

  r_address <= addr( ADDRS_BITS-1+2 downto 2 );
  
  U_ram0: mf_ram1port generic map (N_WORDS, ADDRS_BITS) port map (
    r_address, enable, strobe, di(7  downto  0), we0, do(7  downto 0));

  U_ram1: mf_ram1port  generic map (N_WORDS, ADDRS_BITS) port map (
    r_address, enable, strobe, di(15 downto  8), we1, do(15 downto 8));

  U_ram2: mf_ram1port  generic map (N_WORDS, ADDRS_BITS) port map (
    r_address, enable, strobe, di(23 downto 16), we2, do(23 downto 16));

  U_ram3: mf_ram1port  generic map (N_WORDS, ADDRS_BITS) port map (
    r_address, enable, strobe, di(31 downto 24), we3, do(31 downto 24));


  accessRAM: process(sel, strobe, wr, r_addr, byte_sel, data_inp, do)
  begin

    if sel = '0' then

      if wr = '0' then                  -- WRITE to MEM
        
        assert (r_addr >= 0) and (r_addr < (DATA_MEM_SZ/4))
          report "ramWR index out of bounds: " & natural'image(r_addr)
          severity failure;

        case byte_sel is                -- partial word stores
          when b"1111"  =>      -- SW
            we3 <= '1';
            we2 <= '1';
            we1 <= '1';
            we0 <= '1';
            di  <= data_inp;
          when b"1100" =>       -- SH, upper
            we3 <= '1';
            we2 <= '1';
            we1 <= '0';
            we0 <= '0';
            di(31 downto 16) <= data_inp(15 downto 0);
            di(15 downto 0)  <= (others => 'X');
          when b"0011" =>       -- SH. lower
            we3 <= '0';
            we2 <= '0';
            we1 <= '1';
            we0 <= '1';
            di(15 downto 0)  <= data_inp(15 downto 0);
            di(31 downto 16) <= (others => 'X');
          when b"0001" =>       -- SB
            we3 <= '0';
            we2 <= '0';
            we1 <= '0';
            we0 <= '1';
            di(7 downto 0)  <= data_inp(7 downto 0);
            di(31 downto 8) <= (others => 'X');
          when b"0010" =>
            we3 <= '0';
            we2 <= '0';
            we1 <= '1';
            we0 <= '0';
            di(31 downto 16) <= (others => 'X');
            di(15 downto 8)  <= data_inp(7 downto 0);
            di(7 downto 0)   <= (others => 'X');
          when b"0100" =>
            we3 <= '0';
            we2 <= '1';
            we1 <= '0';
            we0 <= '0';
            di(31 downto 24) <= (others => 'X');
            di(23 downto 16) <= data_inp(7 downto 0);
            di(15 downto 0)  <= (others => 'X');
          when b"1000" =>
            we3 <= '1';
            we2 <= '0';
            we1 <= '0';
            we0 <= '0';
            di(31 downto 24) <= data_inp(7 downto 0);
            di(23 downto 0)  <= (others => 'X');
          when others =>
            we3 <= '0';
            we2 <= '0';
            we1 <= '0';
            we0 <= '0';
            di  <= (others => 'X');

        end case;
        assert TRUE report "ramWR["& natural'image(r_addr) &"] "
          & SLV32HEX(data_inp) &" bySel=" & SLV2STR(byte_sel); -- DEBUG

        data_out <= (others => 'X');
        
      else                              -- READ from MEM, wr /= 0

        we3 <= '0';
        we2 <= '0';
        we1 <= '0';
        we0 <= '0';
        di  <= (others => 'X');

        assert (r_addr >= 0) and (r_addr < (DATA_MEM_SZ/4))
          report "ramRD index out of bounds: " & natural'image(r_addr)
          severity failure;

        -- byte/half selection done at CPU
        data_out(31 downto 24) <= do(31 downto 24);
        data_out(23 downto 16) <= do(23 downto 16);
        data_out(15 downto  8) <= do(15 downto  8);
        data_out(7  downto  0) <= do(7  downto  0);

        assert TRUE report "ramRD["& natural'image(r_addr) &"] "
          & SLV32HEX(do) &" bySel="& SLV2STR(byte_sel);  -- DEBUG

      end if;                           -- wr

    else      -- sel /= 0

      we3 <= '0';
      we2 <= '0';
      we1 <= '0';
      we0 <= '0';
      di       <= (others => 'X');
      data_out <= (others => 'X');

    end if;
        
  end process accessRAM;

end architecture rtl;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++






-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- syncronous RAM; initialization Data loaded at CPU reset, byte-indexed
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture simulation of RAM is

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
  
  constant WAIT_COUNT : max_wait_states := NUM_MAX_W_STS - RAM_WAIT_STATES;
  signal wait_counter, ram_current : integer;
  
  subtype t_address is unsigned((DATA_ADDRS_BITS - 1) downto 0);
  
  subtype word is std_logic_vector(7 downto 0);
  type storage_array is
    array (natural range 0 to (DATA_MEM_SZ - 1)) of word;
  signal storage : storage_array;

  signal enable, waiting, do_wait : std_logic;
  
begin  -- simulation

  U_BUS_WAIT: wait_states generic map (RAM_WAIT_STATES)
     port map (rst, clk, sel, waiting);

  rdy <= not(waiting);

  enable <= not(sel); --  and not(waiting);

  
  accessRAM: process(strobe,enable, wr,rst, addr,byte_sel, data_inp,dump_ram)
    variable u_addr : t_address;
    variable index, latched : natural;

    type binary_file is file of integer;
    file load_file: binary_file open read_mode is LOAD_FILE_NAME;
    variable datum: integer;
    variable s_datum: signed(31 downto 0);

    file dump_file: binary_file open write_mode is DUMP_FILE_NAME;
    
    variable d : reg32 := (others => 'X');
    variable val, i : integer;

  begin

    if rst = '0' then             -- reset, read-in binary initialized data

      index := 0;                 -- byte indexed

      for i in 0 to (DATA_MEM_SZ - 1)  loop

        if not endfile(load_file) then

          read(load_file, datum);
          s_datum := to_signed(datum, 32);
          assert TRUE report "ramINIT["& natural'image(index*4)&"]= " &
            SLV32HEX(std_logic_vector(s_datum)); -- DEBUG
          storage(index+3) <= std_logic_vector(s_datum(31 downto 24));
          storage(index+2) <= std_logic_vector(s_datum(23 downto 16));
          storage(index+1) <= std_logic_vector(s_datum(15 downto  8));
          storage(index+0) <= std_logic_vector(s_datum(7  downto  0));
          index := index + 4;
        end if;
      end loop;

      data_out <= (others=>'X');
      
    else  -- (rst = '1'), normal operation

      u_addr := unsigned(addr( (DATA_ADDRS_BITS-1) downto 0 ) );
      index  := to_integer(u_addr);

      if sel  = '0' and wr = '0' and rising_edge(strobe) then
        
        assert (index >= 0) and (index < DATA_MEM_SZ)
          report "ramWR index out of bounds: " & natural'image(index)
          severity failure;

        case byte_sel is
          when b"1111"  =>                              -- SW
            storage(index+3) <= data_inp(31 downto 24);
            storage(index+2) <= data_inp(23 downto 16);
            storage(index+1) <= data_inp(15 downto  8);
            storage(index+0) <= data_inp(7  downto  0);
          when b"1100" | b"0011" =>                     -- SH
            storage(index+1) <= data_inp(15 downto 8);
            storage(index+0) <= data_inp(7  downto 0);
          when b"0001" | b"0010" | b"0100" | b"1000" => -- SB
            storage(index+0) <= data_inp(7 downto 0);
          when others => null;
        end case;
        assert TRUE report "ramWR["& natural'image(index) &"] "
          & SLV32HEX(data_inp) &" bySel=" & SLV2STR(byte_sel); -- DEBUG
      end if; -- is write?

      if sel = '0' and wr = '1' then

        assert (index >= 0) and (index < DATA_MEM_SZ)
          report "ramRD index out of bounds: " & natural'image(index)
          severity failure;

        case byte_sel is
          when b"1111"  =>                              -- LW
            d(31 downto 24) := storage(index+3);
            d(23 downto 16) := storage(index+2);
            d(15 downto  8) := storage(index+1);
            d(7  downto  0) := storage(index+0);
          when b"1100" =>                               -- LH top-half
            d(31 downto 24) := storage(index+1);
            d(23 downto 16) := storage(index+0);
            d(15 downto  0) := (others => 'X');
          when b"0011" =>                               -- LH bottom-half
            d(31 downto 16) := (others => 'X');
            d(15 downto  8) := storage(index+1);
            d(7  downto  0) := storage(index+0);
          when b"0001" =>                               -- LB top byte
            d(31 downto  8) := (others => 'X');
            d(7  downto  0) := storage(index+0);
          when b"0010" =>                               -- LB mid-top byte
            d(31 downto 16) := (others => 'X');
            d(15 downto  8) := storage(index+0);
            d(7  downto  0) := (others => 'X');
          when b"0100" =>                               -- LB mid-bot byte
            d(31 downto 24) := (others => 'X');
            d(23 downto 16) := storage(index+0);
            d(15 downto  0) := (others => 'X');
          when b"1000" =>                               -- LB bottom byte
            d(31 downto 24) := storage(index+0);
            d(23 downto  0) := (others => 'X');
          when others => d  := (others => 'X');
        end case;
        assert TRUE report "ramRD["& natural'image(index) &"] "
          & SLV32HEX(d) &" bySel="& SLV2STR(byte_sel);  -- DEBUG

      elsif rising_edge(dump_ram) then
        
        i := 0;
        while i < DATA_MEM_SZ-4 loop
          d(31 downto 24) := storage(i+3);
          d(23 downto 16) := storage(i+2);
          d(15 downto  8) := storage(i+1);
          d(7  downto  0) := storage(i+0);
          write( dump_file, to_integer(signed(d)) );
          i := i+4;
        end loop;  -- i

      else
        d := (others=>'X');
      end if; -- is read?

      data_out <= d;  

    end if; -- is reset?
    
  end process accessRAM; -- ---------------------------------------------


end architecture simulation;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

