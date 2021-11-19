library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.numeric_std.ALL;
    use IEEE.math_real.ALL;

    use work.p_common.all;

entity bilinear_flt is
   generic(
      G_IN_WIDTH      : positive              :=  3;
      G_OUT_WIDTH     : positive              :=  8;
      G_PHASE_NUM     : integer               :=  4);
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
      i_pix0     : in  std_logic_vector(8-1 downto 0);
      i_pix1     : in  std_logic_vector(8-1 downto 0);
      -- input row/comlmun number
      i_pos      : in  std_logic_vector(11 -1 downto 0);
      -- out pix valid
      o_pix_valid : out std_logic_vector(G_PHASE_NUM -1 downto 0); 
      -- out pix
      o_pix0     : out  std_logic_vector(16-1 downto 0);
      o_pix1     : out  std_logic_vector(16-1 downto 0));
   end bilinear_flt;


architecture Behavioral of bilinear_flt is

   type t_dummy is array (0 to G_PHASE_NUM -1) of std_logic_vector(15 downto 0);
   signal w_dummy0 : t_dummy;
   signal w_dummy1 : t_dummy;
   signal w_dummy2 : t_dummy;
   signal w_dummy3 : t_dummy;

   attribute use_dsp : string;
--   attribute use_dsp of l_p : signal is "yes";
   attribute use_dsp of o_pix0    : signal is "no";
   attribute use_dsp of o_pix1    : signal is "no";

   signal r_out_possition : unsigned(integer(ceil(log2(real(2048)))) -1 downto 0);
   
   type t_cf is array (0 to G_PHASE_NUM -1) of natural range 0 to G_PHASE_NUM -1;
   signal s_coeff_num : t_cf;
begin

------------------------------------------------------
-- Gen valid process 
------------------------------------------------------

out_pos_proc: process(i_clk)
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_out_possition <= (others => '0');
         else
            for i in 0 to G_PHASE_NUM -1 loop
               s_coeff_num(i) <= (((to_integer(r_out_possition +i)) * (G_IN_WIDTH -1) * G_PHASE_NUM) / G_OUT_WIDTH) mod G_PHASE_NUM;
            end loop;
            r_out_possition <= r_out_possition + G_PHASE_NUM;
            if r_out_possition >= G_OUT_WIDTH then
               r_out_possition <= (others => '0');
            end if;
         end if;
      end if;
   end process;

gen_phase_dsp:
   for i in 0 to ((G_PHASE_NUM/2 -1) + (G_PHASE_NUM mod 2)) generate
      mul_cell0_i : entity work.mul_cell
            generic map (
               G_REG_IN =>  0)
            port map (
               i_clk    => i_clk,
               i_rst    => i_rst,
               i_B      => i_pix0,
               i_A      => coeff0(0, s_coeff_num(i)),
               i_D      => coeff0(0, s_coeff_num(i +1)),
               i_C      => (others => '0'),
               o_mul1   => w_dummy0(i),
               o_mul2   => w_dummy1(i) );
      
      mul_cell1_i : entity work.mul_cell
            generic map (
               G_REG_IN =>  0)
            port map (
               i_clk    => i_clk,
               i_rst    => i_rst,
               i_B      => i_pix1,
               i_A      => coeff0(1, s_coeff_num(i)),
               i_D      => coeff0(1, s_coeff_num(i +1)),
               i_C      => "000000000" & w_dummy1(i) & "0000000" & w_dummy0(i),
               o_mul1   => w_dummy2(i),
               o_mul2   => w_dummy3(i) );

   end generate;

--o_pix0 <= std_logic_vector(unsigned(w_dummy0) + unsigned(w_dummy2));
--o_pix1 <=  std_logic_vector(unsigned(w_dummy1) + unsigned(w_dummy3));

end Behavioral;