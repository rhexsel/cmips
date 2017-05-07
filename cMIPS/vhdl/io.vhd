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



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: from_stdin
--             read a signle character from stdout
--             returns LF ('\n'=0x0a) if there are no charachters on input
--               on the first ever read, returna LF on the empty line read
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.p_wires.all;

entity from_stdin is
  port (rst     : in  std_logic;
        clk     : in  std_logic;
        sel     : in  std_logic;
        wr      : in  std_logic;
        data    : out std_logic_vector);
end from_stdin;

architecture behavioral of from_stdin is

begin

  U_READ_IN: process(clk,sel)
    variable L : line;
    variable this : character;
    variable good : boolean := FALSE;
  begin

    if falling_edge(clk) and sel = '0' then
      read(L, this, good);

      if not(good) then
        readline(input, L);
        this := LF;
      end if;

      data <= x"000000" & std_logic_vector(to_signed(character'pos(this),8));

      assert TRUE report "STD_IOrd= " & this;

    end if;
  end process U_READ_IN;
  
end behavioral;
-- ++ from_stdin +++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: print_data
--             print an integer to stdout, 32bit hexadecimal
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.p_wires.all;

entity print_data is
  port (rst     : in  std_logic;
        clk     : in  std_logic;
        sel     : in  std_logic;
        wr      : in  std_logic;
        data    : in  reg32);
end print_data;

architecture behavioral of print_data is

  file output : text open write_mode is "STD_OUTPUT";

begin

  U_WRITE_OUT: process(sel,clk)
    variable msg : line;
  begin
    if falling_edge(clk) and sel = '0' then
      write ( msg, string'(SLV32HEX(data)) );
      writeline( output, msg );
    end if;
  end process U_WRITE_OUT;

end behavioral;
-- ++ print_data +++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: to_stdout
--             print a signle character to stdout
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.p_wires.all;

entity to_stdout is
  port (rst     : in  std_logic;
        clk     : in  std_logic;
        sel     : in  std_logic;
        wr      : in  std_logic;
        data    : in  std_logic_vector);
end to_stdout;

architecture behavioral of to_stdout is
  
  file output : text open write_mode is "STD_OUTPUT";

begin

  U_WRITE_OUT: process(clk,sel)
    variable msg : line;
  begin
    if falling_edge(clk) and sel = '0' then
      if (data(7 downto 0) = x"00") or (data(7 downto 0) = x"0a") then
        writeline( output, msg );
      else
        write(msg, character'val(to_integer( unsigned(data(7 downto 0)))));
      end if;
    end if;
  end process U_WRITE_OUT;
  
end behavioral;
-- ++ to_stdout +++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: write_data_to_file
--             write one 32bit integer to file "output.data"
--   if( addr(3 downto 0) ) = "0000" then write to file
--   if( addr(3 downto 0) ) = "0100" then close file
--   if( addr(3 downto 0) ) = "0111" then assert dump_ram
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.p_wires.all;

entity write_data_file is
  generic (OUTPUT_FILE_NAME : string := "output.data");
  port (rst      : in  std_logic;
        clk      : in  std_logic;
        sel      : in  std_logic;
        wr       : in  std_logic;
        addr     : in  reg32;
        data     : in  reg32;
        byte_sel : in  reg4;
        dump_ram : out std_logic);
end write_data_file;

architecture behavioral of write_data_file is

  type uint_file_type is file of integer;
  file output_file: uint_file_type open write_mode is OUTPUT_FILE_NAME;

begin

  U_write_uint: process (clk,sel)
  begin

    dump_ram <= '0';

    if  falling_edge(clk) and sel = '0' then
      if addr(3 downto 0) = b"0000" then               -- data write
        if wr = '0' then
          write( output_file, to_integer(signed(data)) );
          assert TRUE report "IOwr[" & SLV32HEX(addr) &"]:" & SLV32HEX(data);
        end if;
      elsif addr(3 downto 0) = b"0100" then            -- close output file
        file_close(output_file);
      elsif addr(3 downto 0) = b"0111" then            -- dump RAM
        dump_ram <= '1';
      end if;
    end if;
    
  end process U_write_uint;

end behavioral;                         -- write_file_data
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: read_data_from_file
--             read one 32bit integer from file "input.data"
--  if not EOF then write data to file
--  else status <= 1
--  on a read, return last status (EOF=1 or otherwise=0)
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.p_wires.all;

entity read_data_file is
  generic (INPUT_FILE_NAME : string := "input.data");
  port (rst      : in  std_logic;
        clk      : in  std_logic;
        sel      : in  std_logic;
        wr       : in  std_logic;
        addr     : in  reg32;
        data     : out reg32;
        byte_sel : in  reg4);
end read_data_file;

architecture behavioral of read_data_file is

  type uint_file_type is file of integer;
  file input_file: uint_file_type open read_mode is INPUT_FILE_NAME;

  signal status : reg32 := (others => '0');

begin

  U_read_uint: process(clk,sel)
    variable datum : integer := 0;
    variable value : reg32;                 -- for debugging only
  begin

    data <= (others => 'X');

    if falling_edge(clk) and sel = '0' then
      if addr(3 downto 0) = b"0000" then               -- data read
        if wr = '1' then
          if not endfile(input_file) then
            read( input_file, datum );
            data <= std_logic_vector(to_signed(datum, 32));
            status <= x"00000000";        -- NOT_EndOfFile
            value := std_logic_vector(to_signed(datum, 32));   -- DEBUG
            assert TRUE report "IOrd[" & SLV32HEX(addr) &"]:"& SLV32HEX(value);
          else
            status <= x"00000001";        -- EndOfFile
          end if;
        else
          data <= (others => 'X');
        end if;
      else                                -- status read
        if wr = '1' then
          data <= status;
        else
          data <= (others => 'X');
        end if;
      end if;
    end if;
    
  end process U_read_uint;

end behavioral;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: generate interrupt after N clock cycles
--   Generates an interrupt after N cycles, N <= 2**30
--   Counting stops on reaching limit stored to counter.
--   data(31) = 1 enables interrupt on reaching limit;
--   data(31) = 0 disables interrupts
--   data(30) = 1 enables counting
--   data(30) = 0 stops counter and delays interrupt (forever?)
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity do_interrupt is
  port (rst      : in    std_logic;
        clk      : in    std_logic;     -- clock pulses counted
        sel      : in    std_logic;
        wr       : in    std_logic;
        data_inp : in    std_logic_vector;
        data_out : out   std_logic_vector;
        irq      : out   std_logic);
  constant NUM_BITS : integer := 30;
  subtype c_width is std_logic_vector(NUM_BITS - 1 downto 0);
  constant START_COUNT : c_width := (others => '0');
end do_interrupt;

architecture behavioral of do_interrupt is

  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component registerN;

  component countNup is
    generic (NUM_BITS: integer);
    port(clk, rst, ld, en: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector;
         co:           out std_logic);
  end component countNup;

  component FFDsimple is
    port(clk, rst : in std_logic;
         D : in  std_logic;
         Q : out std_logic);
  end component FFDsimple;

  signal Dlimit, Qlimit, Q: c_width;
  signal ld_cnt, ld_reg, en, cnt_en, int_en, equals : std_logic;
  signal i_ena, c_ena : std_logic;
begin

  ld_reg <= wr when sel = '0' else '1';
  ld_cnt <= not ld_reg;
  
  Dlimit <= data_inp(NUM_BITS-1 downto 0);

  U_LIMIT: registerN  generic map (NUM_BITS, START_COUNT)
    port map (clk, rst, ld_reg, Dlimit, Qlimit);

  en <= cnt_en and (not equals);

  U_COUNTER: countNup generic map (NUM_BITS)
    port map (clk, rst, ld_cnt, en, START_COUNT, Q, open);

  c_ena <= data_inp(30) when (sel='0' and wr='0') else cnt_en;
  U_COUNT_EN:  FFDsimple port map (clk, rst, c_ena, cnt_en);

  i_ena <= data_inp(31) when (sel='0' and wr='0') else int_en;
  U_INTERR_EN: FFDsimple port map (clk, rst, i_ena, int_en);

  equals <= '1' when (Q = Qlimit(NUM_BITS-1 downto 0) ) else '0';
  
  irq <= '1' when (equals = '1' and int_en = '1') else '0';

  data_out <= int_en & cnt_en & Q;

end behavioral;
-- ++ do_interrupt +++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: simple UART bus interface (a wrapper to the real UART)
--   8 data bits, no parity, 1 stop bit (8N1), catches: framing, overrun
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity simple_uart is
  port (rst     : in    std_logic;
        clk     : in    std_logic;      -- processor clock
        sel     : in    std_logic;
        wr      : in    std_logic;
        addr    : in    std_logic_vector(1 downto 0);
        data_inp : in   std_logic_vector;
        data_out : out  std_logic_vector;
        txdat   : out   std_logic;      -- serial transmission (output)
        rxdat   : in    std_logic;      -- serial reception (input)
        rts     : out   std_logic;
        cts     : in    std_logic;
        irq     : out   std_logic;      -- interrupt request
        bit_rt  : out   std_logic_vector); -- communication speed; for TB only
end simple_uart;

architecture behavioral of simple_uart is

  component uart_int is
    port(clk, rst: in std_logic;
         s_ctrl, s_stat, s_tx, s_rx : in std_logic; -- select registers
         s_intwr, s_intrd : in std_logic; -- select interrupt register
         d_inp:  in  std_logic_vector;  -- 32 bit input
         d_out:  out std_logic_vector;  -- 32 bit output
         txdat:  out std_logic;         -- serial transmission (output)
         rxdat:  in  std_logic;         -- serial reception (input)
         rts:    out std_logic;
         cts:    in  std_logic;
         interr: out std_logic;         -- interrupt request
         bit_rt: out std_logic_vector); -- communication speed - for TB only
  end component uart_int;
  
  signal s_ctrl, s_stat, s_tx, s_rx, s_intwr, s_intrd : std_logic;
  signal d_inp, d_out : reg32;

begin

  U_UART: uart_int port map (clk, rst, s_ctrl,s_stat, s_tx,s_rx,
                             s_intwr, s_intrd,
                             d_inp,d_out, txdat,rxdat, rts,cts, irq, bit_rt);
  
  -- a3a2 wr  register (aligned to word addresses)
  --  00  0  control, R+W             IO_UART_ADDR +0
  --  01  1  status,  R-O             IO_UART_ADDR +4
  --  10  0  interrupt conmtrol W-O   IO_UART_ADDR +8
  --  11  0  transmission W           IO_UART_ADDR +12
  --  11  1  reception    R           IO_UART_ADDR +12
  
  s_ctrl  <= '1' when sel = '0' and addr = b"00" else '0'; -- R+W
  s_stat  <= '1' when sel = '0' and addr = b"01" else '0'; -- R+W
  s_intwr <= '1' when sel = '0' and addr = b"10" and wr = '0' else '0'; -- W
  s_intrd <= '1' when sel = '0' and addr = b"10" and wr = '1' else '0'; -- R
  s_tx    <= '1' when sel = '0' and addr = b"11" and wr = '0' else '0'; -- W-O
  s_rx    <= '1' when sel = '0' and addr = b"11" and wr = '1' else '0'; -- R-O
  
  data_out <= d_out;
  
  d_inp <= data_inp;
  
end behavioral;
-- ++ simple uart +++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: system statistics: gather statistics in one peripheral
-- processor reads performance counters, on word boundaries, adressed as
-- cnt_dc_ref    when "00000", 0
-- cnt_dc_rd_hit when "00100", 4
-- cnt_dc_wr_hit when "01000", 8
-- cnt_dc_flush  when "01100", 12
-- cnt_ic_ref    when "10000", 16
-- cnt_ic_hit    when "10100", 20
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity sys_stats is
  port (rst     : in    std_logic;
        clk     : in    std_logic;
        sel     : in    std_logic;
        wr      : in    std_logic;
        addr    : in    reg32;
        data    : out   reg32;
        cnt_dc_ref    : in  integer;
        cnt_dc_rd_hit : in  integer;
        cnt_dc_wr_hit : in  integer;
        cnt_dc_flush  : in  integer;
        cnt_ic_ref : in  integer;
        cnt_ic_hit : in  integer);
end sys_stats;

architecture behavioral of sys_stats is
begin

  U_SYNC_OUTPUT: process(clk,sel)
    variable i_c : integer := 0;
  begin
    data <= (others => '0');

    if falling_edge(clk) and sel = '0' then
      case addr(4 downto 2) is
        when "000" => i_c := cnt_dc_ref;
        when "001" => i_c := cnt_dc_rd_hit;
        when "010" => i_c := cnt_dc_wr_hit;
        when "011" => i_c := cnt_dc_flush;
        when "100" => i_c := cnt_ic_ref;
        when "101" => i_c := cnt_ic_hit;
        when others => i_c := 0;
      end case;
    end if;
    
    data <= std_logic_vector(to_signed(i_c,32));

  end process U_SYNC_OUTPUT;

end behavioral;
-- ++ system statistics ++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: to_7seg
--  input format:
--  b14 b13 b12  b09   b08   b07..b04 b03..b02
--  red gre blu  MSdot msdot  MSdigit msdigit
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.p_wires.all;

entity to_7seg is
  port (rst      : in  std_logic;
        clk      : in  std_logic;
        sel      : in  std_logic;
        wr       : in  std_logic;
        data     : in  std_logic_vector;
        display0 : out reg8;
        display1 : out reg8;
        red      : out std_logic;
        green    : out std_logic;
        blue     : out std_logic);
  -- 2 decimal points, 2 hex digits, 3 leds
  constant NUM_BITS : integer := 15;
  subtype c_width is std_logic_vector(NUM_BITS - 1 downto 0);
  constant INIT_VALUE : c_width := (others => '0');
end to_7seg;

architecture behavioral of to_7seg is

  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component registerN;

  component display_7seg is
    port(data_i      : in  std_logic_vector(3 downto 0);
         decimal_i   : in  std_logic;
         disp_7seg_o : out std_logic_vector(7 downto 0));
  end component display_7seg;
  
  signal value  : std_logic_vector(NUM_BITS-1 downto 0);
  signal middle : std_logic;
  
begin
  
  U_HOLD_data: registerN generic map (NUM_BITS, INIT_VALUE)
    port map (clk, rst, sel, data(NUM_BITS-1 downto 0), value);

  red   <= value(14);
  green <= value(13);
  blue  <= value(12);

  U_DSP1: display_7seg port map (value(7 downto 4), value(9), display1);

  U_DSP0: display_7seg port map (value(3 downto 0), value(8), display0);

  U_sim: process(sel,rst,clk)
  begin
    middle <= not(sel) and not(clk); -- to remove spurious reports
    if rst = '1' then
      assert not(rising_edge(middle))
        report "dsp7seg: "&  SLV32HEX(data) severity NOTE;
    end if;
  end process;

end behavioral;
-- ++ to_7seg +++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: read_keys
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity read_keys is
  generic (DEB_CYCLES: natural);        -- debouncing interval
  port (rst      : in  std_logic;
        clk      : in  std_logic;
        sel      : in  std_logic;
        data     : out reg32;
        kbd      : in  std_logic_vector (11 downto 0);
        sw       : in  std_logic_vector (3 downto 0));
  constant DEB_BITS : integer := 16;    -- debounce counter width
  constant CNT_MAX : integer := (2**DEB_BITS - 1);
  constant x_DEB_CYCLES : std_logic_vector(DEB_BITS-1 downto 0)
    := std_logic_vector(to_signed((CNT_MAX - DEB_CYCLES),DEB_BITS));
  constant NUM_BITS : integer := 4;     -- four bits to hold key number
  subtype c_width is std_logic_vector(NUM_BITS - 1 downto 0);
  constant NO_KEY : c_width := (others => '0');
end read_keys;

architecture behavioral of read_keys is
  
  component FFD is
    port(clk, rst, set : in std_logic;
         D : in  std_logic; Q : out std_logic);
  end component FFD;

  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector(NUM_BITS-1 downto 0);
         Q:            out std_logic_vector(NUM_BITS-1 downto 0));
  end component registerN;
  
  component countNup is
  generic (NUM_BITS: integer := 16);
  port(clk, rst, ld, en: in  std_logic;
       D:                in  std_logic_vector((NUM_BITS - 1) downto 0);
       Q:                out std_logic_vector((NUM_BITS - 1) downto 0);
       co:               out std_logic);
  end component countNup;

  type kbd_state is (st_idle, st_start, st_wait, st_load, st_release);
  signal kbd_current_st, kbd_next_st : kbd_state;
  attribute SYN_ENCODING of kbd_state : type is "safe";
  -- signal kbd_dbg_st : integer;    -- debugging only
  
  signal cnt_ld, cnt_en, new_ld : std_logic;
  signal press, debounced, rdy_clr, ready : std_logic;
  signal keys_data, cpu_data : reg4;
  signal d : reg2;
  -- signal count : std_logic_vector(DEB_BITS-1 downto 0);  -- debugging only
begin
  
  data(31) <= ready;
  data(30 downto 8) <= (others => '0');
  
  data(7) <= sw(3);
  data(6) <= sw(2);
  data(5) <= sw(1);
  data(4) <= sw(0);
  data(3 downto 0) <= cpu_data(3 downto 0);
  
  U_DEBOUNCER: countNup generic map (DEB_BITS)
    port map (clk=>clk, rst=>rst, ld=>cnt_ld, en=>cnt_en,
              D=>x_DEB_CYCLES, Q=>open, co=>debounced); 
  
  U_NEW_DATA: registerN  generic map (4, NO_KEY)
    port map (clk, rst, new_ld, keys_data, cpu_data);

  d <= new_ld & sel;                    -- new_ld, sel active in '0'
  with d select
    rdy_clr <= '1' when "00",
               '1' when "01",
               '0' when "10",
               ready when others;

  U_READY: FFD port map (clk, rst, '1', rdy_clr, ready);
  
  press <= BOOL2SL(keys_data /= b"0000");
  
  -- translate key position to key code
  -- code for key 0 cannot be zero; value-holding register is reset to "0000"
  with kbd select
    keys_data <= "0001" when "000000000001",   -- 1
                 "0010" when "000000000010",   -- 2
                 "0011" when "000000000100",   -- 3
                 "0100" when "000000001000",   -- 4
                 "0101" when "000000010000",   -- 5
                 "0110" when "000000100000",   -- 6
                 "0111" when "000001000000",   -- 7
                 "1000" when "000010000000",   -- 8
                 "1001" when "000100000000",   -- 9
                 "1010" when "001000000000",   -- *
                 "1111" when "010000000000",   -- 0, cannot be "0000"
                 "1011" when "100000000000",   -- #
                 "0000" when others; -- no key depressed


  -- ---------------------------------------------------------------------
  U_KBD_st_reg: process(rst,clk)
  begin
    if rst = '0' then
      kbd_current_st <= st_idle;
    elsif rising_edge(clk) then
      kbd_current_st <= kbd_next_st;
    end if;
  end process U_KBD_st_reg; ----------------------------------------------

  -- kbd_dbg_st <= integer(kbd_state'pos(kbd_current_st)); -- for debugging

  U_KBD_st_transitions: process(kbd_current_st, press, debounced) --------
  begin
    case kbd_current_st is
      when st_idle =>                   -- 0
        if press = '1' then
          kbd_next_st <= st_start;
        else
          kbd_next_st <= st_idle;
        end if;
      when st_start =>                  -- 1
        kbd_next_st <= st_wait;
      when st_wait =>                   -- 2
        if debounced = '1' then
          kbd_next_st <= st_load;
        else
          kbd_next_st <= st_wait;
        end if;
      when st_load =>                   -- 3
        kbd_next_st <= st_release;
      when st_release =>                -- 4
        if press = '1' then
          kbd_next_st <= st_release;
        else
          kbd_next_st <= st_idle;
        end if;
    end case;
  end process U_KBD_st_transitions;   ------------------------------------

  U_KBD_outputs: process(kbd_current_st)  ------------------------------
  begin
    case kbd_current_st is
      when st_idle  |st_release =>      -- 0,4
        new_ld  <= '1';
        cnt_ld  <= '0';
        cnt_en  <= '0';
      when st_start =>                  -- 1
        new_ld  <= '1';
        cnt_ld  <= '1';
        cnt_en  <= '0';
      when st_wait =>                   -- 2
        new_ld  <= '1';
        cnt_ld  <= '0';
        cnt_en  <= '1';
      when st_load =>                   -- 3
        new_ld  <= '0';
        cnt_ld  <= '1';
        cnt_en  <= '0';
    end case;
  end process U_KBD_outputs;   -------------------------------------------

  
end behavioral;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: LCD display controller
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity LCD_display is
  port (rst      : in    std_logic;
        clk      : in    std_logic;
        sel      : in    std_logic;
        rdy      : out   std_logic;
        wr       : in    std_logic;
        addr     : in    std_logic; -- 0=constrol, 1=data
        data_inp : in    std_logic_vector(31 downto 0);
        data_out : out   std_logic_vector(31 downto 0);
        LCD_DATA : inout std_logic_vector(7 downto 0);  -- bidirectional bus
        LCD_RS   : out   std_logic; -- LCD register select 0=ctrl, 1=data
        LCD_RW   : out   std_logic; -- LCD read=1, 0=write
        LCD_EN   : out   std_logic; -- LCD enable=1
        LCD_BLON : out   std_logic);
  constant NUM_BITS : integer := 8;
  subtype c_width is std_logic_vector(NUM_BITS - 1 downto 0);
  constant INIT_VALUE : c_width := (others => '0');
end LCD_display;

architecture behavioral of LCD_display is

  component wait_states is
    generic (NUM_WAIT_STATES :integer);
    port(rst   : in  std_logic;
       clk     : in  std_logic;
       sel     : in  std_logic;         -- active in '0'
       waiting : out std_logic);        -- active in '1'
  end component wait_states;
  
  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component registerN;

  component FFD is
    port(clk, rst, set, D : in std_logic; Q : out std_logic);
  end component FFD;

  component FFDsimple is
    port(clk, rst, D : in std_logic; Q : out std_logic);
  end component FFDsimple;

  type lcd_state is (st_init, st_idle, st_n, st_n1, st_n2, st_n3,
                     st_n4, st_n5, st_n6, st_n7, st_n8, st_n9, st_na, st_nb);
  attribute SYN_ENCODING of lcd_state : type is "safe";
  signal lcd_current_st, lcd_next_st : lcd_state;
  signal lcd_current : integer;         -- debugging only

  signal waiting, wait1, wait2, n_sel: std_logic;
  signal sel_rs, RS, sel_rw, RW,lcd_enable,lcd_read : std_logic;
  signal inp_data, out_data : reg8;
  
begin

  n_sel <= not(sel);
  
  U_WAIT_ON_READS: component wait_states generic map (1)
    port map (rst, clk, sel, wait1);

  U_WAIT2: FFDsimple port map (clk, rst, wait1, wait2);

  rdy <= not(wait1 or wait2 or waiting);  -- wait for 260ns

  sel_rs <= addr when sel = '0' else RS;
  U_INPUT_RS: FFDsimple port map (clk, rst, sel_rs, RS);

  U_INPUT: registerN generic map (NUM_BITS, INIT_VALUE)
  port map (clk, rst, sel, data_inp(NUM_BITS-1 downto 0), inp_data);

  U_OUTPUT: registerN generic map (NUM_BITS, INIT_VALUE)
  port map (clk, rst, lcd_read, out_data, data_out(NUM_BITS-1 downto 0));
  data_out(31 downto NUM_BITS) <= (others => 'X');

  -- TESTING ONLY
  -- out_data <= b"00000000" when RW = '1' else (others => 'X');
  out_data <= LCD_DATA when RW = '1' else (others => 'Z');
  
  LCD_DATA <= inp_data when RW = '0' else (others => 'Z');

  LCD_RS   <= RS;         -- LCD register select 0=ctrl, 1=data

  sel_rw <= wr when sel = '0' else RW;
  U_INPUT_RW: FFD port map (clk, '1', rst, sel_rw, RW);

  LCD_RW   <= RW;         -- LCD read=1, 0=write

  LCD_EN   <= lcd_enable; -- LCD enable=1

  LCD_BLON <= '1';        -- LCD backlight
 
  -- state register----------------------------------------------------
  U_st_reg: process(rst,clk)
  begin
    if rst = '0' then
      lcd_current_st <= st_init;
    elsif rising_edge(clk) then
      lcd_current_st <= lcd_next_st;
    end if;
  end process U_st_reg;

  lcd_current <= lcd_state'pos(lcd_current_st);  -- debugging only

  U_st_transitions: process(lcd_current_st, RW, sel)
  begin
    case lcd_current_st is
      when st_init =>                   -- 0
        lcd_next_st <= st_idle;

      when st_idle =>                   -- 1
        if sel = '0' then
          lcd_next_st <= st_n;
        else
          lcd_next_st <= st_idle;
        end if;

      when st_n =>                      -- 2
        lcd_next_st <= st_n1;
      when st_n1 =>                     -- 3, setup for Enable is 20ns
        lcd_next_st <= st_n2;

      when st_n2 =>                     -- 4, keep Enable=1 for 200ns
        lcd_next_st <= st_n3;
      when st_n3 =>                     -- 5, data setup is 100ns
        lcd_next_st <= st_n4;
      when st_n4 =>                     -- 6
        lcd_next_st <= st_n5;
      when st_n5 =>                     -- 7
        lcd_next_st <= st_n6;
      when st_n6 =>                     -- 8
        lcd_next_st <= st_n7;
      when st_n7 =>                     -- 9
        lcd_next_st <= st_n8;

      when st_n8 =>                     -- 10, can read now
        lcd_next_st <= st_n9;
      when st_n9 =>                     -- 11, data hold for Enable is >40ns
        lcd_next_st <= st_na;
      when st_na =>                     -- 12
        lcd_next_st <= st_nb;
      when st_nb =>                     -- 13
        lcd_next_st <= st_idle;
        
      when others =>                    -- ??
        lcd_next_st <= st_idle;         --  Enable cycle >500ns
    end case;
  end process U_st_transitions;

  U_st_outputs: process(lcd_current_st)
  begin
    case lcd_current_st is
      when st_init =>        
        lcd_enable <= '0';              -- disable
        lcd_read   <= '1';
        waiting    <= '0';

      when st_idle =>
        lcd_enable <= '0';              -- disable
        lcd_read   <= '1';
        waiting    <= '0';

      when st_n | st_n1 =>
        lcd_enable <= '0';              -- disable, waiting for setup
        lcd_read   <= '1';
        waiting    <= '1';

      when st_n2 | st_n3 | st_n4 | st_n5 | st_n6 | st_n7 =>
        lcd_enable <= '1';              -- enable, waiting
        lcd_read   <= '1';
        waiting    <= '1';
        
      when st_n8 =>
        lcd_enable <= '1';              -- enable, still waiting
        lcd_read   <= '0';
        waiting    <= '1';

      when st_n9 =>
        lcd_enable <= '1';              -- enable, still waiting
        lcd_read   <= '1';
        waiting    <= '1';

      when st_na =>
        lcd_enable <= '0';              -- disable, still waiting
        lcd_read   <= '1';
        waiting    <= '1';

      when st_nb =>
        lcd_enable <= '0';              -- disable, stop waiting
        lcd_read   <= '1';              --  held inp data for 40ns
        waiting    <= '0';

      when others =>
        lcd_enable <= '0';              -- disable
        lcd_read   <= '1';
        waiting    <= '0';
    end case;
  end process U_st_outputs;

end behavioral;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- peripheral: SDcard bus interface (a wrapper to the SDcard controller)
--   base + b"0000" -> address register
--   base + b"0100" -> data registers (RD/WR)
--   base + b"1000" -> control register
--   base + b"1100" -> status register
--
-- Software must ALWAYS check status(31) = busy before reading/writing
--   to controller.  If controller is not busy, check for errors.
--   In case of errors, reset controller by writing 0x10 to control register.
-- Wait states (rdy=0) are inserted as needed by the bus interface.
--
-- Control register: bit(4)=1 reset the controller (because of error)
--                   bit(1)=1 perform a sector READ
--                   bit(0)=1 perform a sector WRITE
--                            bit(0) and bit(1) shall not be both set
--
-- Status register:  bit(31)=1 controller is busy (busy_o=1)
--                   bit(30)=1 simultaneous read and write commands
--                   bit(15..0) controller error bits (see SDcard.vhd)
--
-- Address register: 32 bits, can be written to, and read from
--
-- Data register: data write (sw by CPU), data read (lw by CPU)
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_wires.all;
use work.SdCardPckg.all;

entity SDcard is
  port (rst        : in  std_logic;
        clk        : in  std_logic;
        sel        : in  std_logic;
        rdy        : out std_logic;
        wr         : in  std_logic;
        addr       : in  reg2;       -- a03, a02
        data_inp   : in  reg32;
        data_out   : out reg32;
        sdc_cs     : out std_logic;  -- SDcard chip-select
        sdc_clk    : out std_logic;  -- SDcard serial clock
        sdc_mosi_o : out std_logic;  -- SDcard serial data out (to card)
        sdc_miso_i : in  std_logic;  -- SDcard serial data inp (fro card)
        irq        : out std_logic); -- interrupt request (not yet used)
end SDCard;

architecture behavioral of SDcard is

  component wait_states is
    generic (NUM_WAIT_STATES :integer);
    port(rst   : in  std_logic;
       clk     : in  std_logic;
       sel     : in  std_logic;         -- active in '0'
       waiting : out std_logic);        -- active in '1'
  end component wait_states;
  
  component registerN is
    generic (NUM_BITS: integer; INIT_VAL: std_logic_vector);
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component registerN;

  component FFDsimple is
    port(clk, rst, D : in std_logic; Q : out std_logic);
  end component FFDsimple;

  component SdCardCtrl is
    generic (
      FREQ_G          : real;  -- Master clock frequency (MHz).
      INIT_SPI_FREQ_G : real;  -- Slow SPI clock freq during init (MHz).
      SPI_FREQ_G      : real;  -- Operational SPI freq. to the SD card (MHz).
      BLOCK_SIZE_G    : natural;  -- Num bytes in an SD card block or sector.
      CARD_TYPE_G     : CardType_t);  -- Type of SD card connected.
    port (
      -- Host-side interface signals.
      clk_i      : in  std_logic;  -- Master clock.
      reset_i    : in  std_logic;  -- active-high, synchronous  reset.
      rd_i       : in  std_logic;  -- active-high read block request.
      wr_i       : in  std_logic;  -- active-high write block request.
      continue_i : in  std_logic;  -- If true, inc address and continue R/W.
      addr_i     : in  std_logic_vector;  -- Block address.
      data_i     : in  std_logic_vector;  -- Data to write to block.
      data_o     : out std_logic_vector;  -- Data read from block.
      busy_o     : out std_logic;  -- High when controller is busy.
      hndShk_i   : in  std_logic;  -- High when host has new or has taken data.
      hndShk_o   : out std_logic;  -- High when cntlr has taken or new data.
      error_o    : out std_logic_vector;
      -- I/O signals to the external SD card.
      cs_bo      : out std_logic;   -- Active-low chip-select.
      sclk_o     : out std_logic;   -- Serial clock to SD card.
      mosi_o     : out std_logic;   -- Serial data output to SD card.
      miso_i     : in  std_logic;   -- Serial data input from SD card.
      state      : out std_logic_vector);  -- state, debugging only
  end component SdCardCtrl;

  signal s_addr, s_stat, s_ctrl, s_read, s_write : std_logic;
  signal continue, busy, hndShk_i, hndShk_o, wr_i, rd_i : std_logic;
  signal wait1, waiting, new_trans, new_data_rd, sdc_rst : std_logic;
  signal ctrl_err, set_wr_i, set_rd_i : std_logic;
  signal do_reset, do_reset1 : std_logic;
  signal data_rd, data_rd_reg, data_wr_reg : reg8;
  signal error_o : reg16;
  signal addr_reg : reg32;
  signal sel_data_out : reg3;
  signal state : reg5;
  signal w : reg5;
begin
  
  U_SDcard: SdCardCtrl
    -- generic map (50.0, 0.400, 12.5, 512, SD_CARD_E)
    generic map (50.0, 25.0, 25.0, 512, SD_CARD_E)
    port map (clk, sdc_rst, rd_i, wr_i, '0', addr_reg,
              data_wr_reg, data_rd, busy, hndshk_i, open, error_o,
              -- data_wr_reg, data_rd, busy, hndshk_i, hndshk_o, error_o,
              sdc_cs, sdc_clk, sdc_mosi_o, sdc_miso_i, state);
  
  hndshk_i <= waiting;

  U_WAIT1: component wait_states generic map (1)
    port map (rst, clk, new_trans, wait1);

  U_WAIT: process(rst, clk, wait1, hndshk_o)
    variable w : std_logic;
  begin
    if rst = '0' then
      w := '0';
    elsif rising_edge(clk) then
      if wait1 = '1' then               -- new transaction started
        w := '1';
      end if;
      if hndshk_o = '1' then            -- transaction ended
        w := '0';
      end if;
    end if;
    waiting <= w;
  end process U_WAIT;
  
  rdy <= not(wait1 or waiting);  -- wait for controller
  new_data_rd <= not(hndshk_o);

  U_W1: FFDsimple port map (clk, rst, wait1, w(0));
  U_W2: FFDsimple port map (clk, rst, w(0), w(1));
  U_W3: FFDsimple port map (clk, rst, w(1), w(2));
  U_W4: FFDsimple port map (clk, rst, w(2), w(3));
  U_W5: FFDsimple port map (clk, rst, w(3), w(4));
  U_W6: FFDsimple port map (clk, rst, w(4), hndshk_o);
  
  -- a3a2  wr register (aligned to word addresses: a1a0=00)
  --  00   0  write to ADDR register (32 bits)
  --  00   1  returns current value of ADDR
  --  01   1  read from data register (8 bits, least significant byte)
  --  01   0  write to data register (8 bits, least significant byte)
  --  10   0  write to control register
  --  10   1  read from control register
  --  11   0  no effect (not possible to write to status register)
  --  11   1  read status register

  new_trans <= '0' when addr = b"01" and sel = '0' else '1';
  
  s_addr  <= '0' when sel = '0' and addr = b"00" and wr = '0' else '1';

  s_write <= '0' when sel = '0' and addr = b"01" and wr = '0' else '1';
  s_read  <= '0' when sel = '0' and addr = b"01" and wr = '1' else '1';

  s_ctrl  <= '1' when sel = '0' and addr = b"10" and wr = '0' else '0';
  
  s_stat  <= '1' when sel = '0' and addr = b"11" and wr = '1' else '0';

  do_reset <= '1' when s_ctrl = '1' and data_inp(4) = '1' else '0';
  U_RESET1: FFDsimple port map (clk, rst, do_reset, do_reset1);
  sdc_rst <= not(rst) or do_reset or do_reset1;  -- held HI for 2 cycles

  -- hold wr_i active until first access to WR-register
  set_wr_i <= ((s_ctrl and data_inp(0)) or (wr_i and s_write)) and s_write; 
  U_WR_STROBE: FFDsimple port map (clk, rst, set_wr_i, wr_i);

  -- hold rd_i active until first access to RD-register
  set_rd_i <= ((s_ctrl and data_inp(1)) or (rd_i and s_read)) and s_read;
  U_RD_STROBE: FFDsimple port map (clk, rst, set_rd_i, rd_i);
  
  ctrl_err <= wr_i and rd_i;            -- cannot both read AND write
  
  U_ADDR_REG: registerN generic map (32, x"00000000")
    port map (clk, rst, s_addr, data_inp, addr_reg);

  U_WRITE_REG: registerN generic map (8, x"00")
    port map (clk, rst, s_write, data_inp(7 downto 0), data_wr_reg);

  U_READ_REG: registerN generic map (8, x"00")
    port map (clk, rst, new_data_rd, data_rd, data_rd_reg);

  sel_data_out <= sel & addr;
  
  with sel_data_out select 
    data_out <= addr_reg                         when "000",
                x"000000" & data_rd_reg          when "001",
                x"000000" & b"000" & ctrl_err & b"00" & rd_i & wr_i when "010",
                busy & ctrl_err & b"00" & b"000" & state & x"0" & error_o when "011",
                (others => 'X') when others;
  
end behavioral;
-- ++ SDcard ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


