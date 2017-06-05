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

library IEEE;
use IEEE.std_logic_1164.all;
package p_UART is
  constant BAUD_RT_0 : integer :=    4/2;
  constant BAUD_RT_1 : integer :=    8/2;
  constant BAUD_RT_2 : integer :=   16/2;
  constant BAUD_RT_3 : integer :=   32/2;
  constant BAUD_RT_4 : integer :=   64/2;
  constant BAUD_RT_5 : integer :=  128/2;
  constant BAUD_RT_6 : integer := 2604/2;  -- 19.200,  434/2 = 115.200
  constant BAUD_RT_7 : integer := 5208/2;  --  9.600

  -- top limit for baud-rate divider: 50.000.000 Hz / 4 = 12.500.000 baud
  --   which, adjusted to the next upward power of two is 16M
  constant BAUD_CNTR_LIMIT : integer := ((16*1024*1024)-1);  -- 
end p_UART;

-- package body p_UART is
-- end p_UART;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- UART internals; the external/processor interface is defined in io.vhdl
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- control register, least significant byte only
-- b2..b0: transmit/receive clock speed
--         000: 1/4  CPU clock rate -- for VHDL/C debugging only
--         001: 1/8  CPU clock rate -- for VHDL/C debugging only
--         010: 1/16 CPU clock rate -- for VHDL/C debugging only
--         011: 1/32 CPU clock rate -- for VHDL/C debugging only
--         100: 1/64 CPU clock rate -- for VHDL/C debugging only
--         101: 1/128 CPU clock rate -- for VHDL/C debugging only
--         110:  19.200 bits per second
--         111:   9.600 bits per second
-- b3=1:   signal interrupt on RX buffer full, when a new octet is available
-- b4=1:   signal interrupt on TX buffer empty, when TX space is available
-- b5,b6:  ignored, not used
-- b7=1:   turn on Request to Send (RTS)
--
-- Baud rates dividers (BAUD_RT_n) are defined in packageWires.vhd
-- 
-- status register, least significant byte only
-- b0: overurn error, last octet received overwrote previous in buffer
-- b1: framing error, last octet was not framed by START, STOP bits
-- b2: not used, returns zero
-- b3: interrupt pending on RX buffer full
-- b4: interrupt pending on TX buffer empty
-- b5: receive buffer is full
-- b6: transmit buffer is empty
-- b7: Clear to Send (CTS) is active (=1)
--
-- when CPU reads from RXdat register, bits 0 and 1 of status are cleared
-- 
-- interrupt clear register, least significant byte only
-- b2..b0: ignored, not used
-- b3=1:   clear interrupt bit on RX buffer full (IRQ -> 0)
-- b4=1:   clear interrupt bit on TX buffer empty (IRQ -> 0)
-- b5=1:   set interrupt bit on RX buffer full (IRQ -> 1)
-- b6=1:   set interrupt bit on TX buffer empty (IRQ -> 1)
-- b7:     ignored, not used
--
-- RX and TX circuits are dobule-buffered
--

library ieee; use ieee.std_logic_1164.all;
use work.p_WIRES.all;
use work.p_UART.all;

entity uart_int is
  port(clk, rst: in std_logic;
       s_ctrlwr, s_stat  : in std_logic; -- select registers
       s_tx, s_rx        : in std_logic; -- select registers
       s_intwr, s_intrd  : in std_logic; -- select interrupt register
       d_inp:  in  reg32;               -- input
       d_out:  out reg32;               -- output
       txdat:  out std_logic;           -- interface: serial transmission
       rxdat:  in  std_logic;           -- interface: serial reception
       rts   : out std_logic;           -- interface: request to send
       cts   : in  std_logic;           -- interface: clear to send
       irq_all: out std_logic;          -- interrupt request
       bit_rt : out reg3);              -- communication speed, for debugging
end uart_int;

architecture estrutural of uart_int is

  constant CLOCK_DIVIDER : integer := 50;

  -- bit in ctrl register to set/clear the RTS serial interface signal
  constant RTS_B : integer := 7;

  -- bit in interrupt register to set/clear RX interrupt request
  constant SET_IRQ_TX : integer := 6;
  -- bit in interrupt register to set/clear RX interrupt request
  constant SET_IRQ_RX : integer := 5;
  -- bit in interrupt register to set/clear TX interrupt request
  constant CLR_IRQ_TX : integer := 4;
  -- bit in interrupt register to set/clear RX interrupt request
  constant CLR_IRQ_RX : integer := 3;

  -- bit in ctrl register to set/clear TX interrupt request
  constant IRQ_TX_B : integer := 4;
  -- bit in ctrl register to set/clear RX interrupt request
  constant IRQ_RX_B : integer := 3;

  
  component register8 is
    port(clk, rst, ld: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component register8;

  component par_ser10 is
    port(clk, rst, ld, desl: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic);
  end component par_ser10;

  component ser_par10 is
    port(clk, rst, desl: in  std_logic;
         D:            in  std_logic;
         Q:            out std_logic_vector);
  end component ser_par10;

  component FFDsimple is
    port(clk, rst, D : in std_logic; Q : out std_logic);
  end component FFDsimple;

  -- state machine for transmission-CPU interface
  type txcpu_state is (st_idle, st_check, st_done);
  signal txcpu_current_st, txcpu_next_st : txcpu_state;
  attribute SYN_ENCODING of txcpu_state : type is "safe";
  
  -- state machine for transmission circuit
  type tx_state is (st_idle, st_check, st_start,
                    st_b0, st_b1, st_b2, st_b3, st_b4, st_b5, st_b6, st_b7,
                    st_stop, st_end, st_done);
  signal tx_current_st, tx_next_st : tx_state;
  attribute SYN_ENCODING of tx_state : type is "safe";

  -- state machine for reception-CPU interface
  type rxcpu_state is (st_idle, st_copy, st_check, st_error);
  signal rxcpu_current_st, rxcpu_next_st : rxcpu_state;
  attribute SYN_ENCODING of rxcpu_state : type is "safe";
  
  -- state machine for reception circuit
  type rx_state is (st_idle, st_check, st_start,
                    st_b0, st_b1, st_b2, st_b3, st_b4, st_b5, st_b6, st_b7,
                    st_stop, st_done);
  signal rx_current_st, rx_next_st : rx_state;
  attribute SYN_ENCODING of rx_state : type is "safe";
  
  -- for debugging only
  signal tx_dbg_st, txcpu_dbg_st, rx_dbg_st, rxcpu_dbg_st : integer; 

  signal ctrl, status, txreg, rxreg, received : reg8;
  signal tx_bit_rt, rx_bit_rt : std_logic;
  signal en_tx_clk, txclk, txclk_rise : std_logic;
  signal tx_ld, tx_shift, tx_next, tx_bfr_empt, tx_shr_full : std_logic;
  signal rx_ld, rx_shift, rx_next, rx_bfr_full : std_logic;
  signal rxdat_1to0, rxdat_new, rxdat_int, rxdat_old : std_logic;
  signal rxclk_fall, rxclk_rise, en_rx_clk, rx_done, rxclk : std_logic;
  signal a_overrun, a_framing, reset_rxck : std_logic;
  signal sta_xmit_sto, sta_recv_sto : reg10;
  signal err_overrun, err_framing : std_logic;
  signal rx_int_set, interr_RX_full, tx_int_set, interr_TX_empty : std_logic;
  signal d_int_tx_empty,d_rx_int_set,d_err_framing,d_err_overrun : std_logic;
  signal clear_tx_irq, clear_rx_irq : std_logic;
  
  signal tx_baud_div, rx_baud_div : integer := 0;

begin
  
  -- interrupt register must read 0's as compiler generates RD-mod-WR
  --   sequences to set or clear individual bits
  d_out <= x"000000" & received when s_rx    = '1' else
           x"000000" & status   when s_stat  = '1' else
           x"00000000"          when s_intrd = '1' else  -- RD-mod-WR
           x"000000" & ctrl;            -- show ctrl all other times

  rts <= ctrl(RTS_B);
  
  -- for testing only: tells remote unit what is the transmission speed
  bit_rt <= ctrl(2 downto 0);
  
  U_ctrl:  register8 port map (clk,rst, s_ctrlwr, d_inp(7 downto 0), ctrl);

  status <= cts & tx_bfr_empt & rx_bfr_full &
            interr_TX_empty & interr_RX_full & 
            '0' & err_framing & err_overrun;

  irq_all <= interr_TX_empty or interr_RX_full;

  -- TRANSMISSION ===========================================================
  -- txreg is updated under the assumption that SW checked TXempty beforehand
  U_txreg: register8 port map (clk,rst, s_tx, d_inp(7 downto 0), txreg);

  
  sta_xmit_sto <= '1' & txreg & '0';     -- start (b0), octet, stop (b9)
  tx_next <= txclk_rise and tx_shift;
  U_transmit: par_ser10 port map (clk, rst, tx_ld, tx_next,
                                   sta_xmit_sto, txdat);

  clear_tx_irq <= '0' when s_intwr = '1' and d_inp(CLR_IRQ_TX) = '1' else '1';
  
  tx_int_set <= ( (ctrl(IRQ_TX_B) and tx_ld) or
                  (s_intwr and d_inp(SET_IRQ_TX)) );
  d_int_tx_empty <= (interr_TX_empty or tx_int_set) and clear_tx_irq;
  U_tx_int: FFDsimple port map (clk, rst, d_int_tx_empty, interr_TX_empty);

  
  -- this state machine contols the CPU-transmission interface -------------
  U_TXCPU_st_reg: process(rst,clk)
  begin
    if rst = '0' then
      txcpu_current_st <= st_idle;
    elsif rising_edge(clk) then
      txcpu_current_st <= txcpu_next_st;
    end if;
  end process U_TXCPU_st_reg; ----------------------------------------------

  txcpu_dbg_st <= integer(txcpu_state'pos(txcpu_current_st)); -- for debugging

  U_TXCPU_st_transitions: process(txcpu_current_st, s_tx, tx_shr_full) -----
  begin
    case txcpu_current_st is
      when st_idle =>                   -- 0
        if s_tx = '1' then
          txcpu_next_st <= st_check;
        else
          txcpu_next_st <= st_idle;
        end if;
      when st_check =>                  -- 1
        if tx_shr_full = '1' then
          txcpu_next_st <= st_check;
        else
          txcpu_next_st <= st_done;
        end if;
      when st_done =>                   -- 2
        txcpu_next_st <= st_idle;
      when others =>
        assert false report "TX-CPU stateMachine broken"
          & integer'image(txcpu_state'pos(txcpu_current_st)) severity failure;
    end case;
  end process U_TXCPU_st_transitions;   ------------------------------------

  
  U_TXCPU_outputs: process(txcpu_current_st)  ------------------------------
  begin
    case txcpu_current_st is
      when st_idle =>                   -- 0
        tx_ld       <= '0';
        tx_bfr_empt <= '1';
      when st_check =>                  -- 1
        tx_ld       <= '0';
        tx_bfr_empt <= '0';
      when st_done =>                   -- 2
        tx_ld       <= '1';
        tx_bfr_empt <= '0';
    end case;
  end process U_TXCPU_outputs;   -------------------------------------------



  -- state machine controls data transmission circuit ----------------------
  U_TX_st_reg: process(rst,clk)
  begin
    if rst = '0' then
      tx_current_st <= st_idle;
    elsif rising_edge(clk) then
      tx_current_st <= tx_next_st;
    end if;
  end process U_TX_st_reg;

  tx_dbg_st <= integer(tx_state'pos(tx_current_st));  -- debugging
  
  U_TX_st_transitions: process(tx_current_st,tx_ld,txclk_rise)
  begin
    case tx_current_st is
      when st_idle =>
        if tx_ld = '1' then
          tx_next_st <= st_check;
        else
          tx_next_st <= st_idle;
        end if;
      when st_check =>
        tx_next_st <= st_start;
      when st_start =>
        if txclk_rise = '1' then
          tx_next_st <= st_b0;      -- synchronize CPUclock with TXclock
        else
          tx_next_st <= st_start;
        end if;
      when st_b0 =>
        if txclk_rise = '1' then
          tx_next_st <= st_b1;
        else
          tx_next_st <= st_b0;
        end if;
      when st_b1 =>
        if txclk_rise = '1' then
          tx_next_st <= st_b2;
        else
          tx_next_st <= st_b1;
        end if;
      when st_b2 =>
        if txclk_rise = '1' then
          tx_next_st <= st_b3;
        else
          tx_next_st <= st_b2;
        end if;
      when st_b3 =>
        if txclk_rise = '1' then
          tx_next_st <= st_b4;
        else
          tx_next_st <= st_b3;
        end if;
      when st_b4 =>
        if txclk_rise = '1' then
          tx_next_st <= st_b5;
        else
          tx_next_st <= st_b4;
        end if;
      when st_b5 =>
        if txclk_rise = '1' then
          tx_next_st <= st_b6;
        else
          tx_next_st <= st_b5;
        end if;
      when st_b6 =>
        if txclk_rise = '1' then
          tx_next_st <= st_b7;
        else
          tx_next_st <= st_b6;
        end if;
      when st_b7 =>
        if txclk_rise = '1' then
          tx_next_st <= st_stop;
        else
          tx_next_st <= st_b7;
        end if;
      when st_stop =>
        if txclk_rise = '1' then
          tx_next_st <= st_end;
        else
          tx_next_st <= st_stop;
        end if;
      when st_end =>
        if txclk_rise = '1' then        -- wait for stop-bit to end
          tx_next_st <= st_done;
        else
          tx_next_st <= st_end;
        end if;
      when st_done =>
        tx_next_st  <= st_idle;
      when others =>
        assert false report "TX stateMachine broken"
          & integer'image(tx_state'pos(tx_current_st)) severity failure;
    end case;
  end process U_TX_st_transitions;   -- -----------------------------------


  U_TX_outputs: process(tx_current_st)  -- --------------------------------
  begin
    case tx_current_st is
      when st_idle =>
        tx_shr_full <= '0';
        tx_shift    <= '0';
        en_tx_clk   <= '0';
      when st_check =>
        tx_shift    <= '0';
        tx_shr_full <= '1';
        en_tx_clk   <= '1';
      when st_start | st_b0 | st_b1 | st_b2 | st_b3 | st_b4 | st_b5 | st_b6 | st_b7 | st_stop | st_end =>
        tx_shift    <= '1';
        tx_shr_full <= '1';
        en_tx_clk   <= '1';
      when st_done =>
        tx_shr_full <= '1';
        tx_shift    <= '0';
        en_tx_clk   <= '0';
    end case;
  end process U_TX_outputs;   ----------------------------------------------



  -- RECEPTION =============================================================
  
  U_rxreg: register8 port map (clk,rst, rx_ld, rxreg, received);
  
  rx_next <= rx_shift and rxclk_rise;
  U_receive: ser_par10 port map (clk, rst, rx_next, rxdat, sta_recv_sto);
  rxreg <= sta_recv_sto(8 downto 1);

  U_edgeDetect0: FFDsimple port map (clk, rst, rxdat, rxdat_new);
  U_edgeDetect1: FFDsimple port map (clk, rst, rxdat_new, rxdat_int);
  U_edgeDetect2: FFDsimple port map (clk, rst, rxdat_int, rxdat_old);
  rxdat_1to0 <= rxdat_old and not(rxdat_new);
  
  -- framing error: 10th bit not a STOP=1 or 1st bit not a START=0
  a_framing <= '1' when ( (rx_ld = '1') and
                          (sta_recv_sto(9) /= '1' or sta_recv_sto(0)/='0') )
               else '0';

  d_err_framing <= (a_framing or err_framing) and not(s_rx);
  U_framing: FFDsimple port map (clk, rst, d_err_framing, err_framing);

  d_err_overrun <= (a_overrun or err_overrun) and not(s_rx);
  U_overrun: FFDsimple port map (clk, rst, d_err_overrun, err_overrun);

  clear_rx_irq <= '0' when s_intwr = '1' and d_inp(CLR_IRQ_RX) = '1' else '1';
  
  rx_int_set   <= ( (ctrl(IRQ_RX_B) and rx_done) or
                    (s_intwr and d_inp(SET_IRQ_RX)) );
    
  d_rx_int_set <= (rx_int_set or interr_RX_full) and clear_rx_irq;
  U_rx_int: FFDsimple port map (clk, rst, d_rx_int_set, interr_RX_full);

  
  -- SM controls reception-CPU interface -------------------------------
  U_RXCPU_st_reg: process(rst,clk)
  begin
    if rst = '0' then
      rxcpu_current_st <= st_idle;
    elsif rising_edge(clk) then
      rxcpu_current_st <= rxcpu_next_st;
    end if;
  end process U_RXCPU_st_reg;

  rxcpu_dbg_st <= integer(rxcpu_state'pos(rxcpu_current_st));  -- debugging

  U_RXCPU_st_transitions: process(rxcpu_current_st, rx_done, s_rx)
  begin
    case rxcpu_current_st is
      when st_idle =>                   -- 0
        if rx_done = '1' then           -- rx buffer full
          rxcpu_next_st <= st_copy;
        else
          rxcpu_next_st <= st_idle;
        end if;
      when st_copy =>                   -- 1
        rxcpu_next_st <= st_check;
      when st_check =>                  -- 2
        if rx_done = '1' then
          rxcpu_next_st <= st_error;
        elsif s_rx = '1' then
          rxcpu_next_st <= st_idle;
        else
          rxcpu_next_st <= st_check;
        end if;
      when st_error =>                  -- 3
        rxcpu_next_st <= st_check;
      when others =>
        assert false report "RX-CPU stateMachine broken"
          & integer'image(rxcpu_state'pos(rxcpu_current_st)) severity failure;
    end case;
  end process U_RXCPU_st_transitions; --------------------------------------

  U_RXCPU_outputs: process(rxcpu_current_st)
  begin
    case rxcpu_current_st is
      when st_idle =>                   -- 0
        rx_ld       <= '0';
        rx_bfr_full <= '0';
        a_overrun   <= '0';
      when st_copy =>                   -- 1
        rx_ld       <= '1';
        rx_bfr_full <= '1';
        a_overrun   <= '0';        
      when st_check =>                  -- 2
        rx_ld       <= '0';
        rx_bfr_full <= '1';
        a_overrun   <= '0';
      when st_error =>                  -- 3
        rx_ld       <= '0';
        rx_bfr_full <= '1';
        a_overrun   <= '1';    -- assert overrun error, char overwritten
    end case;
  end process U_RXCPU_outputs; ---------------------------------------------

  
  
  -- SM controls data reception circuit ------------------------------------
  U_RX_st_reg: process(rst,clk)
  begin
    if rst = '0' then
      rx_current_st <= st_idle;
    elsif rising_edge(clk) then
      rx_current_st <= rx_next_st;
    end if;
  end process U_RX_st_reg;

  rx_dbg_st <= integer(rx_state'pos(rx_current_st));  -- debugging only
  
  U_RX_st_transitions: process(rx_current_st, rxclk_fall, rxdat_1to0, rxdat)
  begin
    case rx_current_st is
      when st_idle =>
        if rxdat_1to0 = '1' then    -- start bit = falling edge on rxdat
          rx_next_st <= st_check;
        else
          rx_next_st <= st_idle;
        end if;
      when st_check =>
        if rxdat = '0' then
          rx_next_st <= st_start;
        else
          rx_next_st <= st_idle;
        end if;
      when st_start =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b0;
        else
          rx_next_st <= st_start;
        end if;
      when st_b0 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b1;
        else
          rx_next_st <= st_b0;
        end if;
      when st_b1 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b2;
        else
          rx_next_st <= st_b1;
        end if;
      when st_b2 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b3;
        else
          rx_next_st <= st_b2;
        end if;
      when st_b3 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b4;
        else
          rx_next_st <= st_b3;
        end if;
      when st_b4 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b5;
        else
          rx_next_st <= st_b4;
        end if;
      when st_b5 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b6;
        else
          rx_next_st <= st_b5;
        end if;
      when st_b6 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_b7;
        else
          rx_next_st <= st_b6;
        end if;
      when st_b7 =>
        if rxclk_fall = '1' then
          rx_next_st <= st_stop;
        else
          rx_next_st <= st_b7;
        end if;
      when st_stop =>
        if rxclk_fall = '1' then
          rx_next_st <= st_done;
        else
          rx_next_st <= st_stop;
        end if;
      when st_done =>
        rx_next_st <= st_idle;
      when others =>
        assert false report "RX stateMachine broken"
          & integer'image(rx_state'pos(rx_current_st)) severity failure;
    end case;
  end process U_RX_st_transitions; ------------------------------------


  U_RX_outputs: process(rx_current_st)
  begin
    case rx_current_st is
      when st_idle =>
        rx_done    <= '0';
        rx_shift   <= '0';
        reset_rxck <= '0';
        en_rx_clk  <= '0';
      when st_check =>
        rx_done    <= '0';
        rx_shift   <= '0';
        reset_rxck <= '1';
        en_rx_clk  <= '1';
      when st_start | st_b0 | st_b1 | st_b2 | st_b3 | st_b4 | st_b5 | st_b6 | st_b7 | st_stop =>
        rx_done    <= '0';
        rx_shift   <= '1';
        reset_rxck <= '0';
        en_rx_clk  <= '1';
      when st_done =>
        rx_done    <= '1';
        rx_shift   <= '0';
        reset_rxck <= '0';
        en_rx_clk  <= '0';
    end case;
  end process U_RX_outputs; -------------------------------------------


  

  -- baud rate generators ---------------------------------------------

  -- U_bit_rt_tx: counter8 port map (clk,rst,tx_ld,en_tx_clk,x"00",tx_bit_rt);
  with ctrl(2 downto 0) select
    tx_baud_div <= BAUD_RT_0 when b"000",
                   BAUD_RT_1 when b"001",
                   BAUD_RT_2 when b"010",
                   BAUD_RT_3 when b"011",
                   BAUD_RT_4 when b"100",
                   BAUD_RT_5 when b"101",
                   BAUD_RT_6 when b"110",
                   BAUD_RT_7 when others;

  -- max divisor would be 50,000,000 / 1,200 bps = 46.667 < 64k-1
  U_bit_rt_tx: process(clk, rst, tx_ld, en_tx_clk)
    variable baud_cnt : integer range 0 to BAUD_CNTR_LIMIT;
  begin
     if rst = '0' then
      baud_cnt  := 0;
      txclk <= '0';
      txclk_rise <= '0';
    elsif tx_ld = '1' and rising_edge(clk) then
      baud_cnt  := 1;
      txclk <= '0';
      txclk_rise <= '0';
    elsif en_tx_clk = '1' and rising_edge(clk) then
      if baud_cnt = tx_baud_div then
        if txclk = '0' then
          txclk_rise <= '1';
        else
          txclk_rise <= '0';
        end if;
        txclk <= not(txclk);
        baud_cnt := 1;
      else
        baud_cnt := baud_cnt + 1;
        txclk_rise <= '0';
      end if;
    end if;
  end process U_bit_rt_tx;


  -- U_bit_rt_rx:counter8 port map(clk,rst,reset_rxck,en_rx_clk,00,rx_bit_rt);
  with ctrl(2 downto 0) select
    rx_baud_div <= BAUD_RT_0 when b"000",
                   BAUD_RT_1 when b"001",
                   BAUD_RT_2 when b"010",
                   BAUD_RT_3 when b"011",
                   BAUD_RT_4 when b"100",
                   BAUD_RT_5 when b"101",
                   BAUD_RT_6 when b"110",
                   BAUD_RT_7 when others;

  U_bit_rt_rx: process(clk, rst, reset_rxck, en_rx_clk)
    variable baud_cnt : integer range 0 to BAUD_CNTR_LIMIT;
  begin
    if rst = '0' then
      baud_cnt  := 0;
      rxclk <= '0';
      rxclk_fall <= '0';
      rxclk_rise <= '0';
    elsif reset_rxck = '1' and rising_edge(clk) then
      baud_cnt  := (rx_baud_div / 2);
      rxclk <= '0';
      rxclk_fall <= '0';
      rxclk_rise <= '0';
    elsif en_rx_clk = '1' and rising_edge(clk) then
      if baud_cnt = rx_baud_div then
        if rxclk = '1' then
          rxclk_fall <= '1';
        else
          rxclk_fall <= '0';
          rxclk_rise <= '1';
        end if;
        baud_cnt := 1;
        rxclk <= not(rxclk);
      else
        baud_cnt := baud_cnt + 1;
        rxclk_fall <= '0';
        rxclk_rise <= '0';
      end if;
    end if;
  end process U_bit_rt_rx;

end estrutural;
-- -------------------------------------------------------------------



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- 8 bit register, reset=0 asynchronous, load=1 synchronous
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library ieee; use ieee.std_logic_1164.all;
use work.p_WIRES.all;

entity register8 is
  port(clk, rst, ld: in  std_logic;
        D:           in  reg8;
        Q:           out reg8);
end register8;

architecture functional of register8 is
begin

  process(clk, rst)
    variable value: reg8;
  begin
    if rst = '0' then
      value := x"00";
    elsif rising_edge(clk) then
      if ld = '1' then
        value := D;
      end if;
    end if;
    Q <= value;
  end process;

end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- 10 bit shift-register, parallel load, serial output
--   reset=0 asynch, load=1 asynch, shift=1 synch, fills with '1's
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library ieee; use ieee.std_logic_1164.all;
use work.p_WIRES.all;

entity par_ser10 is
  port(clk, rst, ld, desl: in  std_logic;
       D:                  in  reg10;
       Q:                  out std_logic);
end par_ser10;

architecture functional of par_ser10 is
begin

  process(clk, rst, ld, desl, D)
    variable value: reg10;
  begin
    if rst = '0' then
      value := b"1111111111";
      Q <= '1';
    elsif ld = '1' and rising_edge(clk) then
      value := D;
    elsif desl = '1' and rising_edge(clk) then
      Q <= value(0);
      value(8 downto 0) := value(9 downto 1);
      value(9) := '1';                  -- when idle, send stop-bits
    end if;
  end process;

end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- 10 bit shift register, serial input, parallel output
--   reset=0 asynch, load,shift=1 synch
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library ieee; use ieee.std_logic_1164.all;
use work.p_WIRES.all;

entity ser_par10 is
  port(clk, rst, desl: in  std_logic;
       D:              in  std_logic;
       Q:              out reg10);
end ser_par10;

architecture functional of ser_par10 is
begin

  process(clk, rst, desl)
    variable value: reg10;
  begin
    if rst = '0' then
      value := b"0000000000";
    elsif desl = '1' and rising_edge(clk) then
      value(8 downto 0) := value(9 downto 1);
      value(9) := D;
    end if;
    Q <= value;
  end process;
  
end functional;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++





-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- functional model for the "remote computer" -- for testing only
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.p_WIRES.all;
use work.p_UART.all;
        
entity remota is
  generic(OUTPUT_FILE_NAME : string := "serial.out";
          INPUT_FILE_NAME  : string := "serial.inp");
  port(rst, clk  : in  std_logic;
       start     : in  std_logic;    -- start operation =1
       inpDat    : in  std_logic;    -- serial input
       outDat    : out std_logic;    -- serial output
       bit_rt    : in  reg3);        -- selects bit rate
  constant EOT : reg8 := x"04";      -- end of transmission character
end remota;

architecture simulation of remota is

  component counter8 is
    port(clk, rst, ld, en: in  std_logic;
         D:            in  std_logic_vector;
         Q:            out std_logic_vector);
  end component counter8;


  -- transmission signals & states -----------------------------------------
  type tx_state is (st_init, st_idle, st_start,
                    st_b0, st_b1, st_b2, st_b3, st_b4, st_b5, st_b6, st_b7,
                    st_stop, st_wait, st_done);
  signal tx_current_st, tx_next_st : tx_state;
  signal tx_dbg_st : integer;  -- for debugging only
  attribute SYN_ENCODING of tx_state : type is "safe";
  
  signal tx_bit_rt : reg8;
  signal tx_clk, tx_run : std_logic;

  file input_stream : text open read_mode is INPUT_FILE_NAME;
  -- file input_stream : text open read_mode is "STD_INPUT";
  -- -----------------------------------------------------------------------
  
  -- reception signals & states --------------------------------------------
  type rx_state is (st_idle, st_check, st_start,
                    st_b0, st_b1, st_b2, st_b3, st_b4, st_b5, st_b6, st_b7,
                    st_stop, st_done);
  signal rx_current_st, rx_next_st : rx_state;
  signal rx_dbg_st : integer;  -- for debugging only
  attribute SYN_ENCODING of rx_state : type is "safe";
  
  signal recv, rx_bit_rt : reg8;
  signal rx_clk, rx_run, reset_rxck : std_logic;

  signal tx_baud_div, rx_baud_div : integer := 0;
  
  -- file output_stream : text open write_mode is OUTPUT_FILE_NAME;
  file output_stream : text open write_mode is "STD_OUTPUT";
  -- -----------------------------------------------------------------------

  
begin

  -- transmission control SM ----------------------------------------------
  U_TX_st_reg: process(rst,tx_clk)
  begin
    if rst = '0' then
      tx_current_st <= st_wait;
    elsif rising_edge(tx_clk) then
      tx_current_st <= tx_next_st;
    end if;
  end process U_TX_st_reg;

  tx_dbg_st <= integer(tx_state'pos(tx_current_st));  -- debugging only

  U_tx: process (tx_current_st, start, rst)
    variable sentence : line;
    variable char : character;
    variable good, send_eot : boolean;
    variable bfr  : reg8;
    variable j : integer;
  begin

    case tx_current_st is
      when st_wait =>                   -- 12 wait for starting signal
        outDat <= '1';
        tx_run <= '0';                  -- hold TX clock
        send_eot := FALSE;
        if start = '0' then
          tx_next_st <= st_wait;
        else
          if not endfile(input_stream) and rst = '1' then
            readline( input_stream, sentence );  -- read first line of text
            assert TRUE report "fst line: "&integer'image(sentence'length);
            j := 1;
            tx_next_st <= st_init;
          else
            tx_next_st <= st_done;      -- no input, done!
          end if;
        end if;
      when st_init =>                   -- 0
        outDat <= '1';
        tx_run <= '1';                  -- start TX clock
        tx_next_st <= st_idle;
      when st_idle =>                   -- 1
        if not endfile(input_stream) then
          if j > sentence'right then    -- read new line of input
            readline( input_stream, sentence );
            assert TRUE report "new line: "&integer'image(sentence'length);
            bfr := x"0a";               -- new line
            j := 0;
          elsif sentence'length = 0 then
            bfr := x"0a";               -- send new line for empty line
            assert TRUE report "empty line: " & integer'image(j)&" " & LF;
          else
            read (sentence, char, good);
            assert TRUE report "read: " & integer'image(j) & " " &char;
            bfr := std_logic_vector(to_signed( character'pos(char), 8));
          end if;
          tx_next_st <= st_start;
        else
          tx_next_st <= st_done;        -- no more input, done!
        end if;
      when st_start =>                  -- 2
        outDat <= '0';
        tx_next_st <= st_b0;
      when st_b0 =>                     -- 3
        outDat <= bfr(0);
        tx_next_st <= st_b1;
      when st_b1 =>                     -- 4
        outDat <= bfr(1);
        tx_next_st <= st_b2;
      when st_b2 =>                     -- 5
        outDat <= bfr(2);
        tx_next_st <= st_b3;
      when st_b3 =>                     -- 6
        outDat <= bfr(3);
        tx_next_st <= st_b4;
      when st_b4 =>                     -- 7
        outDat <= bfr(4);
        tx_next_st <= st_b5;
      when st_b5 =>                     -- 8
        outDat <= bfr(5);
        tx_next_st <= st_b6;
      when st_b6 =>                     -- 9
        outDat <= bfr(6);
        tx_next_st <= st_b7;
      when st_b7 =>                     -- 10
        outDat <= bfr(7);
        tx_next_st <= st_stop;
      when st_stop =>                   -- 11
        j := j + 1;
        outDat <= '1';
        tx_next_st <= st_idle;
      when st_done =>                   -- 13 wait forever
        if send_eot = FALSE then
          bfr := EOT;                   -- send out an END-OF-TRANSMISSION
          send_eot := TRUE;
          tx_next_st <= st_start;
        else
          tx_next_st <= st_done;        -- no more input, wait forever
          outDat <= '1';
        end if;
        tx_run <= '0';                  -- stop clock
      when others =>
        assert false report "REMOTE TX stateMachine broken"
          & integer'image(tx_state'pos(tx_current_st)) severity failure;
      end case;

  end process U_tx;
  -- ======================================================================


  
  -- reception ============================================================

  -- reception control SM -------------------------------------------------
  U_RX_st_reg: process(rst,clk)
  begin
    if rst = '0' then
      rx_current_st <= st_idle;
    elsif rising_edge(clk) then
      rx_current_st <= rx_next_st;
    end if;
  end process U_RX_st_reg;

  rx_dbg_st <= integer(rx_state'pos(rx_current_st));  -- debugging only

  U_rx: process(rx_current_st, rx_clk, inpDat)
    variable msg : line;
  begin
    case rx_current_st is
      when st_idle =>
        reset_rxck <= '0';
        rx_run     <= '0';
        recv       <= (others => 'U');
        if falling_edge(inpDat) then    -- start bit
          rx_next_st <= st_check;
        else
          rx_next_st <= st_idle;
        end if;
      when st_check =>
        reset_rxck <= '1';
        rx_run     <= '1';
        rx_next_st <= st_start;
      when st_start =>
        reset_rxck <= '0';
          rx_next_st <= st_b0;
      when st_b0 =>
        if falling_edge(rx_clk) then
          recv(0) <= inpDat;
          rx_next_st <= st_b1;
        else
          rx_next_st <= st_b0;
        end if;
      when st_b1 =>
        if falling_edge(rx_clk) then
          recv(1) <= inpDat;
          rx_next_st <= st_b2;
        else
          rx_next_st <= st_b1;
        end if;
      when st_b2 =>
        if falling_edge(rx_clk) then
          recv(2) <= inpDat;
          rx_next_st <= st_b3;
        else
          rx_next_st <= st_b2;
        end if;
      when st_b3 =>
        if falling_edge(rx_clk) then
          recv(3) <= inpDat;
          rx_next_st <= st_b4;
        else
          rx_next_st <= st_b3;
        end if;
      when st_b4 =>
        if falling_edge(rx_clk) then
          recv(4) <= inpDat;
          rx_next_st <= st_b5;
        else
          rx_next_st <= st_b4;
        end if;
      when st_b5 =>
        if falling_edge(rx_clk) then
          recv(5) <= inpDat;
          rx_next_st <= st_b6;
        else
          rx_next_st <= st_b5;
        end if;
      when st_b6 =>
        if falling_edge(rx_clk) then
          recv(6) <= inpDat;
          rx_next_st <= st_b7;
        else
          rx_next_st <= st_b6;
        end if;
      when st_b7 =>
        if falling_edge(rx_clk) then
          recv(7) <= inpDat;
          rx_next_st <= st_stop;
        else
          rx_next_st <= st_b7;
        end if;
      when st_stop =>
        if falling_edge(rx_clk) then
          rx_next_st <= st_done;
        else
          rx_next_st <= st_stop;
        end if;
      when st_done =>
        rx_run     <= '0';
        rx_next_st <= st_idle;

        if  ((recv /= x"0a") and (recv /= x"04") and (recv /= x"00")) then
          write ( msg, character'val(to_integer(unsigned(recv))) );
        end if;

        if  ((recv = x"0a") or (recv = x"04") or (recv = x"00")) then
          writeline( output_stream, msg );      
        end if;

      when others =>
        assert false report "REMOTE RX stateMachine broken"
          & integer'image(rx_state'pos(rx_current_st)) severity failure;
    end case;
  end process U_rx;


  -- baud rate generators ---------------------------------------------

  with bit_rt select
    tx_baud_div <= BAUD_RT_0 when b"000",
                   BAUD_RT_1 when b"001",
                   BAUD_RT_2 when b"010",
                   BAUD_RT_3 when b"011",
                   BAUD_RT_4 when b"100",
                   BAUD_RT_5 when b"101",
                   BAUD_RT_6 when b"110",
                   BAUD_RT_7 when others;

  U_bit_rt_tx: process(clk, rst)
    variable baud_cnt : integer;
  begin
     if rst = '0' then
      baud_cnt  := 0;
      tx_clk <= '0';
    elsif rising_edge(clk) then
      if baud_cnt = tx_baud_div then
        tx_clk <= not(tx_clk);
        baud_cnt := 1;
      else
        baud_cnt := baud_cnt + 1;
      end if;
    end if;
  end process U_bit_rt_tx;


  -- RX clock daud rate
  with bit_rt select
    rx_baud_div <= BAUD_RT_0 when b"000",
                   BAUD_RT_1 when b"001",
                   BAUD_RT_2 when b"010",
                   BAUD_RT_3 when b"011",
                   BAUD_RT_4 when b"100",
                   BAUD_RT_5 when b"101",
                   BAUD_RT_6 when b"110",
                   BAUD_RT_7 when others;

  U_bit_rt_rx: process(clk, rst, reset_rxck, rx_run)
    variable baud_cnt : integer;
  begin
     if rst = '0' then
      baud_cnt  := 0;
      rx_clk <= '0';
    elsif reset_rxck = '1' and rising_edge(clk) then
      baud_cnt  := 1;
      rx_clk <= '0';
    elsif rx_run = '1' and rising_edge(clk) then
      if baud_cnt = rx_baud_div then
        rx_clk <= not(rx_clk);
        baud_cnt := 1;
      else
        baud_cnt := baud_cnt + 1;
      end if;
    end if;
  end process U_bit_rt_rx;

  
end architecture simulation;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


architecture fake of remota is
begin  -- fake
  outDat <= 'X';
end architecture fake;
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
