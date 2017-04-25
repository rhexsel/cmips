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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library std;
use std.textio.all;

package p_WIRES is

  attribute BUFFERED : string;          -- this signal needs high drive
  attribute ASYNC_SET_RESET : boolean;  -- use asynchronous set+reset
  attribute ROM_BLOCK : string;         -- tell synthesis this is a ROM
  attribute RAM_BLOCK : string;         -- tell synthesis this is a RAM
  attribute FSM_STATE : string;         -- type of state encoding
  attribute FSM_COMPLETE : boolean;     -- keep states with clause others
  attribute CLOCK_SIGNAL : string;
  attribute ENUM_ENCODING : string;
  attribute COMBINATIONAL : boolean;    -- process is combinational

  -- Attribute "safe" implements a safe state machine.
  -- This is a state machine that can recover from an
  -- illegal state (by returning to the reset state).
  attribute SYN_ENCODING : string;
  -- attribute SYN_ENCODING of state_type : type is "safe";
  
  subtype reg2  is std_logic_vector(1 downto 0);
  subtype reg3  is std_logic_vector(2 downto 0);
  subtype reg4  is std_logic_vector(3 downto 0);
  subtype reg5  is std_logic_vector(4 downto 0);
  subtype reg6  is std_logic_vector(5 downto 0);
  subtype reg7  is std_logic_vector(6 downto 0);
  subtype reg8  is std_logic_vector(7 downto 0);
  subtype reg9  is std_logic_vector(8 downto 0);
  subtype reg10 is std_logic_vector(9 downto 0);
  subtype reg11 is std_logic_vector(10 downto 0);
  subtype reg12 is std_logic_vector(11 downto 0);
  subtype reg13 is std_logic_vector(12 downto 0);
  subtype reg16 is std_logic_vector(15 downto 0);
  subtype reg17 is std_logic_vector(16 downto 0);
  subtype reg18 is std_logic_vector(17 downto 0);
  subtype reg19 is std_logic_vector(18 downto 0);
  subtype reg20 is std_logic_vector(19 downto 0);
  subtype reg21 is std_logic_vector(20 downto 0);
  subtype reg23 is std_logic_vector(22 downto 0);
  subtype reg24 is std_logic_vector(23 downto 0);
  subtype reg26 is std_logic_vector(25 downto 0);
  subtype reg28 is std_logic_vector(27 downto 0);
  subtype reg30 is std_logic_vector(29 downto 0);
  subtype reg31 is std_logic_vector(30 downto 0);
  subtype reg32 is std_logic_vector(31 downto 0);
  subtype reg33 is std_logic_vector(32 downto 0);
  subtype reg64 is std_logic_vector(63 downto 0);  

  constant CLOCK_PER   : time := 20 ns;

  -- DO NOT change (textual) format of these four lines
  constant NUM_MAX_W_STS  : integer := 1;
  constant ROM_WAIT_STATES: integer := 0;  -- num additional wait states
  constant RAM_WAIT_STATES: integer := 0;  -- num additional wait states
  constant IO_WAIT_STATES : integer := 0;  -- num additional wait states

  
  subtype  max_wait_states is integer range 0 to NUM_MAX_W_STS;

  type t_alu_fun is (opNOP,
                     opSLL, opSLLV, opSRL, opSRA, opSRLV, opSRAV,
                     opMOVZ, opMOVN,
                     opMFHI, opMTHI, opMFLO, opMTLO,
                     opMULT, opMULTU, opDIV, opDIVU, opMUL,
                     opADD, opADDU, opSUB, opSUBU,
                     opAND, opOR, opXOR, opNOR,
                     opSLT, opSLTU, opLUI,
                     opSPC, opSWAP, opEXT, opINS, opSEB, opSEH,
                     trGEQ, trGEU, trLTH, trLTU, trEQU, trNEQ, trNOP,
                     invalid_op);

  attribute ENUM_ENCODING of t_alu_fun : type is
    "000000 000001 000010 000011 000100 000101 000110 000111 001000 001001 001010 001011 001100 001101 001110 001111 010000 010001 010010 010011 010100 010101 010110 010111 011000 011001 011010 011011 011100 011101 011110 011111 100000 100001 100010   100011 100100 100101 100110 100111 101000 101001   101010";
  
  type instr_type is (iALU,ADD,ADDU,SUB,SUBU,iAND,iOR,iXOR,iNOR,  --8
                      RIMM,BLTZ,BGEZ, BLTZAL,BGEZAL,  -- 13
                      J, JAL, BEQ,BNE,BLEZ,BGTZ,      -- 19
                      ADDI,ADDIU, ANDI,ORI,XORI,LUI,  -- 25
                      COP0, SPEC3,         -- 27
                      SLT,SLTU,SLTI,SLTIU, -- 31
                      LB,LH,LWL,LW,LBU,LHU,LWR,  -- 38
                      SB,SH,SWL,SW,SWR, LL, SC,  -- 45
                      iSLL,iSRL,iSRA,SLLV,SRLV,SRAV,  -- 51
                      JR,JALR,          -- 53
                      MOVZ,MOVN,        -- 55
                      MFHI,MTHI,MFLO,MTLO, MULT,MULTU,DIV,DIVU,  -- 63
                      BREAK, SYSCALL, NOP, TEQ,TNE, TEQI,TNEI,   -- 70
                      TLT,TLTU,TLTI,TLTIU, TGE,TGEU,TGEI,TGEIU,  -- 78
                      SPEC2, NIL,invalid_instr);  -- 81

  attribute ENUM_ENCODING of instr_type : type is
    "0000000 0000001 0000010 0000011 0000100 0000101 0000110 0000111    0001000 0001001 0001010 0001011 0001100 0001101 0001110 0001111    0010000 0010001 0010010 0010011 0010100 0010101 0010110 0010111    0011000 0011001 0011010 0011011 0011100 0011101 0011110 0011111   0100000 0100001 0100010 0100011 0100100 0100101 0100110 0100111     0101000 0101001 0101010 0101011 0101100 0101101 0101110 0101111     0110000 0110001 0110010 0110011 0110100 0110101 0110110 0110111     0111000 0111001 0111010 0111011 0111100 0111101 0111110 0111111  1000000 1000001 1000010 1000011 1000100 1000101 1000110 1000111     1001000 1001001 1001010 1001011 1001100 1001101 1001110 1001111 1010000   1010001";

--    1010010 1010011 1010100 1010101 1010110 1010111
--    1011000 1011001 1011010 1011011 1011100 1011101 1011110 1011111


  
  constant NULL_INSTRUCTION : reg32 := x"fc000000";  -- opcode = 63
  
  -- comparison type: ltz,gez
  type t_comparison is (cNOP,cEQU,cNEQ,cLTZ,cLEZ,cGTZ,cGEZ,cOTH,
                        cSUB,cSLT,cSUBU,cSLTU,tGEQ,tGEU,tLTH,tLTU,tEQU,tNEQ);
  
  type t_control_type is record
    aVal:  std_logic;        -- addressValid, enable data-mem=0
    wmem:  std_logic;        -- READ=1/WRITE=0 in/to memory
    i:     instr_type;       -- instruction
    wreg:  std_logic;        -- register write=0
    selB:  std_logic;        -- B ULA input, reg=0 ext=1
    fun:   std_logic;        -- check function_field=1
    oper:  t_alu_fun;        -- ULA operation
    muxC:  reg3;             -- select result mem=0 ula=1 jr=2 pc+8=3
    c_sel: reg2;             -- select destination reg RD=0 RT=1 31=2
    extS:  std_logic;        -- sign-extend=1, zero-ext=0
    PCsel: reg2;             -- PCmux 0=PC+4 1=beq 2=j 3=jr
    br_t:  t_comparison;     -- branch/trap comparison type
    excp:  reg2;             -- stage with exception 0=no,1=rf,2=ex,3=mm
  end record;

  type t_control_mem is array (0 to 63) of t_control_type;
  
  type t_function_type is record
    i:     instr_type;       -- instruction
    wreg:  std_logic;        -- register write=0
    selB:  std_logic;        -- B ULA input, reg=0 ext=1
    oper:  t_alu_fun;        -- ULA operation
    muxC:  reg3;             -- select result mem=0 ula=1 jr=2 pc+8=3
    trap:  std_logic;        -- trap on compare
    move:  std_logic;        -- conditional move
    sync:  std_logic;        -- synch the memory hierarchy
    PCsel: reg2;             -- PCmux 0=PC+4 1=beq 2=j 3=jr
    excp:  reg2;             -- stage with exception 0=no,1=rf,2=ex,3=mm
  end record;

  type t_function_mem is array (0 to 63) of t_function_type;

  type t_rimm_type is record
    i:     instr_type;       -- instruction
    wreg:  std_logic;        -- register write=0
    selB:  std_logic;        -- B ULA input, reg=0 ext=1
    br_t:  t_comparison;     -- branch/trap comparison type    
    muxC:  reg3;             -- select result mem=0 ula=1 jr=2 *al(pc+8)=3
    c_sel: reg2;             -- select destination reg RD=0 RT=1 31=2
    trap:  std_logic;        -- trap on compare
    PCsel: reg2;             -- PCmux 0=PC+4 1=beq 2=j 3=jr
    excp:  reg2;             -- stage with exception 0=no,1=rf,2=ex,3=mm
  end record;

  type t_rimm_mem is array (0 to 31) of t_rimm_type;

  -- type for floating point numbers: 'good' number, infinity, NaN, zero
  type FP_type is (fp_is_good, fp_is_inf, fp_is_NaN, fp_is_zero);

  
  function log2_ceil(n: natural) return natural;  
  function CONVERT_BOOLEAN(b: in boolean) return std_logic;
  function CONVERT_STRING(s: in string) return std_logic_vector;
  function SL2STR(s: in std_logic) return string;
  function SLV2STR(s: in std_logic_vector) return string;
  function SLV32HEX(w: in std_logic_vector(31 downto 0)) return string;
  function BOOL2SL(b: in boolean) return std_logic;
  function SL2BOOL(s: in std_logic) return boolean;
  function SLV2ASCII(s: std_logic_vector(7 downto 0)) return character;
  function SH_LEFT (inp: std_logic_vector; num_bits: integer) 
    return std_logic_vector;
  function SH_RIGHT(inp : std_logic_vector; num_bits : integer) 
    return std_logic_vector;
  
end p_WIRES;


package body p_WIRES is

  -- ---------------------------------------------------------
  -- find minimum number of bits required to
  -- represent N as an unsigned binary number
  function log2_ceil(n: natural) return natural is
  begin
    if n < 2 then
      return 0;
    else
      return 1 + log2_ceil(n/2);
    end if;
  end;
  -- ---------------------------------------------------------  


  -- ---------------------------------------------------------
  -- shift LEFT a std_logic_vector by num_bits positions
  function SH_LEFT(inp : std_logic_vector; num_bits : integer) 
    return std_logic_vector is
    constant zeros : std_logic_vector(num_bits-1 downto 0) := (others => '0');
  begin
    return inp(inp'high-num_bits downto inp'low) & zeros;
  end function;
  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- shift RIGHT a std_logic_vector by num_bits positions
  function SH_RIGHT(inp : std_logic_vector; num_bits : integer) 
    return std_logic_vector is
    constant zeros : std_logic_vector(num_bits-1 downto 0) := (others => '0');
  begin
    return zeros & inp(inp'high downto inp'low+num_bits);
  end function;
  -- ---------------------------------------------------------
  
  
  -- --------------------------------------------------------- 
  -- convert boolean to std_logic
  function CONVERT_BOOLEAN(b: in boolean) return std_logic is
    variable result : std_logic;
  begin
    if b then
      result := '1'; 
    else
      result := '0';
    end if;
    return result;
  end CONVERT_BOOLEAN;
  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- convert string to std_logic_vector 
  function CONVERT_STRING(s: in string) return std_logic_vector is
    variable result : std_logic_vector(s'range);
  begin
    for i in s'range loop
      if s(i) = '0' then
        result(i) := '0'; 
      elsif s(i) = '1' then 
        result(i) := '1';
      elsif s(i) = 'x' then
        result(i) := 'X';
      else
        result(i) := 'Z';
      end if;
    end loop;
    return result;
  end CONVERT_STRING;
  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- convert std_logic literal to a string, for debugging
  function SL2STR(s: in std_logic) return string is
    variable stmp : string(1 downto 1);
  begin
    case s is
      when 'U' =>  stmp(1) := 'u';
      when 'X' =>  stmp(1) := 'x';
      when '1' =>  stmp(1) := '1';
      when '0' =>  stmp(1) := '0';
      when 'Z' =>  stmp(1) := 'z';
      when 'W' =>  stmp(1) := 'w';
      when 'L' =>  stmp(1) := 'l';
      when 'H' =>  stmp(1) := 'h';
      when others => stmp(1) := '-';
    end case;
    return stmp;
  end;
  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- convert std_logic_vector to a string, for debugging
  function SLV2STR(s: in std_logic_vector) return string is
    variable stmp : string(s'left+1 downto 1);
  begin
    for i in s'reverse_range loop
      case s(i) is
        when 'U' =>  stmp(i+1) := 'u';
        when 'X' =>  stmp(i+1) := 'x';
        when '1' =>  stmp(i+1) := '1';
        when '0' =>  stmp(i+1) := '0';
        when 'Z' =>  stmp(i+1) := 'z';
        when 'W' =>  stmp(i+1) := 'w';
        when 'L' =>  stmp(i+1) := 'l';
        when 'H' =>  stmp(i+1) := 'h';
        when others => stmp(i+1) := '-';
      end case;
    end loop;
    return stmp;
  end;
  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- convert std_logic_vector(32) to an hexadecimal string, for debugging
  function SLV32HEX(w: in std_logic_vector(31 downto 0)) return string is
    variable nibble: reg4;
    variable stmp : string(8 downto 1);
  begin
    for i in 8 downto 1 loop
      nibble := w(((i-1)*4+3) downto ((i-1)*4));
      case nibble is
        when b"0000" => stmp(i) := '0';
        when b"0001" => stmp(i) := '1';
        when b"0010" => stmp(i) := '2';
        when b"0011" => stmp(i) := '3';
        when b"0100" => stmp(i) := '4';
        when b"0101" => stmp(i) := '5';
        when b"0110" => stmp(i) := '6';
        when b"0111" => stmp(i) := '7';
        when b"1000" => stmp(i) := '8';
        when b"1001" => stmp(i) := '9';
        when b"1010" => stmp(i) := 'a';
        when b"1011" => stmp(i) := 'b';
        when b"1100" => stmp(i) := 'c';
        when b"1101" => stmp(i) := 'd';
        when b"1110" => stmp(i) := 'e';
        when b"1111" => stmp(i) := 'f';
        when others  => stmp(i) := 'x';
      end case;
    end loop;
    return stmp;
  end SLV32HEX;
  -- ---------------------------------------------------------

  -- ---------------------------------------------------------
  -- convert boolean to std_logic
  function BOOL2SL(b: in boolean) return std_logic is
    variable s : std_logic;
  begin
    case b is
      when TRUE   => s := '1';
      when others => s := '0';
    end case;
    return s;
  end;
  -- ---------------------------------------------------------


  -- ---------------------------------------------------------
  -- convert boolean to std_logic
  function SL2BOOL(s: in std_logic) return boolean is
    variable b : boolean;
  begin
    case s is
      when '1'    => b := TRUE;
      when others => b := FALSE;
    end case;
    return b;
  end;
  -- ---------------------------------------------------------


  -- ---------------------------------------------------------
  function SLV2ASCII(s: std_logic_vector(7 downto 0)) return character is
    variable ascii_table : string(1 to 256) := (
      nul, soh, stx, etx, eot, enq, ack, bel, 
      bs,  ht,  lf,  vt,  ff,  cr,  so,  si, 
      dle, dc1, dc2, dc3, dc4, nak, syn, etb, 
      can, em,  sub, esc, fsp, gsp, rsp, usp, 
      
      ' ', '!', '"', '#', '$', '%', '&', ''', 
      '(', ')', '*', '+', ',', '-', '.', '/', 
      '0', '1', '2', '3', '4', '5', '6', '7', 
      '8', '9', ':', ';', '<', '=', '>', '?', 

      '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 
      'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 
      'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 
      'X', 'Y', 'Z', '[', '\', ']', '^', '_', 

      '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 
      'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 
      'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
      'x', 'y', 'z', '{', '|', '}', '~', del,

      c128, c129, c130, c131, c132, c133, c134, c135,
      c136, c137, c138, c139, c140, c141, c142, c143,
      c144, c145, c146, c147, c148, c149, c150, c151,
      c152, c153, c154, c155, c156, c157, c158, c159,

      -- the character code for 160 is there (NBSP), 
      -- but prints as no char 

      ' ', '¡', '¢', '£', '¤', '¥', '¦', '§',
      '¨', '©', 'ª', '«', '¬', '­', '®', '¯',
      '°', '±', '²', '³', '´', 'µ', '¶', '·',
      '¸', '¹', 'º', '»', '¼', '½', '¾', '¿',

      'À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç',
      'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï',
      'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', '×',
      'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'Ý', 'Þ', 'ß',

      'à', 'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç',
      'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï',
      'ð', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', '÷',
      'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ', 'ÿ' );
  begin
    return ascii_table(to_integer(unsigned(s)) + 1); 
  end;
  -- -----------------------------------------------------

  
  end p_WIRES;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


