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
      G_TYPE          : string                := "V"; --"V", "H"
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
--      o_start_pos : out std_logic_vector(11 -1 downto 0);
      o_ready   : out std_logic;
      -- input pixel data
      -- pix0
      -- pix1
      -- last  : std_logic; 
      -- eof   : std_logic;
      i_pix      : in  t_in_pix;
      -- next module ready to accept filter outputs
      i_ready    : in  std_logic;
      o_bank_sel : out std_logic_vector(11 downto 0);
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      o_pix      : out t_out_pix_array);
   end bilinear_flt;


architecture Behavioral of bilinear_flt is
   signal w_cf_calc_indx_valid_i           : std_logic;
   signal w_cf_calc_indx_ready_o           : std_logic;
   signal w_cf_calc_indx_pix_i             : t_in_pix;
   signal w_cf_calc_indx_pix_o             : t_in_pix;
   signal w_cf_calc_indx_ipos_ready_o      : std_logic;
   signal w_cf_calc_indx_start_pos_valid_o : std_logic;
   signal w_cf_calc_indx_start_pos_ready_o : std_logic;
   signal w_cf_calc_indx_indx_ready_i      : std_logic;
   signal w_cf_calc_indx_cf_o              : t_cf_indx_array;

   signal w_res_pix_calc_cf_i              : t_cf_indx_array;
   signal w_res_pix_calc_pix_i             : t_in_pix;
   signal w_res_pix_calc_ready_o           : std_logic;
   signal w_res_pix_calc_pix_valid_i       : std_logic;
   signal w_res_pix_calc_pix_o             : t_out_pix_array;
   signal w_res_pix_calc_bank_sel_o        : std_logic_vector(11  downto 0);
   -- infering latch - fix this !!!!!!!!!!!!!!!!!!!!!!!!!!
   signal i_start_pos_valid_reg : std_logic;
   signal i_start_pos_reg       : std_logic_vector(11 -1 downto 0);

   signal r_start : std_logic;
   signal l_start_pos_reg : std_logic_vector(11-1 downto 0);
   signal r_start_pos_reg : std_logic_vector(11-1 downto 0);
begin

-----------------------------------------
-- coeficient index calculation module
-----------------------------------------
   w_cf_calc_indx_pix_i        <= i_pix;
   w_cf_calc_indx_valid_i      <= i_pix.valid;
   w_cf_calc_indx_indx_ready_i <= w_res_pix_calc_ready_o;

cf_indx_calc_i: entity work.cf_indx_calc
   generic map(
      G_IN_SIZE         => G_IN_SIZE,
      G_OUT_SIZE        => G_OUT_SIZE,
      G_PHASE_NUM       => G_PHASE_NUM,
      G_DWIDTH          => G_DWIDTH)
   port map( 
      i_clk             => i_clk,
      i_rst             => i_rst,
      o_ready           => w_cf_calc_indx_ready_o,
      i_pix             => w_cf_calc_indx_pix_i,
      i_ready           => w_cf_calc_indx_indx_ready_i,
      o_pix             => w_cf_calc_indx_pix_o,
      o_cf              => w_cf_calc_indx_cf_o);

-----------------------------------------
-- resulting pix calculation - filtering
-----------------------------------------
   w_res_pix_calc_cf_i        <= w_cf_calc_indx_cf_o;
   w_res_pix_calc_pix_i       <= w_cf_calc_indx_pix_o;

res_pix_calc_i: entity work.res_pix_calc
   generic map(
      G_TYPE      => G_TYPE,
      G_IN_SIZE   => G_IN_SIZE,
      G_OUT_SIZE  => G_OUT_SIZE,
      G_PHASE_NUM => G_PHASE_NUM,
      G_DWIDTH    => G_DWIDTH)
   port map(
      i_clk       => i_clk,
      i_rst       => i_rst,

      o_ready     => w_res_pix_calc_ready_o,
      i_pix       => w_res_pix_calc_pix_i,
      i_cf        => w_res_pix_calc_cf_i,
      i_ready     => i_ready,
      o_pix       => w_res_pix_calc_pix_o,
      o_bank_sel  => w_res_pix_calc_bank_sel_o);
      
------------------------------------------------------------------------------------
-- output assignment
------------------------------------------------------------------------------------
   o_pix        <= w_res_pix_calc_pix_o;
   o_ready      <= w_cf_calc_indx_ready_o;
   o_bank_sel   <= w_res_pix_calc_bank_sel_o;
end Behavioral;

