-----------------------------------------------------------------------------------
-- file name   : cf_calc_cell
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

library ieee_proposed;
    use ieee_proposed.fixed_pkg.all;

library common_lib;
    use common_lib.p_common.all;

entity tb_cf_indx_calc is
   generic(
      --! Relevan input size (width/hight)
      G_IN_SIZE    : integer               :=  4;
      --! Result size in the dimension
      G_OUT_SIZE   : integer               := 16;
      --! Max number of interlived spots between two input pixels
      --! Also, a number of calc cells in the design
      G_PHASE_NUM  : integer range 2 to C_MAX_PHASE_NUM := 4;
      --! Pixel intesity data width
      G_DWIDTH     : integer range 1 to 64 :=    8);
   end;

architecture bench of tb_cf_indx_calc is

  signal i_start_pos: std_logic_vector(11 -1 downto 0);
  signal i_cell_num: std_logic_vector(0 to clog2(G_PHASE_NUM));
  signal o_expected_pos: std_logic_vector(11 -1 downto 0);
  signal o_start_pos: std_logic_vector(11 -1 downto 0);
  signal o_cf_num: std_logic_vector(clog2(G_PHASE_NUM)-1 downto 0);


  signal i_clk            : std_logic;
  signal i_rst            : std_logic;
  constant clk_period : time := 50 ns;
begin

-- Insert values for generic parameters !!
uut_cf_calc_cell: entity work.cf_calc_cell
   generic map (
      G_IN_SIZE      => G_IN_SIZE,
      G_OUT_SIZE     => G_OUT_SIZE,
      G_PHASE_NUM    => G_PHASE_NUM,
      G_DWIDTH       => G_DWIDTH)
   port map (
      i_start_pos    => i_start_pos,
      i_cell_num     => i_cell_num,
      o_expected_pos => o_expected_pos,
      o_start_pos    => o_start_pos,
      o_cf_num       => o_cf_num );

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
      wait for clk_period *9;  
         i_rst <= '0';
      wait;  
   end process;


  stimulus: process(i_clk)
      variable vr_start : std_logic;
   begin
      if rising_edge(i_clk)  or falling_edge(i_clk) then
         if i_rst = '1' then
            i_start_pos    <= (others => '0');
            i_cell_num     <= (others => '0'); 
            vr_start       := '1';
         else
            if vr_start = '1' then
               vr_start       := '0';
            elsif unsigned(i_cell_num) < G_PHASE_NUM then
               i_cell_num     <= std_logic_vector(unsigned(i_cell_num) +1);            
            elsif (unsigned(i_start_pos) < G_IN_SIZE) then
               i_start_pos     <= std_logic_vector(unsigned(i_start_pos) +1); 
               i_cell_num     <= (others => '0');           
            else
               i_start_pos    <= (others => '0');
               i_cell_num     <= (others => '0'); 
            end if;
         end if;
      end if;
   end process;


end;
