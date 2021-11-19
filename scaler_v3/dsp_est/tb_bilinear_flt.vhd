-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity tb_bilinear_flt is
     generic(
        G_IN_WIDTH      : positive              :=  3;
        G_OUT_WIDTH     : positive              := 10;
        G_PHASE_NUM     : integer               :=  4);
   end;

architecture bench of tb_bilinear_flt is

  signal i_clk: std_logic;
  signal i_rst: std_logic;
  signal o_ready: std_logic;
  signal i_valid: std_logic;
  signal i_pix0: std_logic_vector(8-1 downto 0);
  signal i_pix1: std_logic_vector(8-1 downto 0);
  signal i_position: std_logic_vector(11 -1 downto 0);
  signal o_pix0: std_logic_vector(16-1 downto 0);
  signal o_pix1: std_logic_vector(16-1 downto 0);

   constant clk_period : time := 10 ns;
begin

  -- Insert values for generic parameters !!
uut_bilinear_flt_i: entity work.bilinear_flt
   generic map ( 
      G_IN_WIDTH  => G_IN_WIDTH,
      G_OUT_WIDTH => G_OUT_WIDTH,
      G_PHASE_NUM => G_PHASE_NUM )
   port map (
      i_clk       => i_clk,
      i_rst       => i_rst,
      o_ready     => o_ready,
      i_valid     => i_valid,
      i_pix0      => i_pix0,
      i_pix1      => i_pix1,
      i_pos       => i_position,
      o_pix0      => o_pix0,
      o_pix1      => o_pix1 );

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
  
      i_pix0      <= "00000010";
      i_pix1      <= "00000010";
      i_position  <= (others => '0');

    wait;
  end process;


end;
