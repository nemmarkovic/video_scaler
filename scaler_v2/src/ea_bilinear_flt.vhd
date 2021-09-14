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

library ieee_proposed;
    use ieee_proposed.fixed_pkg.all;

library common_lib;
    use common_lib.p_common.all;

entity bilinear_flt is
   generic(
      G_IN_SIZE       : integer               :=  446;
      G_OUT_SIZE      : integer               := 2048;
      G_MANTISA_WIDTH : integer range 1 to 64 :=    8;
      G_PRESISION     : integer range 1 to 64 :=    8; --= clog2(G_TAP_NO)
      G_TAP_NO        : integer range 2 to C_MAX_TAP_NO :=   C_MAX_TAP_NO);
   port ( 
      -- input clk
      i_clk     : in  std_logic;
      -- input reset
      i_rst     : in  std_logic;
      -- ready to filter new data pair
      o_ready   : out std_logic;
      i_valid   : in  std_logic;
      -- input pixel data
      -- data = pix0[2*G_MANTISA_WIDTH -1 : G_MANTISA_WIDTH], 
      --        pix1[  G_MANTISA_WIDTH -1 : 0]
      -- last  : std_logic; 
      -- eof   : std_logic;
      i_pix     : in  t_dinfo(data(0 to 1));
      -- input row/comlmun pair
      i_position  : in  std_logic_vector(11 -1 downto 0);
      -- next module ready to accept filter outputs
      i_ready   : in  std_logic;
      o_valid   : out std_logic_vector(G_TAP_NO -1 downto 0);
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      o_pix     : out t_dinfo_array(0 to G_TAP_NO-1)(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0)));
   end bilinear_flt;


architecture Behavioral of bilinear_flt is
   constant SFY : sfixed(C_SF_WIDTH -1 downto -G_PRESISION) := 
                   resize(((to_sfixed(G_IN_SIZE  -2, 12, -1)) /
                          ( to_sfixed(G_OUT_SIZE -1, 12, -1))), C_SF_WIDTH -1, -G_PRESISION);

   -- bilinear filter cell signals
   signal s_oVFCEL_dinfo : t_dinfo_array(0 to G_TAP_NO-1)(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));
   signal s_oVFCEL_valid : std_logic_vector(G_TAP_NO -1 downto 0);

   type t_possition is array (0 to 63) of natural range 0 to G_TAP_NO - 1;
   signal s_iVFCEL_out_col : t_possition;
   signal s_iVFCEL_valid   : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_colmun         : std_logic_vector(11-1 downto 0);
   signal s_iVFCEL_pix     : t_dinfo(data(0 to 1)(G_MANTISA_WIDTH -1 downto 0));

   type t_valid_col is record
      col_out_num  : natural range 0 to G_TAP_NO -1;
      valid        : std_logic;  
   end record;

   type t_valid_col_array is array (0 to G_TAP_NO - 1) of t_valid_col;

   signal col_out_info : t_valid_col_array;
   signal s_hrange : natural range 0 to G_TAP_NO - 1;
   signal s_lrange : natural range 0 to G_TAP_NO - 1;

begin

------------------------------------------------------
-- Gen valid process 
------------------------------------------------------
gen_valid:
   for gen_var in 0 to G_TAP_NO -1 generate
      valid_proc: process(i_clk)
         variable v_colmun : natural;
      begin
         if rising_edge(i_clk) then
            if i_rst = '1' then
               col_out_info(gen_var).valid        <= '0';
               col_out_info(gen_var).col_out_num  <=  0;
            else
               v_colmun := to_integer(unsigned(i_position));
               if ((v_colmun +1)*(G_OUT_SIZE-1) - gen_var * (G_IN_SIZE -1)) >= 0 and 
                  ((v_colmun)   *(G_OUT_SIZE-1) - gen_var * (G_IN_SIZE -1)) <= 0 and
                   gen_var < G_OUT_SIZE

               then
                  col_out_info(gen_var).col_out_num  <= gen_var;
                  col_out_info(gen_var).valid        <= '1';
               else
                  col_out_info(gen_var).valid        <= '0';
               end if;
            end if;
         end if;

      end process;
   end generate;

------------------------------------------------------
-- Set output row/colmun range proc
------------------------------------------------------
filter_cell_range_proc: process(all)
      variable v_stop   : std_logic;
   begin
      for gen_var in 0 to G_TAP_NO -1 loop
         if gen_var = 0 then
            v_stop := '0';
            s_hrange <= 0;
            s_iVFCEL_valid(gen_var) <= '0';
         end if;
      
         if v_stop = '0' then
            s_lrange <= col_out_info(gen_var).col_out_num;
         end if;
      
         if col_out_info(gen_var).valid   = '1' then
            v_stop := '1';
            s_hrange <= col_out_info(gen_var).col_out_num;
         end if;

         if gen_var <= s_hrange - s_lrange then
            s_iVFCEL_valid(gen_var)   <= '1' and i_valid;
            s_iVFCEL_out_col(gen_var) <= s_lrange + gen_var;
         else
            s_iVFCEL_valid(gen_var)   <= '0';
            s_iVFCEL_out_col(gen_var) <=  0;
         end if;

      end loop;
   end process;

------------------------------------------------------
-- Register inputs process
-- Register input colmun and pixel values to be synced
-- with valid data info 
------------------------------------------------------
filter_cell_in_reg_proc: process(i_clk)
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            s_colmun          <= (others => '0');
            s_iVFCEL_pix.data <= (others => (others => '0'));
            s_iVFCEL_pix.last <= '0';
            s_iVFCEL_pix.eof  <= '0';
         else
            s_colmun          <= i_position;
            s_iVFCEL_pix      <= i_pix;
         end if;
      end if;
   end process;


gen_filter_cell:
   for gen_var in 0 to G_TAP_NO -1 generate
      filter_cell_i : entity work.filter_cell
         generic map(
            G_MANTISA_WIDTH => G_MANTISA_WIDTH,
            G_PRESISION     => G_PRESISION)
         port map( 
            i_clk    => i_clk,
            i_rst    => i_rst,
            i_valid  => s_iVFCEL_valid(gen_var),
            i_pix    => s_iVFCEL_pix,
            i_SFY    => SFY,
            i_colmun => s_colmun,
            i_ocolmun=> std_logic_vector(to_unsigned(col_out_info(gen_var).col_out_num, 11)),
            o_pix    => s_oVFCEL_dinfo(gen_var),
            o_valid  => s_oVFCEL_valid(gen_var));

      end generate;

------------------------------------------------------------------------------------
-- output assignment
------------------------------------------------------------------------------------
   o_pix   <= s_oVFCEL_dinfo;
   o_valid <= s_oVFCEL_valid;
   o_ready <= i_ready;

end Behavioral;

