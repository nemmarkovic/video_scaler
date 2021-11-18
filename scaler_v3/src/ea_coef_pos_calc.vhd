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
      G_IN_SIZE       : integer               :=  256;
      G_OUT_SIZE      : integer               := 1280;
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
      i_ready      : in  std_logic;
      o_cf         : out t_cf_indx_array);
   end cf_indx_calc;

architecture Behavioral of cf_indx_calc is
   constant c_phase_width : positive := clog2(G_PHASE_NUM);
   constant c_phase_num   : positive := 2**c_phase_width;

   -- cf index calc cell signals

   signal l_mux_sel          : std_logic_vector(c_phase_num -1 downto 0);
   signal l_ipos_as_expected : std_logic_vector(c_phase_num    downto 0);
 
   type t_cf_width_array is array (0 to c_phase_num) of std_logic_vector(c_phase_width -1 downto 0);
   signal l_cf_indx        : t_cf_width_array;

   type t_pix_pos is array (0 to c_phase_num) of std_logic_vector(11 -1 downto 0);
   signal w_next_start_pix :  t_pix_pos;
   signal w_expected_pos   :  t_pix_pos;

begin
-----------------------------------------
-- combinational logic between two reg stages
-----------------------------------------

cf_calc_cell_gen: for gen_cell_num in 0 to c_phase_num generate
      type t_cell_num_array is array (0 to c_phase_num) of std_logic_vector(c_phase_width downto 0);
      signal l_cell_num        : t_cell_num_array;
   begin
   -----------------------------------------
   -- coef calculate cell
   -----------------------------------------
   l_cell_num(gen_cell_num) <= std_logic_vector(to_unsigned(gen_cell_num, c_phase_width +1));
   coef_pos_calc_cell_i: entity work.cf_calc_cell
      generic map(
         G_IN_SIZE        => G_IN_SIZE,
         G_OUT_SIZE       => G_OUT_SIZE,
         G_PHASE_NUM      => c_phase_num,
         G_DWIDTH         => G_DWIDTH)
      port map( 
         i_start_pos       => i_start_pos,
         i_cell_num        => l_cell_num(gen_cell_num),
         --output pixel data 
         o_expected_pos    => w_expected_pos(gen_cell_num),
         o_start_pos       => w_next_start_pix(gen_cell_num),
         o_cf_num          => l_cf_indx(gen_cell_num));

      --                                             is equal to i_pos
      l_ipos_as_expected(gen_cell_num) <= nor(w_expected_pos(gen_cell_num) xor i_pos) and i_valid;
   end generate;


   process(all)
      variable vl_mux_sel : std_logic_vector(c_phase_num -1 downto 0);
   begin
      vl_mux_sel := (others => '0');
      cf_xor_gen: for gen_cell_num in 1 to c_phase_num loop
         if (l_ipos_as_expected(gen_cell_num) xor l_ipos_as_expected(gen_cell_num -1)) = '1' then
            vl_mux_sel(gen_cell_num -1) := '1';
         end if;
      end loop;
      l_mux_sel <= vl_mux_sel;

   end process;

-----------------------------------------
-- outputs assignment
-----------------------------------------
   o_ready           <= i_ready;
   o_pos_ready       <= or(l_mux_sel(c_phase_num -1 downto 0)) or (nor(l_ipos_as_expected) and i_valid);
   o_start_pos_ready <= or(l_mux_sel(c_phase_num -1 downto 0)) or (l_ipos_as_expected(c_phase_num) and i_valid);

--   process(w_next_start_pix, i_rst, l_mux_sel)
   process(all)
   begin
--      if rising_edge(i_clk) then
         if i_rst = '1' then
            o_start_pos       <= (others => '0');
         else
            o_start_pos       <= (others => '0');

            if and(l_ipos_as_expected) = '1' then
               o_start_pos       <= w_next_start_pix(c_phase_num);
            else
               for cell_num_gen in 0 to c_phase_num -1 loop
                  if l_mux_sel(cell_num_gen) = '1' then
                     o_start_pos       <= w_next_start_pix(cell_num_gen+1);
                  end if;
               end loop;          
            end if;
         end if;
--      end if;
   end process;


gf: for cell_num_gen in 0 to c_phase_num -1 generate
   o_cf(cell_num_gen).cf_indx       <= l_cf_indx(cell_num_gen);
   o_cf(cell_num_gen).cf_indx_valid <= i_valid and l_ipos_as_expected(cell_num_gen);
end generate;
end Behavioral;
