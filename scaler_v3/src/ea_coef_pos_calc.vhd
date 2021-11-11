-----------------------------------------------------------------------------------
-- file name   : ea_coef_pos_calc
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

entity cf_indx_calc is
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
      -- input row/comlmun position valid
      i_valid   : in  std_logic;
      -- input row/comlmun pair
      i_pos      : in  std_logic_vector(11 -1 downto 0);
      i_start_pos: in  std_logic_vector(11 -1 downto 0);
      o_pos_ready: out std_logic;
      o_start_pos_ready: out std_logic;
      o_start_pos : out std_logic_vector(integer(ceil(log2(real(G_PHASE_NUM)))) -1 downto 0);
      -- next module ready to accept filter outputs
      i_ready    : in  std_logic_vector(0 to G_PHASE_NUM -1);
      o_valid    : out std_logic_vector(0 to G_PHASE_NUM -1);
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      o_coef_indx : out t_coef_num);
   end cf_indx_calc;

architecture Behavioral of cf_indx_calc is
   constant c_phase_width : positive := integer(ceil(log2(real(G_PHASE_NUM))));
   constant c_phase_num   : positive := 2**c_phase_width;

   signal r_ipos       : std_logic_vector(11 -1 downto 0);
   signal w_ipos_valid : std_logic;
   signal l_ipos_ready : std_logic;

   signal l_start_opix_pos : std_logic_vector(11 -1 downto 0);
   signal r_start_opix_pos : std_logic_vector(11 -1 downto 0);

   signal l_ipos_as_expected : std_logic_vector(c_phase_num -1 downto 0);
 
   type t_coef_width_array is array (0 to c_phase_num-1) of std_logic_vector(c_phase_width -1 downto 0);
   signal l_coef_num       : t_coef_width_array;
   signal r_coef_num       : t_coef_width_array;

   signal w_cf_num_ready   : std_logic_vector(c_phase_num -1 downto 0);
   signal l_cf_num_ready   : std_logic;

   type t_pix_pos is array (0 to c_phase_num-1) of std_logic_vector(11 -1 downto 0);
   signal w_next_start_pix :  t_pix_pos;
   signal l_mux_data       :  t_pix_pos;
   signal w_expected_pos   :  t_pix_pos;
   
   signal l_cf_num_valid_xor : std_logic_vector(0 to c_phase_num-1);
begin

reg_in_pos : entity work.reg
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => i_pos,
      i_valid => i_valid,
      o_ready => o_ready,
      i_ready => w_ipos_valid,
      o_valid => l_ipos_ready,
      o_data  => r_ipos);

reg_next_out_start_pos : entity work.reg
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => l_start_opix_pos,
      i_valid => or(l_cf_num_valid_xor),
      o_ready => open,
      i_ready => l_cf_num_ready,
      o_valid => open,
      o_data  => r_start_opix_pos);

cf_calc_cell_gen: for cell_num in 0 to c_phase_num -1 generate

   coef_pos_calc_cell_i: entity work.cf_calc_cell
      generic map(
         G_IN_SIZE        => G_IN_SIZE,
         G_OUT_SIZE       => G_OUT_SIZE,
         G_PHASE_NUM      => c_phase_num,
         G_DWIDTH         => G_DWIDTH)
      port map( 
         i_start_pos       => r_start_opix_pos,
         i_cell_num        => std_logic_vector(to_unsigned(cell_num, c_phase_width)),
         --output pixel data 
         o_expected_pos    => w_expected_pos(cell_num),
         o_start_pos       => w_next_start_pix(cell_num),
         o_cf_num          => l_coef_num(cell_num));
 
      --                                             is equal to i_pos
      l_ipos_as_expected(cell_num) <= w_ipos_valid and nor(w_expected_pos(cell_num) xor i_pos);
   end generate;

   --candidate for next pos
   l_mux_data(c_phase_num -1) <= std_logic_vector(unsigned(r_start_opix_pos) + to_unsigned(c_phase_num,11));
cf_start_pos_mux_gen: for cell_num in 1 to c_phase_num -1 generate
   l_cf_num_valid_xor(cell_num-1) <= l_ipos_as_expected(cell_num) xor l_ipos_as_expected(cell_num -1);
   l_mux_data(cell_num-1)         <= w_next_start_pix(cell_num);
   end generate;

cf_start_pos_mux_reg_gen: for cell_num in 0 to c_phase_num -1 generate
   process(i_clk)
   begin
      if rising_edge(i_clk) then
          if l_cf_num_valid_xor(cell_num) then
             l_start_opix_pos <= l_mux_data(cell_num) ;
          elsif cell_num = c_phase_num -1 and l_ipos_as_expected(cell_num) = '1' then
             l_start_opix_pos <= l_mux_data(cell_num) ;
          end if;
      end if;
      end process;
   end generate;

   l_cf_num_ready <= and(w_cf_num_ready);

cf_reg_cf_num_gen: for cell_num in 0 to c_phase_num -1 generate
      -----------------------------------------
      -- register coef index
      -----------------------------------------
      reg_coef_num_i : entity work.reg
         generic map(
            G_DWIDTH => c_phase_width)
         port map(
            i_clk   => i_clk,
            i_rst   => i_rst,
            i_data  => l_coef_num(cell_num),
            i_valid => l_ipos_as_expected(cell_num),
            o_ready => w_cf_num_ready(cell_num),
            i_ready => i_ready(cell_num),
            o_valid => o_valid(cell_num),
            o_data  => o_coef_indx(cell_num)); -- r_coef_num(cell_num));

   end generate;

end Behavioral;
