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


-- disk(0): ctrl(31)=oper[1rd, 0wr], (30)=doInterrupt, (29..12)=0
--          (11..0)=numBytes [word aligned]
-- disk(1): stat(31)=oper[1rd, 0wr], (30)=irqPending, (29)=busy
--          (28..12)=0, (11..0)=currentDMAaddress
-- disk(2): srd [rd=disk file, wr=memory address]
-- disk(3): dst [rd=memory address, wr=disk file]


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- simulates a disk controller with DMA transfers, word only transfers
--   transfers AT MOST 4Kbytes or 1024 memory cycles
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;
-- use work.p_memory.all;

entity DISK is
  port (rst      : in    std_logic;
        clk      : in    std_logic;
        sel      : in    std_logic;     -- active in '0'
        rdy      : out   std_logic;     -- active in '0'
        wr       : in    std_logic;     -- active in '0'
        busFree  : in    std_logic;     -- '1' = bus will be free next cycle
        busReq   : out   std_logic;     -- '1' = bus will be used next cycle
        addr     : in    reg2;
        data_inp : in    reg32;
        data_out : out   reg32;
        dma_addr : out   reg32;
        dma_dinp : in    reg32;
        dma_dout : out   reg32;
        dma_wr   : out   std_logic;     -- active in '0'
        dma_aval : out   std_logic;     -- active in '0'
        dma_type : out   reg4);
  constant NUM_BITS : integer := 32;
  constant START_VALUE : reg32 := (others => '0');

end entity DISK;

architecture functional of DISK is

  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component registerN;

  component countNup is
    generic (NUM_BITS: integer := 16);
    port(clk, rst, ld, en: in  std_logic;
         D:                in  std_logic_vector((NUM_BITS - 1) downto 0);
         Q:                out std_logic_vector((NUM_BITS - 1) downto 0);
         co:               out std_logic);
  end component countNup;

  constant C_OPER : integer := 31;      -- operation 1=rd, 0=wr
  constant C_INT  : integer := 30;      -- interrupt when finished=1
  constant S_BUSY : integer := 29;      -- controller busy=1

  type int_file is file of integer;
  file my_file : int_file;
  
  signal ld_ctrl, s_ctrl, s_stat, ld_src, s_src, ld_dst, s_dst : std_logic;
  signal busy, take_bus, ld_curr, rst_curr, en_curr : std_logic;
  signal ctrl, src, dst, stat : reg32;
  signal current : reg12;

begin  -- functional

  rdy <= '0';                           -- simulation only, never waits

  s_ctrl <= '1' when sel = '0' and addr = b"00" else '0'; -- R+W
  s_stat <= '1' when sel = '0' and addr = b"01" else '0'; -- R+W
  s_src  <= '1' when sel = '0' and addr = b"10" else '0'; -- W
  s_dst  <= '1' when sel = '0' and addr = b"11" else '0'; -- W

  ld_ctrl <= '0' when s_ctrl = '1' and wr = '0' else '1';  
  U_CTRL: registerN  generic map (NUM_BITS, START_VALUE)
    port map (clk, rst, ld_ctrl, data_inp, ctrl);

  ld_src <= '0' when s_src = '1' and wr = '0' else '1';  
  U_SRC:  registerN  generic map (NUM_BITS, START_VALUE)
    port map (clk, rst, ld_src, data_inp, src);

  ld_dst <= '0' when s_dst = '1' and wr = '0' else '1';  
  U_DST:  registerN  generic map (NUM_BITS, START_VALUE)
    port map (clk, rst, ld_dst, data_inp, dst);

  stat <= ctrl(C_OPER) & ctrl(C_INT) & busy & '1' & x"0000" & current;
  
  with addr select
    data_out <= ctrl  when "00",
                stat  when "01",
                src   when "10",
                dst   when others;

  busReq   <= take_bus;
  
  dma_type <= b"1111";                  -- always transfers words
  dma_wr   <= ctrl(C_OPER);
  dma_aVal <= take_bus;

  dma_addr <= x"00000" & current;       -- at most 4K transfers
  
  dma_dout <= datum    when ctrl(C_OPER) = '0' else (others => 'X');

  dma_dinp <= data_inp when ctrl(C_OPER) = '1' else (others => 'X');


 
  U_FILE_CTRL: process(s_ctrl)
  begin

    if s_ctrl = '1' then
      if ctrl(C_oper) = '1' then          -- read file
        if src(0) = '0' then
          file_open(my_file, "DMA_0.src", read_mode);
        else 
          file_open(my_file, "DMA_1.src", read_mode);
        end if;
      else                                --  write file
        if dst(0) = '0' then
          file_open(my_file, "DMA_0.dst", write_mode);
        else 
          file_open(my_file, "DMA_1.dst", write_mode);
        end if;
      end if;
    end if;   
    
  end process U_FILE_CTRL; -------------------------------------------

  rst_curr <= not(ld_curr);
  U_CURRENT: countNup generic map (12)
    port map (clk, rst_curr, '0', en_curr, ctrl(11 downto 0), current);
  
  
  

  
  
  
end architecture functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture FPGA of DISK is
begin
  rdy      <= '0';
  busReq   <= '0';
  data_out <= (others => 'X');
  dma_addr <= (others => 'X');
  dma_dout <= (others => 'X');
  dma_wr   <= '1';
  dma_aval <= '1';
  dma_type <= b"1111";
end architecture FPGA;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++











--x 
--x       index := 0;                 -- byte indexed
--x 
--x       for i in 0 to (DATA_MEM_SZ - 1)  loop
--x 
--x         if not endfile(load_file) then
--x 
--x           read(load_file, datum);
--x           s_datum := to_signed(datum, 32);
--x           assert TRUE report "ramINIT["& natural'image(index*4)&"]= " &
--x             SLV32HEX(std_logic_vector(s_datum)); -- DEBUG
--x           storage(index+3) <= std_logic_vector(s_datum(31 downto 24));
--x           storage(index+2) <= std_logic_vector(s_datum(23 downto 16));
--x           storage(index+1) <= std_logic_vector(s_datum(15 downto  8));
--x           storage(index+0) <= std_logic_vector(s_datum(7  downto  0));
--x           index := index + 4;
--x         end if;
--x       end loop;
--x 
--x 
--x 
--x 
--x 
--x -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--x -- syncronous RAM; initialization Data loaded at CPU reset, byte-indexed
--x -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--x architecture simulation of RAM is
--x 
--x   
--x 
--x   signal enable, waiting, do_wait : std_logic;
--x   
--x begin  -- simulation
--x 
--x   
--x   accessRAM: process(strobe,enable, wr,rst, addr,byte_sel, data_inp,dump_ram)
--x     variable u_addr : t_address;
--x     variable index, latched : natural;
--x 
--x     type binary_file is file of integer;
--x     file load_file: binary_file open read_mode is LOAD_FILE_NAME;
--x     variable datum: integer;
--x     variable s_datum: signed(31 downto 0);
--x 
--x     file dump_file: binary_file open write_mode is DUMP_FILE_NAME;
--x     
--x     variable d : reg32 := (others => 'X');
--x     variable val, i : integer;
--x 
--x   begin
--x 
--x     if rst = '0' then             -- reset, read-in binary initialized data
--x       data_out <= (others=>'X');
--x       
--x     else  -- (rst = '1'), normal operation
--x 
--x       u_addr := unsigned(addr( (DATA_ADDRS_BITS-1) downto 0 ) );
--x       index  := to_integer(u_addr);
--x 
--x       if sel  = '0' and wr = '0' and rising_edge(strobe) then
--x         
--x         assert (index >= 0) and (index < DATA_MEM_SZ)
--x           report "ramWR index out of bounds: " & natural'image(index)
--x           severity failure;
--x 
--x         case byte_sel is
--x           when b"1111"  =>                              -- SW
--x             storage(index+3) <= data_inp(31 downto 24);
--x             storage(index+2) <= data_inp(23 downto 16);
--x             storage(index+1) <= data_inp(15 downto  8);
--x             storage(index+0) <= data_inp(7  downto  0);
--x           when b"1100" | b"0011" =>                     -- SH
--x             storage(index+1) <= data_inp(15 downto 8);
--x             storage(index+0) <= data_inp(7  downto 0);
--x           when b"0001" | b"0010" | b"0100" | b"1000" => -- SB
--x             storage(index+0) <= data_inp(7 downto 0);
--x           when others => null;
--x         end case;
--x         assert TRUE report "ramWR["& natural'image(index) &"] "
--x           & SLV32HEX(data_inp) &" bySel=" & SLV2STR(byte_sel); -- DEBUG
--x       end if; -- is write?
--x 
--x       if sel = '0' and wr = '1' then
--x 
--x         assert (index >= 0) and (index < DATA_MEM_SZ)
--x           report "ramRD index out of bounds: " & natural'image(index)
--x           severity failure;
--x 
--x         case byte_sel is
--x           when b"1111"  =>                              -- LW
--x             d(31 downto 24) := storage(index+3);
--x             d(23 downto 16) := storage(index+2);
--x             d(15 downto  8) := storage(index+1);
--x             d(7  downto  0) := storage(index+0);
--x           when b"1100" =>                               -- LH top-half
--x             d(31 downto 24) := storage(index+1);
--x             d(23 downto 16) := storage(index+0);
--x             d(15 downto  0) := (others => 'X');
--x           when b"0011" =>                               -- LH bottom-half
--x             d(31 downto 16) := (others => 'X');
--x             d(15 downto  8) := storage(index+1);
--x             d(7  downto  0) := storage(index+0);
--x           when b"0001" =>                               -- LB top byte
--x             d(31 downto  8) := (others => 'X');
--x             d(7  downto  0) := storage(index+0);
--x           when b"0010" =>                               -- LB mid-top byte
--x             d(31 downto 16) := (others => 'X');
--x             d(15 downto  8) := storage(index+0);
--x             d(7  downto  0) := (others => 'X');
--x           when b"0100" =>                               -- LB mid-bot byte
--x             d(31 downto 24) := (others => 'X');
--x             d(23 downto 16) := storage(index+0);
--x             d(15 downto  0) := (others => 'X');
--x           when b"1000" =>                               -- LB bottom byte
--x             d(31 downto 24) := storage(index+0);
--x             d(23 downto  0) := (others => 'X');
--x           when others => d  := (others => 'X');
--x         end case;
--x         assert TRUE report "ramRD["& natural'image(index) &"] "
--x           & SLV32HEX(d) &" bySel="& SLV2STR(byte_sel);  -- DEBUG
--x 
--x       elsif rising_edge(dump_ram) then
--x         
--x         i := 0;
--x         while i < DATA_MEM_SZ-4 loop
--x           d(31 downto 24) := storage(i+3);
--x           d(23 downto 16) := storage(i+2);
--x           d(15 downto  8) := storage(i+1);
--x           d(7  downto  0) := storage(i+0);
--x           write( dump_file, to_integer(signed(d)) );
--x           i := i+4;
--x         end loop;  -- i
--x 
--x       else
--x         d := (others=>'X');
--x       end if; -- is read?
--x 
--x       data_out <= d;  
--x 
--x     end if; -- is reset?
--x     
--x   end process accessRAM; -- ---------------------------------------------
--x 
--x 
--x end architecture simulation;
--x -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--x


