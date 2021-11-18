-----------------------------------------------------------------------------------
-- file name   : res_pix_calc
-- module      : bilinear_flt
-- author      : Nebojsa Markovic
-- emaill      : mnebojsa.etf@gmail.com
-- date        : november 10th, 2021
-----------------------------------------------------------------------------------
-- description :
-----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library common_lib;
    use common_lib.p_common.all;

entity res_pix_calc is
   generic(
      G_IN_SIZE       : integer               :=  256;
      G_OUT_SIZE      : integer               := 1280;
      G_PHASE_NUM     : integer range 2 to C_MAX_PHASE_NUM := 4;
      G_DWIDTH        : integer range 1 to 64 :=    8);
   port ( 
      --! input clk
      i_clk       : in  std_logic;
      --! input reset
      i_rst       : in  std_logic;

      o_ready     : out std_logic;
      -- input pixel data
      -- pix0
      -- pix1
      -- last  : std_logic; 
      -- eof   : std_logic;
      i_pix       : in  t_in_pix;

      i_cf        : in  t_cf_indx_array;
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      o_pix      : out t_out_pix);
   end res_pix_calc;

architecture Behavioral of res_pix_calc is

begin

filter_cell_i: entity work.filter_cell
   generic map(
      G_DWIDTH    => G_DWIDTH,
      G_PRESISION     : integer range 1 to 64 :=    6);
   port ( 
      i_clk    : in  std_logic;
      i_rst    : in  std_logic;
      i_valid  : in  std_logic;
      i_pix    : in  t_dinfo(data(0 to 1)(G_MANTISA_WIDTH -1 downto 0));
      i_SFY    : in  sfixed(C_SF_WIDTH -1 downto -G_PRESISION);
      i_colmun : in  std_logic_vector(11 -1 downto 0);
      i_ocolmun: in  std_logic_vector(11 -1 downto 0);
      o_pix    : out t_dinfo(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));
      o_valid  : out std_logic);
   end filter_cell;
end Behavioral;
