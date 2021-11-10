-----------------------------------------------------------------------------------
-- file name   : ea_bilinear_flt
-- module      : bilinear_flt
-- author      : Nebojsa Markovic
-- emaill      : mnebojsa.etf@gmail.com
-- date        : september 1st, 2021
-----------------------------------------------------------------------------------
-- description :
--        Based on the input pixel pair, pixel pair possition in the original image
--        and scaling factor gives resultat pixels for the result image
-----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library ieee_proposed;
    use ieee_proposed.fixed_pkg.all;

library common_lib;
    use common_lib.p_common.all;

entity bilinear_flt is
   generic(
      G_IN_SIZE       : integer               :=  446;
      G_OUT_SIZE      : integer               := 2048;
      G_PHASE_NUM     : integer range 2 to C_MAX_PHASE_NUM := 4;
      G_DWIDTH        : integer range 1 to 64 :=    8);
   port ( 
      -- input clk
      i_clk     : in  std_logic;
      -- input reset
      i_rst     : in  std_logic;
      -- ready to filter new data pair
      o_ready   : out std_logic;
      i_valid   : in  std_logic;
      -- input pixel data
      -- pix0
      -- pix1
      -- last  : std_logic; 
      -- eof   : std_logic;
      i_pix      : in  t_in_pix;
      -- input row/comlmun pair
      i_pos      : in  std_logic_vector(11 -1 downto 0);
      -- next module ready to accept filter outputs
      i_ready    : in  std_logic;
      o_valid    : out std_logic_vector(G_PHASE_NUM -1 downto 0);
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      o_pix      : out t_dinfo);
   end bilinear_flt;


architecture Behavioral of bilinear_flt is

begin

------------------------------------------------------------------------------------
-- output assignment
------------------------------------------------------------------------------------

gen_out_unused_pix: for i in G_PHASE_NUM to C_MAX_PHASE_NUM generate
      o_pix.data(i) <= (others => '0');
      o_pix.last(i) <= '0';
      o_pix.sof(i)  <= '0';
   end generate;

end Behavioral;

