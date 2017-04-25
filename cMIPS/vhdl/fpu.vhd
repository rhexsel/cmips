-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  cMIPS, a VHDL model of the classical five stage MIPS pipeline.
--  Copyright (C) 2015  Joao Manoel Pampanini Filho & Roberto Andre Hexsel
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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity special_values is
  port (in_a,in_b         : in  std_logic_vector(30 downto 0);
        type_A,type_b     : out FP_type;
        denormA,denormB   : out std_logic);
end special_values;

architecture estrutural of special_values is

  -- type_A= 11    A=0.0
  -- type_A= 01    infinito
  -- type_A= 10    NaN
  -- type_A= 00    A é numero bom
  -- type FP_type is fp_is_good, fp_is_inf, fp_is_NaN, fp_is_zero;

  constant mant_all_zeroes : reg23 := (others => '0');
  constant exp_all_zeroes  : reg8  := (others => '0');
  constant exp_all_ones    : reg8  := (others => '1');
  
begin

  U_check_A: process(in_a)
    variable mant_is_zero, exp_is_zero, exp_is_255 : boolean;
  begin
    mant_is_zero := (in_a(22 downto  0) = mant_all_zeroes);
    exp_is_zero  := (in_a(30 downto 23) = exp_all_zeroes);
    exp_is_255   := (in_a(30 downto 23) = exp_all_ones);

    if exp_is_zero and mant_is_zero then
      type_A <= fp_is_zero;
    elsif exp_is_255 and mant_is_zero then
      type_A <= fp_is_inf;
    elsif exp_is_255 and not(mant_is_zero) then
      type_A <= fp_is_nan;
    else
      type_A <= fp_is_good;
    end if;

    if exp_is_zero then
      denormA <= '0';
    else
      denormA <= '1';
    end if;

  end process U_check_A;

  
  U_check_B: process(in_b)
    variable mant_is_zero, exp_is_zero, exp_is_255 : boolean;
  begin
    mant_is_zero := (in_b(22 downto  0) = mant_all_zeroes);
    exp_is_zero  := (in_b(30 downto 23) = exp_all_zeroes);
    exp_is_255   := (in_b(30 downto 23) = exp_all_ones);

    if exp_is_zero and mant_is_zero then
      type_B <= fp_is_zero;
    elsif exp_is_255 and mant_is_zero then
      type_B <= fp_is_inf;
    elsif exp_is_255 and not(mant_is_zero) then
      type_B <= fp_is_nan;
    else
      type_B <= fp_is_good;
    end if;

    if exp_is_zero then
      denormB <= '0';
    else
      denormB <= '1';
    end if;

  end process U_check_B;
  
    -- type_A <= b"11" when to_integer(unsigned(in_a(30 downto 23))) = 0 AND to_integer(unsigned(in_a(22 downto 0))) = 0
    -- else b"01" when to_integer(unsigned(in_a(30 downto 23))) = 255 AND to_integer(unsigned(in_a(22 downto 0))) = 0
    -- else b"10" when to_integer(unsigned(in_a(30 downto 23))) = 255 AND to_integer(unsigned(in_a(22 downto 0))) /= 0
    -- else b"00";

    -- type_b <= b"11" when to_integer(unsigned(in_b(30 downto 23))) = 0 AND to_integer(unsigned(in_b(22 downto 0))) = 0
    -- else b"01" when to_integer(unsigned(in_b(30 downto 23))) = 255 AND to_integer(unsigned(in_b(22 downto 0))) = 0
    -- else b"10" when to_integer(unsigned(in_b(30 downto 23))) = 255 AND to_integer(unsigned(in_b(22 downto 0))) /= 0
    -- else b"00";

  -- denormA <= '0' when to_integer(unsigned(in_a(30 downto 23))) = 0 else '1';
  -- denormB <= '0' when to_integer(unsigned(in_b(30 downto 23))) = 0 else '1';

end estrutural;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity data_check_mult is
    port(type_A,type_B : in  FP_type;
         sig_A,sig_B   : in  std_logic;
         sig_out       : out std_logic;
         exp_in        : in  std_logic_vector ( 7 downto 0);
         fra_in        : in  std_logic_vector (22 downto 0);
         exp_out       : out std_logic_vector ( 7 downto 0);
         fra_out       : out std_logic_vector (22 downto 0));
end data_check_mult;

architecture estrutural of data_check_mult is
begin

  check : process(type_A,type_B, exp_in,fra_in)
    variable exp_p : std_logic_vector ( 7 downto 0);
    variable fra_p : std_logic_vector (22 downto 0);
  begin

    -- if (type_A = "10" OR type_B = "10" ) then
      --   exp_p := (OTHERS => '1');
      -- fra_p := (OTHERS => '1');
    -- elsif ( (type_A = "01" AND type_B = "11") OR (type_A = "11" AND type_B = "01") ) then
      -- exp_p := (OTHERS => '1');
      -- fra_p := (OTHERS => '1');
    -- elsif (type_A = "01" OR type_B = "01") then
      -- exp_p := (OTHERS => '1');
      -- fra_p := (OTHERS => '0');
    -- elsif (type_A = "11" OR type_B = "11") then
      -- exp_p := (OTHERS => '0');
      -- fra_p := (OTHERS => '0');
    -- else
      -- exp_p := exp_in;
      -- fra_p := fra_in;
    -- end if;

    case type_A is
      when fp_is_NaN =>                 -- 10
        exp_p := (OTHERS => '1');
        fra_p := (OTHERS => '1');
      when fp_is_inf =>                 -- 01
        exp_p := (OTHERS => '1');
        if type_B = fp_is_zero then     -- 11
          fra_p := (OTHERS => '1');
        else
          fra_p := (OTHERS => '0');
        end if;
      when fp_is_zero =>                -- 11
        if type_B = fp_is_inf then      -- 01
          exp_p := (OTHERS => '1');
          fra_p := (OTHERS => '1');
        else
          exp_p := (OTHERS => '0');
          fra_p := (OTHERS => '0');
        end if;
      when others =>
        case type_B is
          when fp_is_NaN =>             -- 10
            exp_p := (OTHERS => '1');
            fra_p := (OTHERS => '1');
          when fp_is_zero =>            -- 10
            exp_p := (OTHERS => '0');
            fra_p := (OTHERS => '0');
          when others =>
            exp_p := exp_in;
            fra_p := fra_in;
        end case;
    end case;

    exp_out <= exp_p ;
    fra_out <= fra_p ;
  end process;

  check_sig : process(type_A,type_B, sig_A,sig_B)
    variable sig_p : std_logic;
  begin
    if (type_A = fp_is_NaN OR type_B = fp_is_NaN ) then
      sig_p := '0';
    elsif ( (type_A = fp_is_inf  AND type_B = fp_is_zero) OR
            (type_A = fp_is_zero AND type_B = fp_is_inf ) ) then
      sig_p := '0';
    else
      sig_p := sig_A XOR sig_B;
    end if;

    sig_out <= sig_p;
  end process check_sig;
   
end estrutural;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- MULT_FLOAT
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity mult32float is
  port(AB_in          : in  std_logic_vector(31 downto 0);
       rel,rst,wt_in  : in  std_logic;
       sela,selb,selc : in  std_logic;
       prod           : out std_logic_vector(31 downto 0);
       pronto,wt_out  : out std_logic);
end mult32float;

architecture estrutural of mult32float is

  component special_values is
    port (in_a,in_b         : in  std_logic_vector;
          type_A,type_b     : out FP_type;
          denormA,denormB   : out std_logic);
  end component special_values;

  component data_check_mult is
    port (type_A,type_B : in  FP_type;
          sig_A,sig_B   : in  std_logic;
          sig_out       : out std_logic;
          exp_in        : in  std_logic_vector;
          fra_in        : in  std_logic_vector;
          exp_out       : out std_logic_vector;
          fra_out       : out std_logic_vector);
  end component data_check_mult;


signal vlid_stg0,wt_stg0,flag,denormA,denormB: std_logic;
signal type_A,type_B : FP_type;
signal expA,expB,exp_ab,exp_p,desloc : std_logic_vector(8 downto 0);
signal in_A,in_B : std_logic_vector(31 downto 0);

signal vlid_stg1,wt_stg1,sign_A,sign_B : std_logic;
signal type_A2,type_B2 : FP_type;
signal deloc2 : std_logic_vector(4 downto 0);
signal exp_stg1 : std_logic_vector(7 downto 0);
signal frac_A,frac_B : std_logic_vector(23 downto 0);
signal frac_p : std_logic_vector(47 downto 0);

signal vlid_stg2,wt_stg2,sign_A2,sign_B2,sign_f : std_logic;
signal type_A3,type_B3 : FP_type;
signal deloc3,deloc4 : std_logic_vector(4 downto 0);
signal exp_stg2,exp_stg3,exp_f : std_logic_vector(7 downto 0);
signal frac_f,mant : std_logic_vector(22 downto 0);
signal frac_normed : std_logic_vector(23 downto 0);
signal frac_rounded : std_logic_vector(25 downto 0);
signal signR : std_logic_vector(47 downto 0);

signal w_intra,w_pronto: std_logic;

begin

  -- ENTRADA
  stg0_start: process(rel)
  begin
    if rising_edge(rel) then
      if (rst = '0' or (selA = selB and flag = '0')) then
        vlid_stg0 <= '0';
        wt_stg0   <= '0';
        flag      <= '0';
        in_A      <= x"00000000";
        in_B      <= x"00000000" ;
      elsif (selA = '1' and selB = '0') then
        vlid_stg0 <= '0';
        wt_stg0   <= '1';
        flag      <= '1';
        in_A      <= AB_in;
        in_B      <= x"00000000";
      elsif (selA = '0' and selB = '1') then
        vlid_stg0 <= '1';
        wt_stg0   <= '1';
        flag      <= '0';
        in_A      <= in_A;
        in_B      <= AB_in;
      end if;
    end if;
  end process;

  s_cases : special_values
    port map (in_A(30 downto 0),in_B(30 downto 0),
              type_A,type_B, denormA,denormB);

  -- separa expoentes da entrada
  expA <= '0' & in_A(30 downto 23) when denormA = '1' else b"000000001";
  -- e agenta para a soma
  expB <= '0' & in_B(30 downto 23) when denormB = '1' else b"000000001";

  -- soma dos expoentes
  exp_ab <=  std_logic_vector(signed(expA) + signed(expB)); -- soma com a bias

  exp_p <= '0' & x"ff" when exp_ab >= b"011111111" else
           '0' & x"00" when exp_ab <= b"001111111" else
           std_logic_vector(signed(exp_ab) + signed'("110000001"));

  desloc <= b"000000000" when exp_ab > b"001111111" else
            std_logic_vector(signed'("010000000") - signed(exp_ab));

  -- MULT
  stg1_Mult: process(rel)
  begin
    if rising_edge(rel) then
      if (rst = '0' or vlid_stg0 = '0') then
        vlid_stg1   <= '0'            ;
        wt_stg1     <= '0'            ;
        type_A2     <= fp_is_good;
        type_B2     <= fp_is_good;
        sign_A      <= '0'            ;
        sign_B      <= '0'            ;
        deloc2      <= (OTHERS => '0');
        exp_stg1    <= (OTHERS => '0');
        frac_A      <= (OTHERS => '0');
        frac_B      <= (OTHERS => '0');
      else
        vlid_stg1   <= '1';
        wt_stg1     <= wt_stg0;
        type_A2     <= type_A         ;
        type_B2     <= type_B         ;
        sign_A      <= in_A(31)       ;
        sign_B      <= in_B(31)       ;
        if (desloc < b"000011000") then
          deloc2 <= desloc(4 downto 0) ;
        else
          deloc2 <= "11000";
        end if;
        exp_stg1    <= exp_p(7 downto 0);
        frac_A       <= denormA & in_A(22 downto 0);
        frac_B       <= denormB & in_B(22 downto 0);
      end if;
    end if;
  end process;

  frac_p <= std_logic_vector(unsigned(frac_A) * unsigned(frac_B)) ;

  -- NORM e ROUND
  stg2_round: process(rel)
  begin
    if rising_edge(rel) then
      if (rst = '0' or vlid_stg1 = '0') then
        vlid_stg2   <= '0'     ;
        wt_stg2     <= '0'     ;
        type_A3     <= fp_is_good;
        type_B3     <= fp_is_good;
        sign_A2     <= '0'     ;
        sign_B2     <= '0'     ;
        deloc3      <= (OTHERS => '0');
        exp_stg2    <= (OTHERS => '0');
        signR       <= (OTHERS => '0');
      else
        vlid_stg2   <= '1'        ;
        wt_stg2     <= wt_stg1    ;
        type_A3     <= type_A2    ;
        type_B3     <= type_B2    ;
        sign_A2     <= sign_A     ;
        sign_B2     <= sign_B     ;
        deloc3      <= deloc2     ;
        exp_stg2    <= exp_stg1   ;
        signR       <= frac_p     ;
      end if;
    end if;
  end process;

  frac_rounded <= std_logic_vector(unsigned('0' & signR(46 downto 22)) + 1) WHEN signR(47) = '0'
               ELSE std_logic_vector(unsigned('0' & signR(47 downto 23)) + 1);

  deloc4 <=  std_logic_vector(unsigned(deloc3) - 1) when (signR(47) = '1' or frac_rounded(25) = '1') and deloc3 > b"00000" else deloc3;

  exp_stg3 <= x"00" when signR(47) = '0' and signR(46) = '0' else std_logic_vector(unsigned(exp_stg2) + 1) when (signR(47) = '1' or frac_rounded(25) = '1') and deloc3 = b"00000" else exp_stg2;

  frac_normed <= b"0000" & x"00000" when exp_stg3 = x"ff"
                 else std_logic_vector(unsigned(frac_rounded(25 downto 2)) srl to_integer(unsigned(deloc4))) when frac_rounded(25) = '1'
                 else std_logic_vector(unsigned(frac_rounded(24 downto 1)) srl to_integer(unsigned(deloc4)));

  mant <= frac_normed(22 downto 0);

  finish : data_check_mult
    port map (type_A3,type_B3,sign_A2,sign_B2,sign_f,exp_stg3,mant,exp_f,frac_f);

  -- Fim do processo
  stg3_final: process(rel)
  begin
    if rising_edge(rel) then
      if ( rst = '0' or
           (selc = '1' and  w_intra = '0' and vlid_stg2 = '0') ) then
        w_pronto <= '0';
        prod   <= x"00000000";
      elsif (selc = '0' and w_pronto = '1') then
        w_pronto <= '1';
      elsif (vlid_stg2 = '1') then
        w_pronto <= '1';
        prod   <= sign_f & exp_f  & frac_f;
      end if;
    end if;
  end process;

  pronto <= w_pronto;
  w_intra <= (wt_in or wt_stg0 or wt_stg1 or wt_stg2) and (not w_pronto) ;
  wt_out <= w_intra;

end estrutural;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity data_check_sum is
  port(type_A,type_B : in  std_logic_vector ( 1 downto 0);
       sig_A,sig_B   : in  std_logic;
       sig_out       : out std_logic;
       exp_in        : in  std_logic_vector ( 7 downto 0);
       fra_in        : in  std_logic_vector (22 downto 0);
       exp_out       : out std_logic_vector ( 7 downto 0);
       fra_out       : out std_logic_vector (22 downto 0));
end data_check_sum;

architecture estrutural of data_check_sum is

  signal sig_p : std_logic;
  signal exp_p : std_logic_vector ( 7 downto 0);
  signal fra_p : std_logic_vector (22 downto 0);

begin

  check : process(type_A,type_B,sig_A,sig_B,exp_in,fra_in)
  begin
    if (type_A = "10" OR type_B = "10" ) then
      sig_p <= '0';
      exp_p <= (OTHERS => '1');
      fra_p <= (OTHERS => '1');
    elsif (type_A = "01" AND sig_A /= sig_B AND type_B = "01") then
      sig_p <= '0';
      exp_p <= (OTHERS => '1');
      fra_p <= (OTHERS => '1');
    elsif (type_A = "01") then
      sig_p <= sig_A;
      exp_p <= (OTHERS => '1');
      fra_p <= (OTHERS => '0');
    elsif (type_B = "01") then
      sig_p <= sig_B;
      exp_p <= (OTHERS => '1');
      fra_p <= (OTHERS => '0');
    elsif (type_A = "11" OR type_B = "11") then
      sig_p <= sig_A AND sig_B;
      exp_p <= (OTHERS => '0');
      fra_p <= (OTHERS => '0');
    elsif (exp_in = x"00") AND (fra_in = b"0000000000000") then
      sig_p <= '0';
      exp_p <= (OTHERS => '0');
      fra_p <= (OTHERS => '0');
    else
      sig_p <= sig_A;
      exp_p <= exp_in;
      fra_p <= fra_in;
    end if;
  end process;

  sig_out <= sig_p ;
  exp_out <= exp_p ;
  fra_out <= fra_p ;

end estrutural;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SUM_FLOAT
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sum32float is
  port (AB_in          : in  std_logic_vector (31 downto 0);
        rel,rst,wt_in  : in  std_logic;
        sela,selb,selc : in  std_logic;
        prod           : out std_logic_vector (31 downto 0);
        pronto,wt_out  : out std_logic);
end sum32float;

architecture estrutural of sum32float is

  component special_values is
    port (in_a,in_b        : in  std_logic_vector ;
          type_A,type_B    : out std_logic_vector ;
          denormA,denormB  : out std_logic);
  end component special_values;

  component data_check_sum is
    port (type_A,type_B : in  std_logic_vector;
          sig_A,sig_B   : in  std_logic;
          sig_out       : out std_logic;
          exp_in        : in  std_logic_vector ;
          fra_in        : in  std_logic_vector ;
          exp_out       : out std_logic_vector ;
          fra_out       : out std_logic_vector);
  end component data_check_sum;


signal vlid_stg0,wt_stg0,flag,denorma,denormb,sub_sum  : std_logic ;
signal type_A,type_B : std_logic_vector( 1 downto 0);
signal expA,expB,exp_p,deloc : std_logic_vector( 7 downto 0);
signal st0_sign_A,st0_sign_B_un,st0_sign_B,st0_sign_B2 : std_logic_vector(25 downto 0);
signal in_A,in_B : std_logic_vector(31 downto 0);

signal vlid_stg1,wt_stg1,s_A,s_b,sin : std_logic ;
signal type_A2,type_B2,aux           : std_logic_vector( 1 downto 0);
signal desloc                        : std_logic_vector( 4 downto 0);
signal exp_stg1,delocn               : std_logic_vector( 7 downto 0);
signal signA,signB,sum_AB            : std_logic_vector(25 downto 0);
signal sum_AB2                       : std_logic_vector(26 downto 0);

signal vlid_stg2,wt_stg2,s_A2,s_b2,sign_f : std_logic ;
signal type_A3,type_B3                    : std_logic_vector( 1 downto 0);
signal exp_stg2,exp_f,exp_stg21,exp_aux   : std_logic_vector( 7 downto 0);
signal sum_f,frac_f                       : std_logic_vector(22 downto 0);
signal sum_C                              : std_logic_vector(25 downto 0);
signal rounded_sum                        : std_logic_vector(27 downto 0);

signal w_pronto,w_intra : std_logic;

begin

  -- ENTRADA
  stg0_start: process(rel)
  begin
    if rising_edge(rel) then
      if (rst = '0' or (selA = selB and flag = '0')) then
        vlid_stg0 <= '0';
        wt_stg0   <= '0';
        flag      <= '0';
        in_A      <= x"00000000";
        in_B      <= x"00000000" ;
      elsif (selA = '1' and selB = '0') then
        vlid_stg0 <= '0';
        wt_stg0   <= '1';
        flag      <= '1';
        in_A      <= AB_in;
        in_B      <= x"00000000";
      elsif (selA = '0' and selB = '1') then
        vlid_stg0 <= '1';
        wt_stg0   <= '1';
        flag      <= '0';
        if ( unsigned(in_A(30 downto 0)) >= unsigned(AB_in(30 downto 0)) ) then
          in_A      <= in_A;
          in_B      <= AB_in;
        else
          in_A      <= AB_in;
          in_B      <= in_A;
        end if;
      end if;
    end if;
  end process;

  -- s_cases : special_values
  --   port map (in_A(30 downto 0),in_B(30 downto 0),type_a,type_b,denormA,denormB);

  expA <=  in_A(30 downto 23) when denormA = '1' else x"01";
  expB <=  in_B(30 downto 23) when denormB = '1' else x"01";

  deloc <= std_logic_vector(unsigned(expA) - unsigned(expB));

  exp_p <= expA;

  sub_sum <= in_A(31) xor in_B(31);

  st0_sign_A <= b"00" & denormA & in_A(22 downto 0);
  st0_sign_B_un <= b"00" & denormB & in_B(22 downto 0);
  st0_sign_B2 <= std_logic_vector(unsigned(st0_sign_B_un) srl to_integer(unsigned(deloc)));
  st0_sign_B <= std_logic_vector(-signed(st0_sign_B2)) when sub_sum = '1' else st0_sign_B2;

  -- MULT
  stg1_Mult: process(rel)
  begin
    if rising_edge(rel) then
      if (rst = '0' or vlid_stg0 = '0') then
        vlid_stg1   <= '0';
        wt_stg1     <= '0';
        type_A2     <= (OTHERS => '0');
        type_B2     <= (OTHERS => '0');
        s_A         <= '0';
        s_b         <= '0';
        exp_stg1    <= (OTHERS => '0');
        signA       <= (OTHERS => '0');
        signB       <= (OTHERS => '0');
      else
        vlid_stg1   <= '1';
        wt_stg1     <= wt_stg0;
        type_A2     <= type_A;
        type_B2     <= type_B;
        s_A         <= in_A(31);
        s_b         <= in_B(31);
        exp_stg1    <= exp_p;
        signA       <= st0_sign_A;
        signB       <= st0_sign_B;
      end if;
    end if;
  end process;

  sum_AB <=  std_logic_vector(signed(signA) + signed(signB));
  sum_ab2 <= sum_AB & '0';

  deloc_sum: process(sum_AB)
  begin
      if (sum_AB(24) = '1') then
        desloc <= b"00001";
        sin <= '0';
      elsif (sum_AB(23) = '1') then
        desloc <= b"00000";
        sin <= '0';
      elsif (sum_AB(22) = '1') then
        desloc <= b"00001";
        sin <= '1';
      elsif (sum_AB(21) = '1') then
        desloc <= b"00010";
        sin <= '1';
      elsif (sum_AB(20) = '1') then
        desloc <= b"00011";
        sin <= '1';
      elsif (sum_AB(19) = '1') then
        desloc <= b"00100";
        sin <= '1';
      elsif (sum_AB(18) = '1') then
        desloc <= b"00101";
        sin <= '1';
      elsif (sum_AB(17) = '1') then
        desloc <= b"00110";
        sin <= '1';
      elsif (sum_AB(16) = '1') then
        desloc <= b"00111";
        sin <= '1';
      elsif (sum_AB(15) = '1') then
        desloc <= b"01000";
        sin <= '1';
      elsif (sum_AB(14) = '1') then
        desloc <= b"01001";
        sin <= '1';
      elsif (sum_AB(13) = '1') then
        desloc <= b"01010";
        sin <= '1';
      elsif (sum_AB(12) = '1') then
        desloc <= b"01011";
        sin <= '1';
      elsif (sum_AB(11) = '1') then
        desloc <= b"01100";
        sin <= '1';
      elsif (sum_AB(10) = '1') then
        desloc <= b"01101";
        sin <= '1';
      elsif (sum_AB(9) = '1') then
        desloc <= b"01110";
        sin <= '1';
      elsif (sum_AB(8) = '1') then
        desloc <= b"01111";
        sin <= '1';
      elsif (sum_AB(7) = '1') then
        desloc <= b"10000";
        sin <= '1';
      elsif (sum_AB(6) = '1') then
        desloc <= b"10001";
        sin <= '1';
      elsif (sum_AB(5) = '1') then
        desloc <= b"10010";
        sin <= '1';
      elsif (sum_AB(4) = '1') then
        desloc <= b"10011";
        sin <= '1';
      elsif (sum_AB(3) = '1') then
        desloc <= b"10100";
        sin <= '1';
      elsif (sum_AB(2) = '1') then
        desloc <= b"10101";
        sin <= '1';
      elsif (sum_AB(1) = '1') then
        desloc <= b"10110";
        sin <= '1';
      elsif (sum_AB(0) = '1') then
        desloc <= b"10111";
        sin <= '1';
      else
        desloc <= b"11000";
        sin <= '1';
      end if;
  end process;

  aux <= b"01" when exp_stg1 = b"11111110" and desloc = b"00001" and sin = '0' else b"10" when desloc = b"11000" and sin = '1' else "00";

  delocn <=  "000" & desloc when (sin = '0') OR ( unsigned(desloc) <= (unsigned(exp_stg1) - unsigned'(b"00000001"))) else std_logic_vector(unsigned(exp_stg1) - unsigned'(b"00000001"));

  -- NORM e ROUND
  stg2_round: process(rel)
  begin
    if rising_edge(rel) then
      if (rst = '0' or vlid_stg1 = '0') then
        vlid_stg2   <= '0';
        wt_stg2     <= '0';
        type_A3     <= (OTHERS => '0');
        type_B3     <= (OTHERS => '0');
        s_A2        <= '0';
        s_b2        <= '0';
        exp_stg2    <= (OTHERS => '0');
        sum_C       <= (OTHERS => '0');
      else
        vlid_stg2   <= '1';
        wt_stg2     <= wt_stg1;
        type_A3     <= type_A2;
        type_B3     <= type_B2;
        s_A2        <= s_A;
        s_b2        <= s_b;
        if (aux > b"00") then
          exp_stg2 <= (OTHERS => aux(0));
        elsif (unsigned(desloc) > (unsigned(exp_stg1) - unsigned'(b"00000001"))) then
          exp_stg2 <= (OTHERS => '0');
        elsif (sin = '0') then
          exp_stg2 <= std_logic_vector(unsigned(exp_stg1) + unsigned(delocn));
        else
          exp_stg2 <= std_logic_vector(unsigned(exp_stg1) - unsigned(delocn));
        end if;
        if (aux > b"00") then
          sum_C <= (OTHERS => '0');
        elsif (sin = '0') then
          sum_C <= std_logic_vector(unsigned(sum_AB2(25 downto 0)) srl to_integer(unsigned(delocn)));
        else
          sum_C <= std_logic_vector(unsigned(sum_AB2(25 downto 0)) sll to_integer(unsigned(delocn)));
        end if;
      end if;
    end if;
  end process;

  rounded_sum <= std_logic_vector(unsigned( b"000" & sum_C(24 downto 0)) + unsigned'(x"0000001"));

  exp_aux <= std_logic_vector(unsigned(exp_stg2) + unsigned'(b"00000001")) when rounded_sum(25) = '1' else exp_stg2;

  sum_f <=  b"00000000000000000000000" when exp_stg2 = x"fe" and rounded_sum(25) = '1'
            else rounded_sum(24 downto 2) when rounded_sum(25) = '1'
           else rounded_sum(23 downto 1);

  exp_stg21 <= x"01" when exp_stg2 = x"00" and rounded_sum(24) = '1'
            else x"ff" when exp_stg2 = x"fe" and rounded_sum(25) = '1'
            else exp_aux;

  finish : data_check_sum
    port map (type_A3,type_B3,s_A2,s_b2,sign_f,exp_stg21,sum_f,exp_f,frac_f);

  -- Fim do processo
  stg3_final: process(rel)
  begin
    if rising_edge(rel) then
      if ( rst = '0' or (selc = '1' and  w_intra = '0' and vlid_stg2 = '0')) then
        w_pronto <= '0';
        prod   <= x"00000000";
      elsif (selc = '0' and w_pronto = '1') then
        w_pronto <= '1';
      elsif (vlid_stg2 = '1') then
        w_pronto <= '1';
        prod   <= sign_f & exp_f & frac_f;
      end if;
    end if;
  end process;

  pronto <= w_pronto;
  w_intra <= (wt_in or wt_stg0 or wt_stg1 or wt_stg2) and (not w_pronto) ;
  wt_out <= w_intra;

end architecture estrutural;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FPU
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_wires.all;

entity FPU is
  port(rst      : in    std_logic;
       clk      : in    std_logic;
       sel      : in    std_logic;
       rdy      : out   std_logic;
       wr       : in    std_logic;
       addr     : in    reg4;
       data_inp : in    reg32;
       data_out : out   reg32);
end FPU;


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- fake FPU
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture fake of FPU is
begin
  rdy <= '1';
  data_out <= (others => '0');
end architecture fake;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FPU
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
architecture rtl of FPU is

  component wait_states is
    generic (NUM_WAIT_STATES :integer);
    port(rst   : in  std_logic;
         clk     : in  std_logic;
         sel     : in  std_logic;         -- active in '0'
         waiting : out std_logic);        -- active in '1'
  end component wait_states;

  component mult32float is port(
    AB_in          : in  std_logic_vector;
    rel,rst,wt_in  : in  std_logic ;
    sela,selb,selc : in  std_logic ;
    prod           : out std_logic_vector;
    pronto,wt_out  : out std_logic);
  end component mult32float;

  component sum32float is port(
    AB_in          : in  std_logic_vector;
    rel,rst,wt_in  : in  std_logic ;
    sela,selb,selc : in  std_logic ;
    prod           : out std_logic_vector;
    pronto,wt_out  : out std_logic);
  end component sum32float;

  --component div32float is port(
  --AB_in          : in  std_logic_vector;
  --rel,rst,wt_in  : in  std_logic ;
  --sela,selb,selc : in  std_logic ;
  --prod           : out std_logic_vector;
  --pronto,wt_out  : out std_logic);
  --end component div32float;

  signal wt,wt0,pt0,selA_mul,selB_mul,selC_mul, wt_mul, wt_st0 : std_logic;
  signal    wt1,pt1,selA_sum,selB_sum,selC_sum : std_logic;
  signal    wt2,pt2,selA_div,selB_div,selC_div : std_logic;
  signal RES_MUL,RES_SUM,RES_DIV               : std_logic_vector(31 DOWNTO 0);

begin

  U_Mult_float: mult32float
    port map (data_inp,clk,rst,'0',selA_mul,selB_mul,selC_mul,RES_MUL,pt0,wt0);

  RES_SUM <= (others => 'X');
  -- U_Sum_float : sum32float
  -- port map (data_inp,clk,rst,wt,selA_sum,selB_sum,selC_sum,RES_SUM,pt1,wt1);

  -- U_Div_float : div32float
  -- port map (data_inp,clk,rst,wt,selA_div,selB_div,selC_div,RES_DIV,pt2,wt2);


  -- sel   wr  addr
  --  0    0   0000   ativa selA (SW A) MUL
  --  0    0   0001   ativa selB (SW B) MUL
  --  0    1   0001   ativa selC (LW C) MUL
  
  --  0    0   0100   ativa selA (SW A) SUM
  --  0    0   0101   ativa selB (SW B) SUM
  --  0    1   0100   ativa selC (LW C) SUM
  
  --  0    0   1100   ativa selA (SW A) DIV
  --  0    0   1101   ativa selB (SW B) DIV
  --  0    1   110x   ativa selC (LW C) DIV
  
  --  1    x   xxx   *#NOP#*

  selA_mul <= '1' when sel = '0' and addr = "0000" and wr = '0' else '0';
  selB_mul <= '1' when sel = '0' and addr = "0001" and wr = '0' else '0';
  selC_mul <= '1' when sel = '0' and addr = "0000" and wr = '1' else '0';

  selA_sum <= '1' when sel = '0' and addr = "0010" and wr = '0' else '0';
  selB_sum <= '1' when sel = '0' and addr = "0011" and wr = '0' else '0';
  selC_sum <= '1' when sel = '0' and addr = "0010" and wr = '1' else '0';

  --selA_div <= '1' when sel = '0' and addr = "0100" and wr = '0' else '0';
  --selB_div <= '1' when sel = '0' and addr = "0101" and wr = '0' else '0';
  --selC_div <= '1' when sel = '0' and addr = "0100" and wr = '1' else '0';

  wt_mul <= not(selC_mul);

  U_WAIT_ON_READS: component wait_states
    generic map (1) port map (rst, clk, wt_mul, wt_st0);
  
  rdy <= not(wt_st0 or (wt0 and selC_mul)); -- or (wt1 and selC_sum)); --or (wt2 and selC_div));

  data_out <= RES_MUL when selC_mul = '1' else
              RES_SUM when selC_sum = '1' else
              (others => 'X');
              --RES_DIV when selC_div = '1' else
end architecture rtl;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


