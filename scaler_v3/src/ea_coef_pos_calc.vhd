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
      G_IN_SIZE       : integer               :=  4;
      G_OUT_SIZE      : integer               := 16;
      G_PHASE_NUM     : integer range 2 to C_MAX_PHASE_NUM := 4;
      G_DWIDTH        : integer range 1 to 64 :=    8);
   port ( 
      --! input clk
      i_clk       : in  std_logic;
      --! input reset
      i_rst       : in  std_logic;
      --! input row/comlmun position valid
      i_valid     : in  std_logic;
      --! ready
      o_ready     : out std_logic;
      --! input row/comlmun pair
      i_pos       : in  std_logic_vector(11 -1 downto 0);
      --! current output pix possition in row/colmun for V/H filter
      i_start_pos : in  std_logic_vector(11 -1 downto 0);
      --! 
      o_pos_ready : out std_logic;
      o_start_pos_ready: out std_logic;
      o_start_pos : out std_logic_vector(11 -1 downto 0);
      -- next module ready to accept filter outputs
      i_ready_indx : in  std_logic_vector(0 to G_PHASE_NUM -1);
      o_valid_indx : out std_logic_vector(0 to G_PHASE_NUM -1);
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      o_coef_indx : out t_coef_num);
   end cf_indx_calc;

architecture Behavioral of cf_indx_calc is
   constant c_phase_width : positive := clog2(G_PHASE_NUM);
   constant c_phase_num   : positive := 2**c_phase_width;

   -- cf index calc cell signals
   signal w_ready            : std_logic;
   signal w_valid_ipos       : std_logic;
   signal w_valid_start_pos  : std_logic;
   signal w_ipos             : std_logic_vector(11 -1 downto 0);
   signal w_start_pos        : std_logic_vector(11 -1 downto 0);

   signal l_mux_sel          : std_logic_vector(c_phase_num -1 downto 0);
   signal l_ipos_as_expected : std_logic_vector(c_phase_num    downto 0);
 
   type t_cf_width_array is array (0 to c_phase_num) of std_logic_vector(c_phase_width -1 downto 0);
   signal l_cf_indx        : t_cf_width_array;

   signal w_cf_num_ready   : std_logic_vector(c_phase_num -1 downto 0);

   type t_pix_pos is array (0 to c_phase_num) of std_logic_vector(11 -1 downto 0);
   signal w_next_start_pix :  t_pix_pos;
   signal w_expected_pos   :  t_pix_pos;
   
   -- output reg signals
   signal w_coef_indx      : t_coef_num;
   signal w_valid_indx     : std_logic_vector(0 to G_PHASE_NUM -1);
begin

-----------------------------------------
-- register coef index
-----------------------------------------
reg_coef_num_i : entity work.reg
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => i_pos,
      i_valid => i_valid,
      o_ready => w_ready,
      i_ready => and(w_cf_num_ready),
      o_valid => w_valid_ipos,
      o_data  => w_ipos);


reg_next_st_pos_num_i : entity work.reg
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => i_start_pos,
      i_valid => i_valid,
      o_ready => open, --w_ready,
      i_ready => and(w_cf_num_ready),
      o_valid => w_valid_start_pos,
      o_data  => w_start_pos);




cf_calc_cell_gen: for gen_cell_num in 0 to c_phase_num generate

   coef_pos_calc_cell_i: entity work.cf_calc_cell
      generic map(
         G_IN_SIZE        => G_IN_SIZE,
         G_OUT_SIZE       => G_OUT_SIZE,
         G_PHASE_NUM      => c_phase_num,
         G_DWIDTH         => G_DWIDTH)
      port map( 
         i_start_pos       => w_start_pos,
         i_cell_num        => std_logic_vector(to_unsigned(gen_cell_num, c_phase_width +1)),
         --output pixel data 
         o_expected_pos    => w_expected_pos(gen_cell_num),
         o_start_pos       => w_next_start_pix(gen_cell_num),
         o_cf_num          => l_cf_indx(gen_cell_num));

      --                                             is equal to i_pos
      l_ipos_as_expected(gen_cell_num) <= nor(w_expected_pos(gen_cell_num) xor w_ipos) and w_valid_ipos;
   end generate;


   process(all)
   begin
      l_mux_sel <= (others => '0');
      cf_xor_gen: for gen_cell_num in 1 to c_phase_num loop
         if (l_ipos_as_expected(gen_cell_num) xor l_ipos_as_expected(gen_cell_num -1)) = '1' then
            l_mux_sel(gen_cell_num -1) <= '1';
         end if;
      end loop; 
   end process;


cf_reg_cf_num_gen: for gen_cell_num in 0 to c_phase_num -1 generate
      -----------------------------------------
      -- register coef index
      -----------------------------------------
      reg_coef_num_i : entity work.reg
         generic map(
            G_DWIDTH => c_phase_width)
         port map(
            i_clk   => i_clk,
            i_rst   => i_rst,
            i_data  => l_cf_indx(gen_cell_num),
            i_valid => w_valid_ipos and l_ipos_as_expected(gen_cell_num),
            o_ready => w_cf_num_ready(gen_cell_num),
            i_ready => i_ready_indx(gen_cell_num),
            o_valid => w_valid_indx(gen_cell_num),
            o_data  => w_coef_indx(gen_cell_num));

   end generate;


-----------------------------------------
-- outputs assignment
-----------------------------------------
   o_ready           <= w_ready;
   o_pos_ready       <= or(l_mux_sel(c_phase_num -1 downto 0));
   o_start_pos_ready <= w_valid_ipos and l_ipos_as_expected(c_phase_num);

   process(all)
   begin
      --if rising_edge(i_clk) then
         o_start_pos       <= (others => '0');
         for cell_num_gen in 0 to c_phase_num -1 loop
            if l_mux_sel(cell_num_gen) = '1' then
               o_start_pos       <= w_next_start_pix(cell_num_gen+1);
            end if;
         end loop;
      --end if;
   end process;


   o_valid_indx      <= w_valid_indx;
   o_coef_indx       <= w_coef_indx;

end Behavioral;
