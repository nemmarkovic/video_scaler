library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library ieee_proposed;
    use ieee_proposed.fixed_pkg.all;

entity bfilter_cu is
   generic(
      G_IN_WIDTH   : positive := 3;
      G_OUT_WIDTH  : positive := 10;
      -- must be pow(2)
      G_PHASE_NUM : positive := 4;
      G_MAX_OUT   : positive := 2048);
   port ( 
      i_clk       : in  std_logic;
      i_rst       : in  std_logic;
      i_valid     : in  std_logic;
      o_ready     : out std_logic;
      i_pos       : in  std_logic_vector(integer(ceil(log2(real(G_MAX_OUT)))) -1 downto 0);

      i_cr_ready  : in  std_logic_vector(G_PHASE_NUM -1 downto 0);
      o_cf_valid  : out std_logic_vector(G_PHASE_NUM -1 downto 0);
      o_cf_pos    : out std_logic_vector(integer(ceil(log2(real(G_PHASE_NUM))))*G_PHASE_NUM -1 downto 0));
   end bfilter_cu;

architecture Behavioral of bfilter_cu is

  component reg is
   generic(
      G_DWIDTH : positive := 8);
   port (
      i_clk   : in  std_logic;
      i_rst   : in  std_logic;

      i_valid : in  std_logic;
      o_ready : out std_logic;
      i_data  : in  std_logic_vector(G_DWIDTH -1 downto 0);

      i_ready : in  std_logic;
      o_valid : out std_logic;
      o_data  : out std_logic_vector(G_DWIDTH -1 downto 0));
     end component;

   constant c_wpos : positive              := integer(ceil(log2(real(G_MAX_OUT))));
   constant c_sf   : ufixed(6 downto -6)   := resize(to_ufixed((G_IN_WIDTH -1) *G_PHASE_NUM +1-1,7,-7)/to_ufixed(G_OUT_WIDTH -1, 7,-7 ), 6,-6);
   constant c_cf_pos_width : natural       := integer(ceil(log2(real(G_PHASE_NUM))));

   signal w_iREG_IPOS_valid : std_logic;
   signal w_oREG_IPOS_ready : std_logic;
   signal w_iREG_IPOS_data  : std_logic_vector(c_wpos -1 downto 0);

   signal w_iREG_IPOS_ready : std_logic;
   signal w_oREG_IPOS_valid : std_logic;
   signal w_oREG_IPOS_data  : std_logic_vector(c_wpos -1 downto 0);

   signal w_iREG_OPOS_valid : std_logic;
   signal w_oREG_OPOS_ready : std_logic;
   signal w_iREG_OPOS_data  : std_logic_vector(c_wpos -1 downto 0);

   signal w_iREG_OPOS_ready : std_logic;
   signal w_oREG_OPOS_valid : std_logic;
   signal w_oREG_OPOS_data  : std_logic_vector(c_wpos -1 downto 0);

   signal r_read_next_pos  : std_logic;
   signal r_cyc_start_opos : unsigned(c_wpos -1 downto 0);
   signal l_cf_valid       : std_logic_vector(G_PHASE_NUM -1 downto 0);

   type t_array_slv is array (G_PHASE_NUM -1 downto 0) of std_logic_vector(7 downto 0);
   signal w_mul_sub : t_array_slv;

   type t_cf_num_array is array (G_PHASE_NUM -1 downto 0) of std_logic_vector(c_cf_pos_width -1 downto 0);
   signal l_cf_num : t_cf_num_array;

   type t_ipix_poss is array (G_PHASE_NUM -1 downto 0) of std_logic_vector(8 -c_cf_pos_width -1 downto 0);
   signal l_ipix_pos_for_opix : t_ipix_poss;

   type t_ipos_fits is array (G_PHASE_NUM -1 downto 0) of std_logic;
   signal l_ipos_fits : t_ipos_fits;
 --  signal l_coef_valid : t_ipos_fits;

begin
------------------------------------------
-- register input possition info
------------------------------------------
   w_iREG_IPOS_valid <= i_valid;
   w_iREG_IPOS_data  <= i_pos;

   w_iREG_IPOS_ready <= r_read_next_pos;

reg_in_poss: reg --entity work.reg
   generic map(
      G_DWIDTH => c_wpos)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,

      i_valid => w_iREG_IPOS_valid,
      o_ready => w_oREG_IPOS_ready,
      i_data  => w_iREG_IPOS_data,

      i_ready => w_iREG_IPOS_ready,
      o_valid => w_oREG_IPOS_valid,
      o_data  => w_oREG_IPOS_data);

--   w_oREG_POS_valid <= 
--   w_oREG_POS_data  <= 
--   w_oREG_POS_ready <= 


------------------------------------------
-- register next output pix possition info
------------------------------------------
   w_iREG_OPOS_valid <= i_valid;
   w_iREG_OPOS_data  <= std_logic_vector(r_cyc_start_opos);

   w_iREG_OPOS_ready <= r_read_next_pos;

reg_out_poss: reg --entity work.reg
   generic map(
      G_DWIDTH => c_wpos)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,

      i_valid => w_iREG_OPOS_valid,
      o_ready => w_oREG_OPOS_ready,
      i_data  => w_iREG_OPOS_data,

      i_ready => w_iREG_OPOS_ready,
      o_valid => w_oREG_OPOS_valid,
      o_data  => w_oREG_OPOS_data);

--   w_oREG_POS_valid <= 
--   w_oREG_POS_data  <= 
--   w_oREG_POS_ready <= 

gen_calc_pos: for i in 0 to G_PHASE_NUM -1 generate
   w_mul_sub(i)         <= std_logic_vector( resize(((to_ufixed(to_integer(unsigned(w_oREG_OPOS_data)),7,-6) + to_ufixed(i,7,-6)) * c_sf),7,0));
   l_cf_num(i)          <= w_mul_sub(i)(c_cf_pos_width -1 downto 0);
   l_ipix_pos_for_opix(i)<= w_mul_sub(i)(8 -1 downto c_cf_pos_width);
   end generate;

gen_cmp_positions: for i in 0 to G_PHASE_NUM -1 generate

   l_ipos_fits(i) <= '1' when to_integer(unsigned(l_ipix_pos_for_opix(i))) = to_integer(unsigned(w_oREG_IPOS_data)) else '0';
   l_cf_valid(i)  <= l_ipos_fits(i) and w_oREG_OPOS_valid;
   end generate;

------------------------------------------
-- calculate start out pix position value
-- for current cycle
------------------------------------------
calc_cyc_start_opos_p: process(all)--i_clk)
      variable ssss : unsigned(c_wpos -1 downto 0);
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_read_next_pos  <= '0';
            ssss := (others => '0');
         else
            if w_oREG_OPOS_ready = '1' then
               r_read_next_pos  <= '0';
            end if;
            ssss := r_cyc_start_opos;
            if (or(i_cr_ready) and or(o_cf_valid)) = '1' then
               -- if all multipliers are active next cycle starts at
               -- r_cyc_start_opos incremented for G_PHASE_NUM +1
               ssss := ssss + unsigned(l_cf_num(G_PHASE_NUM -1)); -- r_opos(G_PHASE_NUM)
               for i in 1 to G_PHASE_NUM -1 loop
                  if (l_ipos_fits(i) xor l_ipos_fits(i-1)) = '1' then
                     -- last valid output is on r_opos(l_ipos_fits(i-1)) possition
                     -- next cycle possition is r_opos(l_ipos_fits(i))
                     ssss := ssss + unsigned(l_cf_num(i -1)); -- r_opos(l_ipos_fits(i))
                     r_read_next_pos  <= '1';
                  end if;
               end loop;
            end if;
         end if;
         r_cyc_start_opos <= ssss;
      end if;
   end process;

   o_cf_valid <= l_cf_valid;
gen_out:
   for i in 0 to G_PHASE_NUM -1 generate
      o_cf_pos((i +1) *c_cf_pos_width -1 downto i *c_cf_pos_width) <= l_cf_num(i);
   end generate;
   o_ready <= w_oREG_OPOS_ready;
end Behavioral;
