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
      o_start_pos : out std_logic_vector(11 -1 downto 0);
      o_ready   : out std_logic;
      -- input pixel data
      -- pix0
      -- pix1
      -- last  : std_logic; 
      -- eof   : std_logic;
      i_pix      : in  t_in_pix;
      -- next module ready to accept filter outputs
      i_ready    : in  std_logic;
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      o_pix      : out t_out_pix_array);
   end bilinear_flt;


architecture Behavioral of bilinear_flt is

   signal w_strt_reg_data_i      : std_logic_vector(11 -1 downto 0);
   signal w_strt_reg_valid_i     : std_logic;
   signal w_strt_reg_ready_o     : std_logic;
   signal w_strt_reg_ready_i     : std_logic;
   signal w_strt_reg_valid_o     : std_logic;
   signal w_strt_reg_data_o      : std_logic_vector(11 -1 downto 0);

   signal w_cf_calc_indx_valid_i           : std_logic;
   signal w_cf_calc_indx_ready_o           : std_logic;
   signal w_cf_calc_indx_start_pos_valid_i : std_logic;
   signal w_cf_calc_indx_start_pos_ready_i : std_logic;
   signal w_cf_calc_indx_pos_i             : std_logic_vector(11 -1 downto 0);
   signal w_cf_calc_indx_start_pos_i       : std_logic_vector(11 -1 downto 0);
   signal w_cf_calc_indx_start_pos_o       : std_logic_vector(11 -1 downto 0);
   signal w_cf_calc_indx_ipos_ready_o      : std_logic;
   signal w_cf_calc_indx_start_pos_valid_o : std_logic;
   signal w_cf_calc_indx_start_pos_ready_o : std_logic;
   signal w_cf_calc_indx_indx_ready_i      : std_logic;
   signal w_cf_calc_indx_cf_o              : t_cf_indx_array;

   signal w_res_pix_calc_cf_i              : t_cf_indx_array;
   signal w_res_pix_calc_pix_i             : t_in_pix;
   signal r_res_pix_calc_pix_i             : t_in_pix;
   signal w_res_pix_calc_ready_o           : std_logic;
   signal w_res_pix_calc_pix_valid_i       : std_logic;
   signal w_res_pix_calc_pix_o             : t_out_pix_array;

   -- infering latch - fix this !!!!!!!!!!!!!!!!!!!!!!!!!!
   signal i_start_pos_valid_reg : std_logic;
   signal i_start_pos_reg       : std_logic_vector(11 -1 downto 0);
begin

-----------------------------------------
-- coeficient index calculation module
-----------------------------------------
   w_strt_reg_data_i  <= w_cf_calc_indx_start_pos_o;
   w_strt_reg_ready_i <= w_cf_calc_indx_start_pos_ready_o;
   w_strt_reg_valid_i <= w_cf_calc_indx_start_pos_valid_o;

reg_start_pos: entity work.reg_hs
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk    => i_clk,
      i_rst    => i_rst,
      i_data   => i_start_pos_reg, --w_strt_reg_data_i,
      i_valid  => i_start_pos_valid_reg, --w_strt_reg_valid_i,
      o_ready  => w_strt_reg_ready_o,
      i_ready  => w_strt_reg_ready_i,
      o_valid  => w_strt_reg_valid_o,
      o_data   => w_strt_reg_data_o);


process(all)
   variable v_start : std_logic;
begin
   if i_rst = '1' then
      i_start_pos_reg       <= (others => '0');
      i_start_pos_valid_reg <= '0';
      v_start               := '0';
   else 
      if v_start = '0' then
         i_start_pos_valid_reg <= '1';
         i_start_pos_reg       <= (others => '0');
         if o_ready = '1' then
            v_start               := '1';
         end if;
      else
         i_start_pos_reg       <= w_strt_reg_data_i;
         i_start_pos_valid_reg <= w_strt_reg_valid_i;
      end if;
   end if;
end process;

-----------------------------------------
-- coeficient index calculation module
-----------------------------------------
   w_cf_calc_indx_pos_i        <= i_pix.pos;
   w_cf_calc_indx_valid_i      <= i_pix.valid;

   w_cf_calc_indx_start_pos_valid_i <= w_strt_reg_valid_o;
   w_cf_calc_indx_start_pos_ready_i <= w_strt_reg_ready_o;
   w_cf_calc_indx_start_pos_i  <= w_strt_reg_data_o;
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
      i_valid           => w_cf_calc_indx_valid_i,
      o_ready           => w_cf_calc_indx_ready_o,
      i_pos             => w_cf_calc_indx_pos_i,
      i_start_pos_valid => w_cf_calc_indx_start_pos_valid_i,
      o_start_pos_ready => w_cf_calc_indx_start_pos_ready_o,
      i_start_pos       => w_cf_calc_indx_start_pos_i,

      o_start_pos_valid => w_cf_calc_indx_start_pos_valid_o,
      i_start_pos_ready => w_cf_calc_indx_start_pos_ready_i,

      o_start_pos       => w_cf_calc_indx_start_pos_o,
      i_ready           => w_cf_calc_indx_indx_ready_i,
      o_cf              => w_cf_calc_indx_cf_o);

-----------------------------------------
-- resulting pix calculation - filtering
-----------------------------------------
   w_res_pix_calc_cf_i        <= w_cf_calc_indx_cf_o;
   w_res_pix_calc_pix_i       <= i_pix;
   process(i_clk)
      variable v_start_pos : std_logic_vector(11 -1 downto 0);
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_res_pix_calc_pix_i <= t_in_pix_rst;
   o_start_pos  <= (others => '0');
   v_start_pos  := (others => '0');
         else
            r_res_pix_calc_pix_i <= w_res_pix_calc_pix_i;
   o_start_pos  <= v_start_pos;
   v_start_pos  := w_strt_reg_data_o;
         end if;
      end if;
   end process;

res_pix_calc_i: entity work.res_pix_calc
   generic map(
      G_IN_SIZE   => G_IN_SIZE,
      G_OUT_SIZE  => G_OUT_SIZE,
      G_PHASE_NUM => G_PHASE_NUM,
      G_DWIDTH    => G_DWIDTH)
   port map(
      i_clk       => i_clk,
      i_rst       => i_rst,

      o_ready     => w_res_pix_calc_ready_o,
      i_pix       => r_res_pix_calc_pix_i,
      i_cf        => w_res_pix_calc_cf_i,
      i_ready     => i_ready,
      o_pix       => w_res_pix_calc_pix_o);
      
------------------------------------------------------------------------------------
-- output assignment
------------------------------------------------------------------------------------
   o_pix        <= w_res_pix_calc_pix_o;
   o_ready      <= w_cf_calc_indx_ready_o;

end Behavioral;

