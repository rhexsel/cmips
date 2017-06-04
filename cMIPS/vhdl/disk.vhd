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


-- disk(0): ctrl(31)=oper[1=rd, 0=wr], (30)=doInterrupt,
--          (11..0)=transferSize in words, aligned, <= 1024
-- disk(1): stat(31)=oper[1rd, 0wr], (30)=doInterrupt, (29)=busy,
--          (28)=interrupt pending, (27)=0,
--          (26)=errSize [transfer larger than 1024 words],
--          (25,24)=file error [00=ok, 01=status, 10=name, 11=mode]. 
--          (23..0)=last address referenced
-- disk(2): src [rd=disk file {0,1,2,3}, wr=memory address]
-- disk(3): dst [rd=memory address, wr=disk file {0,1,2,3}]
-- disk(4): interr, (1)=setIRQ, (0)=clrIRQ


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- simulates a disk controller with DMA transfers, word only transfers
--   transfers AT MOST 4Kbytes or 1024 memory cycles
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity DISK is
  port (rst      : in    std_logic;
        clk      : in    std_logic;
        strobe   : in    std_logic;     -- strobe for file reads/writes
        sel      : in    std_logic;     -- active in '0'
        rdy      : out   std_logic;     -- active in '0'
        wr       : in    std_logic;     -- active in '0'
        busFree  : in    std_logic;     -- '1' = bus will be free next cycle
        busReq   : out   std_logic;     -- '1' = bus will be used next cycle
        busGrant : in    std_logic;     -- '1' = bus is free in this cycle
        addr     : in    reg3;
        data_inp : in    reg32;
        data_out : out   reg32;
        irq      : out   std_logic;
        dma_addr : out   reg32;
        dma_dinp : in    reg32;
        dma_dout : out   reg32;
        dma_wr   : out   std_logic;     -- active in '0'
        dma_aval : out   std_logic;     -- active in '0'
        dma_type : out   reg4);
  constant NUM_BITS : integer := 32;
  constant START_VALUE : reg32 := (others => '0');
end entity DISK;


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- simulation version -- logic too complex for synthesis,
--                       as there is no hw disk, model is for simulation
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture simulation of DISK is

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

  component FFDsimple is
    port(clk, rst, D : in std_logic; Q : out std_logic);
  end component FFDsimple;

  constant C_OPER    : integer := 31;      -- operation 1=rd, 0=wr
  constant C_OPER_RD : std_logic := '1';
  constant C_OPER_WR : std_logic := '0';
  
  constant C_INT    : integer := 30;      -- interrupt when finished=1
  constant S_BUSY   : integer := 29;      -- controller busy=1
  constant I_SET    : integer :=  1;      -- set IRQ
  constant I_CLR    : integer :=  0;      -- clear IRQ  
  
  constant DSK_OK     : std_logic_vector(1 downto 0) := b"00";
  constant DSK_STATUS : std_logic_vector(1 downto 0) := b"01";
  constant DSK_NAME   : std_logic_vector(1 downto 0) := b"10";
  constant DSK_MODE   : std_logic_vector(1 downto 0) := b"11";

  type int_file is file of integer;
  file my_file : int_file;

  type dma_state is (st_init, st_idle, st_src, st_dst, st_check,
                     st_bus, st_xfer, st_int, st_assert, st_wait, st_err);
  attribute SYN_ENCODING of dma_state : type is "safe";
  signal dma_current_st, dma_next_st : dma_state;
  signal dma_curr_dbg, current_int, ctrl_int, addr_int : integer;
  
  signal ld_ctrl, s_ctrl, s_stat, ld_src, s_src, ld_dst, s_dst : std_logic;
  signal busy, take_bus, ld_curr, rst_curr, en_curr : std_logic;
  signal ctrl, src, dst, stat, datum : reg32 := (others => '0');
  signal current, xfer_sz : reg10;
  signal last_addr : reg24;
  signal base_addr, curr_addr, address : reg32;
  signal s_intw, s_intr, set_irq, clear_irq, s_dat, err_sz : std_logic;
  signal d_set_interrupt, interrupt, do_interr, ld_last : std_logic;
  signal done, last_one : boolean;
  signal err_dsk : reg2 := b"00";
  signal clear_hold_done, set_hold_done, d_set_hold_done, hold_done : std_logic;

begin  -- functional

  rdy <= ZERO;                           -- simulation only, never waits

  s_ctrl <= '1' when sel = '0' and addr = b"000" else '0'; -- R+W
  s_stat <= '1' when sel = '0' and addr = b"001" else '0'; -- R+W
  s_src  <= '1' when sel = '0' and addr = b"010" else '0'; -- W
  s_dst  <= '1' when sel = '0' and addr = b"011" else '0'; -- W
  s_intw <= '1' when sel = '0' and addr = b"100" and wr = '0' else '0'; -- W
  s_intr <= '1' when sel = '0' and addr = b"100" and wr = '1' else '0'; -- R
  s_dat  <= '1' when sel = '0' and addr = b"111" else '0'; -- W, DEBUG

  
  ld_ctrl <= '0' when s_ctrl = '1' and wr = '0' else '1';  
  U_CTRL: registerN  generic map (NUM_BITS, START_VALUE)
    port map (clk, rst, ld_ctrl, data_inp, ctrl);

  ld_src <= '0' when s_src = '1' and wr = '0' else '1';  
  U_SRC:  registerN  generic map (NUM_BITS, START_VALUE)
    port map (clk, rst, ld_src, data_inp, src);

  ld_dst <= '0' when s_dst = '1' and wr = '0' else '1';  
  U_DST:  registerN  generic map (NUM_BITS, START_VALUE)
    port map (clk, rst, ld_dst, data_inp, dst);

  stat <= ctrl(C_OPER) & ctrl(C_INT) & busy & interrupt &
          '0' & err_sz & err_dsk & last_addr;

  
  with addr select
    data_out <= ctrl  when "000",
                stat  when "001",
                src   when "010",
                dst   when "011",
                x"00000000" when others;  -- interrupts, does RD-mod-WR

  irq       <= interrupt;
  
  busReq    <= take_bus;
  
  dma_type  <= b"1111";                   -- always transfers words
  dma_wr    <= not(ctrl(C_OPER)) or not(take_bus);  -- write to RAM
  dma_aVal  <= not(take_bus);

  base_addr <= dst when ctrl(C_OPER) = C_OPER_RD else src;
  curr_addr <= x"0000" & b"0000" & current & b"00";       -- word aligned
  address   <= std_logic_vector( signed(base_addr) + signed(curr_addr) );

  dma_addr  <= address;
  dma_dout  <= datum when ctrl(C_OPER) = C_OPER_RD else (others => 'X');


  xfer_sz  <= ctrl(9 downto 0) when ctrl_int <= 1024 else (others => '0');
  addr_int <= to_integer(unsigned( ctrl(10 downto 0))); 
  err_sz   <= YES when addr_int > 1024 else NO;   -- check if size > 1024
  
  rst_curr <= not(ld_curr) and rst;
  U_CURRENT: countNup generic map (10)           -- current DMA reference 
    port map (clk, rst_curr, '0', en_curr, xfer_sz, current);

  last_one <= (current_int = (ctrl_int - 1));
  ld_last  <= BOOL2SL(not(last_one));
  U_LAST_ADDR: registerN  generic map (24, x"000000")       -- for status
    port map (clk, rst, ld_last, address(23 downto 0), last_addr);

  
  current_int <= to_integer(unsigned(current));
  ctrl_int    <= to_integer(unsigned(ctrl(9 downto 0)));  -- check == 1024

  done        <= ( (current = (ctrl(9 downto 0))) and (hold_done = NO) );
  
  clear_hold_done <= en_curr;     -- first increment, makes current /= 0
  set_hold_done   <= s_ctrl;      -- wait 1 DMA access to check for done

  d_set_hold_done <= (set_hold_done or hold_done) and not(clear_hold_done);
  U_HOLD_DONE: FFDsimple port map (clk, rst, d_set_hold_done, hold_done);
  
  
  
  -- file operations -----------------------------------------------------
  U_FILE_CTRL: process(rst, clk, s_ctrl, s_src, s_dst, data_inp, ctrl)
    variable status : file_open_status := open_ok;
    variable i_status : integer := 0;
  begin

    if rst = '1' then

      if (s_src = YES) and falling_edge(clk) and (ctrl(C_OPER) = C_OPER_RD)
      then            -- read file
        case data_inp(1 downto 0) is
          when b"00" => file_open(status, my_file, "DMA_0.src", read_mode);
          when b"01" => file_open(status, my_file, "DMA_1.src", read_mode);
          when b"10" => file_open(status, my_file, "DMA_2.src", read_mode);
          when b"11" => file_open(status, my_file, "DMA_3.src", read_mode);
          when others => status := name_error;
        end case;
        i_status := file_open_status'pos(status);
        assert status = open_ok
          report "fileRDopen["&SLV32HEX(ctrl)&"]."&SLV32HEX(data_inp)&" "&
          natural'image(i_status);
        case status is
          when open_ok      => err_dsk <= DSK_OK;
          when status_error => err_dsk <= DSK_STATUS;
          when name_error   => err_dsk <= DSK_NAME;
          when mode_error   => err_dsk <= DSK_MODE;
          when others       => null;
        end case;
      end if;

      if (s_dst = YES) and falling_edge(clk) and (ctrl(C_OPER) = C_OPER_WR)
      then
        case data_inp(1 downto 0) is
          when b"00" => file_open(status, my_file, "DMA_0.dst", write_mode);
          when b"01" => file_open(status, my_file, "DMA_1.dst", write_mode);
          when b"10" => file_open(status, my_file, "DMA_2.dst", write_mode);
          when b"11" => file_open(status, my_file, "DMA_3.dst", write_mode);
          when others => status := name_error;
        end case;
        i_status := file_open_status'pos(status);
        assert status = open_ok
          report "fileWRopen["&SLV32HEX(ctrl)&"]."&SLV32HEX(data_inp)&" "&
          natural'image(i_status);
        case status is
          when open_ok      => err_dsk <= DSK_OK;
          when status_error => err_dsk <= DSK_STATUS;
          when name_error   => err_dsk <= DSK_NAME;
          when mode_error   => err_dsk <= DSK_MODE;
          when others       => null;
        end case;
      end if; -- end write file

    end if; -- reset
    
  end process U_FILE_CTRL; -----------------------------------------------

  
  clear_irq <= s_intw and data_inp(I_CLR);

  set_irq   <= ( (ctrl(C_INT) and do_interr) or (s_intw and data_inp(I_SET)) );
  
  d_set_interrupt <= set_irq or (interrupt and not(clear_irq));
  U_tx_int: FFDsimple port map (clk, rst, d_set_interrupt, interrupt);
  

  -- state register-------------------------------------------------------
  U_st_reg: process(rst,clk)
  begin
    if rst = ZERO then
      dma_current_st <= st_init;
    elsif rising_edge(clk) then
      dma_current_st <= dma_next_st;
    end if;
  end process U_st_reg;
  dma_curr_dbg <= dma_state'pos(dma_current_st);  -- debugging only

  
  U_st_transitions: process(dma_current_st, strobe, done,
                            s_ctrl, s_src, s_dst, s_stat,
                            busFree, busGrant, current, ctrl, interrupt,
                            dma_dinp, err_sz, err_dsk)
    variable i_datum : integer;
    variable i_addr, i_val : reg32;
  begin
    case dma_current_st is
      when st_init =>                   -- 0
        dma_next_st <= st_idle;

      when st_idle =>                   -- 1
        if s_ctrl = YES then
          dma_next_st <= st_src;
        else
          dma_next_st <= st_idle;
        end if;

      when st_src =>                    -- 2
        if s_src = YES then
          dma_next_st <= st_dst;
        else
          dma_next_st <= st_src;
        end if;

      when st_dst =>                    -- 3
        if s_dst = YES then
          dma_next_st <= st_check;
        else
          dma_next_st <= st_dst;
        end if;

      when st_check =>                  -- 4  are there any errors?
        if err_sz = NO and err_dsk = b"00" then
          dma_next_st <= st_bus;
        else
          dma_next_st <= st_err;        -- YES, wait for status to be read
        end if;
        
      when st_bus =>                    -- 5
        if busFree = NO then
          dma_next_st <= st_bus;
        else
          dma_next_st <= st_xfer;
        end if;

      when st_xfer =>                   -- 6
        if not(done) then     -- not done

          i_addr := x"00000" & current & b"00";
          if ( rising_edge(strobe) and (busGrant = YES) )then
            if ctrl(C_OPER) = C_OPER_RD then  -- read
              if not(endfile(my_file)) then
                read( my_file, i_datum );
                datum <= std_logic_vector(to_signed(i_datum, 32));
                i_val := std_logic_vector(to_signed(i_datum, 32));
                assert TRUE
                  report "DISKrd["&SLV32HEX(i_addr)&"]="&SLV32HEX(i_val);
              else
                datum <= (others => 'X');
              end if;
            else                      -- write = ctrl(C_OPER) = C_OPER_WR
              write( my_file, to_integer(signed(dma_dinp)) );
              assert TRUE
                report "DISKwr["&SLV32HEX(i_addr)&"]="&SLV32HEX(dma_dinp);
            end if;
          end if;

          if busFree = NO then
            dma_next_st <= st_bus;
          else
            dma_next_st <= st_xfer;
          end if;
          
        else                            -- done
          dma_next_st <= st_int;
        end if;

      when st_int =>                    -- 7
        if ctrl(C_INT) = YES then       -- shall we raise an interrupt?
          dma_next_st <= st_assert;
        else
          dma_next_st <= st_idle;
        end if;
        file_close(my_file);

      when st_assert =>                 -- 8
        dma_next_st <= st_wait;
        
      when st_wait =>                   -- 9
        if interrupt = YES then         -- wait for IRQ to be cleared
          dma_next_st <= st_wait;
        else
          dma_next_st <= st_idle;
        end if;

      when st_err =>                    -- 10
        if s_stat = NO then
          dma_next_st <= st_err;
        else
          dma_next_st <= st_idle;
        end if;
        
      when others =>                    -- ??
        dma_next_st <= st_idle;
    end case;
  end process U_st_transitions; -- -----------------------------------


  U_st_outputs: process(dma_current_st, done)
  begin
    case dma_current_st is
      when st_init | st_idle | st_src =>
        busy       <= NO;               -- free
        en_curr    <= NO;               -- do not increment address
        ld_curr    <= NO;               -- do not load address
        take_bus   <= NO;               -- leave the bus alone
        do_interr  <= NO; 
        
      when st_dst =>
        busy       <= YES;              -- busy
        en_curr    <= NO;               -- do not increment address
        ld_curr    <= YES;              -- load address
        take_bus   <= NO;               -- leave the bus alone
        do_interr  <= NO; 
        
      when st_bus | st_check | st_wait =>
        busy       <= YES;              -- busy
        en_curr    <= NO;               -- do not increment address
        ld_curr    <= NO;               -- do not load address
        take_bus   <= NO;               -- leave the bus alone
        do_interr  <= NO; 

      when st_xfer =>
        busy       <= YES;              -- busy
        en_curr    <= YES;              -- increment address          
        if not(done) then
          take_bus <= YES;              -- request bus
        else
          take_bus <= NO;
         end if;
        ld_curr    <= NO;               -- do not load address
        do_interr  <= NO; 
        
      when st_int =>
        busy       <= NO;               -- free
        en_curr    <= NO;               -- do not increment address
        ld_curr    <= NO;               -- do not load address
        take_bus   <= NO;               -- leave the bus alone
        do_interr  <= NO; 

      when st_assert =>
        busy       <= NO;               -- free
        en_curr    <= NO;               -- increment address
        ld_curr    <= NO;               -- do not load address
        take_bus   <= NO;               -- leave the bus alone
        do_interr  <= YES;              -- raise interrupt request

      when others =>
        busy       <= NO;               -- free
        en_curr    <= NO;               -- do not increment address
        ld_curr    <= NO;               -- do not load address
        take_bus   <= NO;               -- leave the bus alone
        do_interr  <= NO; 
    end case;
  end process U_st_outputs; -- -----------------------------------
  
  
end architecture simulation;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- synthesis version - compiler will optimize all away (one hopes)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture fake of DISK is
begin
  rdy      <= 'X';
  busReq   <= NO;
  irq      <= NO;
  data_out <= (others => 'X');
  dma_addr <= (others => 'X');
  dma_dout <= (others => 'X');
  dma_wr   <= 'X';
  dma_aval <= 'X';
  dma_type <= (others => 'X');
end architecture fake;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



