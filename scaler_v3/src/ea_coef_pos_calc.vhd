--gen_sh: if G_DWIDTH = 8 generate
--   signal r_reg_data : std_logic_vector(G_DWIDTH -1 downto 0);
--   signal l_reg_data : std_logic_vector(G_DWIDTH -1 downto 0);
--
--   signal l_dvalid   : std_logic;
--   signal r_dvalid   : std_logic;
--
--   signal r_dready   : std_logic;
--   signal l_dready   : std_logic;
--begin
--comb_proc: process(all)
--      variable vl_valid    : std_logic;
--      variable vl_data     : std_logic_vector(G_DWIDTH -1 downto 0);
--      variable vl_dready   : std_logic;
--   begin
--      vl_data       := r_reg_data;
--      vl_valid      := r_dvalid;
--      vl_dready     := r_dready;
--
--      if i_rst = '0' then
--      -- side i_ready i_valid
--      if (r_dvalid and not(i_ready)) = '1' then
--         vl_dready := '0';
--      elsif (r_dvalid and i_ready and i_valid) = '1' then
--         vl_dready := '1';
--      elsif not(r_dvalid) = '1' then
--         vl_dready := '1';
--      end if;
--
--      if (i_valid and not(r_dvalid)) = '1' then
--         vl_valid  := '1';
--         vl_data   := i_data; 
--      elsif (i_valid and r_dvalid and i_ready) = '1' then
--         vl_valid  := '1';
--         vl_data   := i_data;
--      elsif (not(i_valid) and i_ready) = '1' then
--         vl_valid  := '0';
--      end if;
--      end if;
--
--      l_reg_data     <= vl_data;
--      l_dvalid       <= vl_valid;
--      l_dready       <= vl_dready;
--   end process;
--
--
--reg_proc: process(i_clk)
--   begin
--      if rising_edge(i_clk) then
--         if i_rst = '1' then
--            r_reg_data <= (others => '0');
--            r_dvalid   <= '0';
--            r_dready   <= '0';
--         else
--            r_reg_data <= l_reg_data;
--            r_dvalid   <= l_dvalid;
--            r_dready   <= l_dready;
--         end if;
--      end if;
--   end process;
--end generate;

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
      G_TYPE          : string                := "V"; --"V", "H"
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
      i_pix       : in  t_in_pix;
      --! ready
      o_ready     : out std_logic;
      -- next module ready to accept filter outputs
      i_ready      : in  std_logic;
      o_pix        : out t_in_pix;
      o_cf         : out t_cf_indx_array);
   end cf_indx_calc;

architecture Behavioral of cf_indx_calc is
   constant c_phase_width : positive := clog2(G_PHASE_NUM);
   constant c_phase_num   : positive := 2**c_phase_width;

   -- cf index calc cell signals
   signal l_mux_sel          : std_logic_vector(c_phase_num -1 downto 0);
   signal l_ipos_as_expected : std_logic_vector(0 to c_phase_num);
   signal r_ipos_as_expected : std_logic_vector(0 to c_phase_num);
 
   type t_cf_width_array is array (0 to c_phase_num) of std_logic_vector(c_phase_width -1 downto 0);
   signal l_cf_indx        : t_cf_width_array;

   type t_pix_pos is array (0 to c_phase_num) of std_logic_vector(11 -1 downto 0);
   signal w_next_start_pix :  t_pix_pos;
   signal w_expected_pos   :  t_pix_pos;

   -- sync signals
   signal l_ipos_ready : std_logic;
   signal r_ipos_ready : std_logic;

   signal l_ipix       : t_in_pix;
   signal r_ipix       : t_in_pix;


   signal l_start_pos_ready : std_logic;
   signal r_start_pos_ready : std_logic;

   signal l_start_pos_valid : std_logic;
   signal r_start_pos_valid : std_logic;

   signal l_start_pos  : std_logic_vector(11 -1 downto 0);
   signal r_start_pos  : std_logic_vector(11 -1 downto 0);

   signal r_indx_ready : std_logic;
   signal l_indx_ready : std_logic;
   
   signal l_indx_valid : std_logic_vector(0 to c_phase_num -1);
--   signal r_indx_valid : std_logic_vector(0 to c_phase_num -1);
begin
----------------------------------------------------
-- o_ready update process
-- the module is ready to take a new pix pair if
-- * i_pix is not as expected on any calc cell and
-- * the next stage is ready
-----------------------------------------------------
ipos_ready_proc: process(all)
    begin
      l_ipix          <= r_ipix;
      l_ipos_ready    <= r_ipos_ready;
--      l_ipos_ready    <= '0';
      -- ready for new i_pos(and/or a new pix pair)
      -- when l_ipos_as_expected is equal to '1' on all cells, it means 
      -- current pix pair is not exploited - more outputs should be generated than
      -- PHASE_CELLS is available - at least one more cycle needed => not ready for
      -- new input pix
      -- if at least one cell gives back info i_pos not as expected and next step is
      -- ready to accept the results, the module is ready for new pix par
      if ((nand(l_ipos_as_expected)) and l_start_pos_ready) = '1' then
         l_ipos_ready <= '1';  
         l_ipix.valid <= '0';
      elsif and(l_ipos_as_expected) = '1' then
         l_ipos_ready <= '0';
      end if;

      if i_pix.valid = '1' and l_ipos_ready = '1' then
         l_ipix       <= i_pix;
      end if;
   end process;

----------------------------------------------------
-- register ipos and valid signal
-----------------------------------------------------
reg_proc: process(i_clk)
      variable v_start : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_ipos_ready <= '0';
            v_start      := '0';

            r_ipos_as_expected <= (others => '0');
            r_ipix             <= t_in_pix_rst;
         else
            if v_start = '0' then
               r_ipos_ready <= i_ready;
               if i_ready = '1' then
                  v_start      := '1';              
               end if;
            else
               r_ipos_ready <= l_ipos_ready;
            end if;

--            if l_ipos_ready = '1' then
               r_ipix       <= l_ipix;
--            end if;
            r_ipos_as_expected <= l_ipos_as_expected;
         end if;
      end if;
   end process;

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
         i_start_pos       => r_start_pos,
         i_cell_num        => l_cell_num(gen_cell_num),
         --output pixel data 
         o_expected_pos    => w_expected_pos(gen_cell_num),
         o_start_pos       => w_next_start_pix(gen_cell_num),
         o_cf_num          => l_cf_indx(gen_cell_num));

      -- is equal to i_pos
      l_ipos_as_expected(gen_cell_num) <= nor(w_expected_pos(gen_cell_num) xor r_ipix.pos) and r_ipix.valid;
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

----------------------------------------------------
-- start pos
-----------------------------------------------------
start_pos_valid_comb_proc: process(all)
      variable v_done_mjau        : std_logic;
   begin
      l_start_pos_valid <= '0';--r_start_pos_valid;
      l_start_pos       <= (others => '0');  --r_start_pos; --    

      if (and(l_ipos_as_expected)) = '1' then
         l_start_pos       <= w_next_start_pix(c_phase_num);
         l_start_pos_valid <= '1';
      else
         cf_xor_gen: for gen_cell_num in 0 to c_phase_num -1 loop
            if (l_mux_sel(gen_cell_num )) = '1' then
               l_start_pos       <= w_next_start_pix(gen_cell_num +1);
               l_start_pos_valid <= '1';
            end if;
         end loop;
      end if;

      if l_ipix.pos /= r_ipix.pos then
         l_start_pos       <= (others => '0');
      end if;

      if l_ipos_ready = '1' and l_ipix.valid = '1' then
         l_start_pos       <= (others => '0');
      end if;

      l_indx_valid <= (others => '0');
      if (r_ipix.valid = '1') then
         l_indx_valid <= l_ipos_as_expected(0 to c_phase_num -1);
      end if;

   end process;

start_pos_valid_reg_proc: process(i_clk)
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_start_pos_valid <= '0';
            r_start_pos       <= (others => '0');
         else
            r_start_pos_valid <= l_start_pos_valid;
            if (l_start_pos_ready and i_ready) = '1' then
               r_start_pos       <= l_start_pos;
            end if;
         end if;
      end if;
   end process;

------------------------------------------------------------------------
------------------------------------------------------------------------
start_pos_comb_proc: process(all)
   begin
      l_start_pos_ready <= '0';
      if (i_ready) = '1' then
         l_start_pos_ready <= '1';
      elsif not(r_start_pos_valid) = '1' then
         l_start_pos_ready <= '1';
      end if;
   end process;

start_pos_reg_proc: process(i_clk)
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_start_pos_ready <= '0';
         else
            r_start_pos_ready <= l_start_pos_ready;
         end if;
      end if;
   end process;

-----------------------------------------
-- outputs assignment
-----------------------------------------
   o_ready           <= l_ipos_ready; --r_ipos_ready;
   o_pix             <= r_ipix;

gf: for cell_num_gen in 0 to c_phase_num -1 generate
   o_cf(cell_num_gen).cf_indx       <= l_cf_indx(cell_num_gen);
   o_cf(cell_num_gen).cf_indx_valid <= l_indx_valid(cell_num_gen);
end generate;

end Behavioral;
