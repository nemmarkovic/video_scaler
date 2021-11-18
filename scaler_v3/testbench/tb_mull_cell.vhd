
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity tb_mull_cell is
   generic(
      G_REG_IN : natural range 0 to 1 := 1);
   end entity;

architecture bench of tb_mull_cell is

   signal i_clk : std_logic;
   signal i_rst : std_logic;
   signal i_a   : std_logic_vector( 7 downto 0);
   signal i_b   : std_logic_vector( 7 downto 0);
   signal i_d   : std_logic_vector( 7 downto 0);
   signal i_c   : std_logic_vector(48 -1 downto 0);
   signal o_mul1: std_logic_vector(16 -1 downto 0);
   signal o_mul2: std_logic_vector(16 -1 downto 0);
 
   signal s_sgn: signed(16 -1 downto 0);

   constant clk_period : time := 10 ns;

begin

   ea_mul_cell_i : entity work.mul_cell
      generic map (
         G_REG_IN =>  G_REG_IN)
      port map (
         i_clk    => i_clk,
         i_rst    => i_rst,
         i_B      => i_b,
         i_A      => i_a,
         i_D      => i_d,
         i_C      => i_c,
         o_mul1   => o_mul1,
         o_mul2   => o_mul2 );

clk_proc: process
  begin
     i_clk <= '0';
        wait for clk_period/2; 
     i_clk <= '1';
        wait for clk_period/2;
  end process;
  
rst_proc: process
  begin
        i_rst <= '1';
     wait for clk_period *10; 
     wait until rising_edge(i_clk);
        i_rst <= '0';
     wait;
  end process;


  stimulus: process
  begin
    i_a <= (others => '0');
    i_b <= (others => '0');
    i_c <= (others => '0');
    i_d <= (others => '0');
    wait until i_rst = '0';
    i_a <= std_logic_vector(to_unsigned(255,8));
    i_b <= std_logic_vector(to_unsigned(255,8));
    i_d <= std_logic_vector(to_unsigned(255,8));
    i_c <= "000000000000011111110000000010001111111000000001";
    wait;
  end process;

s_sgn <= to_signed(-5, s_sgn'high+1);
end;


