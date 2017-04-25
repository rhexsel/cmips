
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- VGA controller
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity vga is
  port(rst     : in  std_logic;
       clk     : in  std_logic;
       VGA_R, VGA_G, VGA_B : out reg4;
       VGA_HS, VGA_VS :      out std_logic);
end entity vga;

architecture behavioral of vga is

  signal address :       reg15;
  signal address_sig :   reg15 := (others => '0');
  signal Pixels, Linha : reg11;
  signal RGB, RGB_mem  : reg12;
  signal video_on: std_logic;
  signal resetn  : std_logic;

  component memoriavideo
    port(address : IN  STD_LOGIC_VECTOR (14 DOWNTO 0);
          clock  : IN  STD_LOGIC;
          q      : OUT STD_LOGIC_VECTOR (11 DOWNTO 0));
  end component memoriavideo;

  component VGA_controller
    port(rst, clk           : in  std_logic;
         Video_on_o         : out std_logic;
         Pixels_o, Linha_o  : out reg11;
         VGA_HS_o, VGA_VS_o : out std_logic);
  end component VGA_controller;


begin

  U_memoriavideo : memoriavideo port map (
    address => address,
    clock   => clk,
    q       => RGB_mem);

  U_sincronismo : sincronismo port map (
    clk => clk,
    rst => rst,
    Video_on_o => Video_on,
    Pixels_o   => Pixels,
    Linha_o    => Linha,
    VGA_HS_o   => VGA_HS,
    VGA_VS_o   => VGA_VS);

  -- Processo que controla as saidas RGB
  U_VGA_RGB: process (clk, rst)
  begin
    if rst = '0' then
      VGA_R <= "0000";
      VGA_G <= "0000";
      VGA_B <= "0000";
    elsif rising_edge (clk) then
      if (Video_on = '0') Then
        VGA_R <= "0000";
        VGA_G <= "0000";
        VGA_B <= "0000";
      else
        VGA_R <= RGB(11 downto 8);
        VGA_G <= RGB( 7 downto 4);
        VGA_B <= RGB( 3 downto 0);
      end if;
    end if;
  end Process VGA_RGB;
        

  -- Enderecamento da memoria
  Enderecamento: process(Linha, Pixels)
  begin
    -- Enviando enderecos para a memoria. O decremento na linha e na coluna
    -- serve para indicar o endereco correto, pois a imagem esta deslocada
    Address <= (Linha(6 downto 0)- "0101111") & (Pixels(7 downto 0) - "10111111");
    -- Nos pixels onde nao tem imagem serao preenchido com a cor azul
    RGB <= "000001010110";
    if (Pixels > 191 and Pixels < 446) and (Linha >175 and linha < 302) then
      -- O numeros definem a regiao onde a imagem sera mostrada
      -- (a imagem armazenada na memoria eh de 256 x 128)
      RGB <= RGB_mem;
    end if;
  end Process Enderecamento;


end behavioral;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.p_wires.all;

entity VGA_controller is
  Generic(ADDR_WIDTH: integer := 12;
          DATA_WIDTH: integer := 1);
  port(signal rst, clk :      in  std_logic;
       signal video_on :      out std_logic;
       signal Pixels,Linha :  out std_logic_vector(10 downto 0);
       signal Horiz_sync,Vert_sync : out std_logic);
end VGA_controller;

architecture behavior of VGA_controller is

  signal cont_x, cont_y: std_logic_vector(10 Downto 0);

  -- valor maximo da variavel cont_x,
  -- valor encontrado a partir da analise dos tempos do sincronismo horizontal
  constant H_max : reg11 := CONV_STD_LOGIC_VECTOR(1588,11); 

  -- valor maximo da variavel cont_y,
  -- valor encontrado a partir da analise dos tempos do sincronismo vertical
  constant V_max : reg11 := CONV_STD_LOGIC_VECTOR(528,11); 

  signal video_on_H, video_on_V: std_logic;

begin           

  video_on <= video_on_H and video_on_V;

  --Generate Horizontal and Vertical Timing Signals for Video Signal
  VIDEO_DISPLAY: Process (Clock, Reset)
  begin
    
    if rst = '0' then
      cont_x     <= "00000000000";
      cont_y     <= "00000000000";
      Video_on_H <= '0';
      Video_on_V <= '0';
    elsif clk'event and clk = '1' then

      -- cont_x conta os pixels
      -- (espaco utilizado+espaco nao utilizado +
      --    tempo extra para o sinal de sincronismo)
      --
      --  Contagem de Pixels:
      --           			  <-H Sync->
      --   ------------------------------------__________
      --   0        511 -espaco nao utilizado-  1400     
      
      
      if (cont_x >= H_max) then
        cont_x <= "00000000000";
      else
        cont_x <= cont_x + "00000000001";
      end if;

      -- O Horiz_Sync deve permanecer em nivel logico alto por 27,06 us
      -- entao em baixo por 3,77 us

			
      if (cont_x <= 1494) and (cont_x >= 1306) then
        Horiz_Sync <= '0';
      else
        Horiz_Sync <= '1';
      end if;
        
      -- Ajusta o tempo do Video_on_H
      if (cont_x <= 1258) then  
        video_on_H <= '1';
      else
        video_on_H <= '0';
      end if;

      --  Contagem de linhas...
      -- Linha conta as linhas de pixels
      -- (127 + tempo extra para sinais de sincronismo)
      --
      --  <--128 linhas utilizadas -->                  ->V Sync<-
      --  -----------------------------------------------_______------------
      --  0                          127           495-494               528
      --

      if (cont_y >= V_max) and (cont_x >= 736) then
        cont_y <= "00000000000";
      elsif (cont_x = H_Max) then
        cont_y <= cont_y + "00000000001";
      end if;

      -- Generate Vertical Sync Signal
      if (cont_y <= 496) and (cont_y >= 495) then   -- (Trocar por (Linha = 494 or linha = 495) ?)
        Vert_Sync <= '0';
      else
        Vert_Sync <= '1';
      end if;
          
        -- Ajusta o tempo do Video_on_V
      if (cont_y <= 479) then
        video_on_V <= '1';
      else
        video_on_V <= '0';
      end if;

    end if; -- Termina o IF do Reset

    Linha  <= cont_y;
    Pixels <= "0" & cont_x(10 downto 1);
    -- Usa cont_x descartandando o ultimo bit para dividir por 2 a frequencia
    -- De forma com que o clock seja semelhante ao do monitor.

  end process VIDEO_DISPLAY;

end behavior;

