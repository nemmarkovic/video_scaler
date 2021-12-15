library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.p_axi.all;
library ieee_proposed;
    use ieee_proposed.fixed_pkg.all;

library common_lib;
    use common_lib.p_common.all;

entity tb_video_scaler is
     generic(
        G_IN_SIZE       : integer               := 4;
        G_OUT_SIZE      : integer               := 21;
        G_PHASE_NUM     : integer range 2 to C_MAX_PHASE_NUM := 4;
        G_DWIDTH        : integer range 1 to 64 :=    8);
end tb_video_scaler;

architecture Behavioral of tb_video_scaler is
   signal i_clk  : std_logic;
   signal i_rst  : std_logic;
   signal o_ready: std_logic;

   signal s_axis_in    : t_axis_s_in;
   signal s_axis_out   : t_axis_s_out;

   signal i_ready: std_logic;
   signal o_pix  : t_out_pix;

   signal s_pix_gen  : t_in_pix;
   signal s_valid_i : std_logic;
   signal s_ready_o : std_logic;

   signal s_axis_in_gen  : t_axis_s_in;
   signal s_pix_i    : std_logic_vector(11 -1 downto 0);
   signal s_pix_o    : std_logic_vector(11 -1 downto 0);
   signal s_valid   : std_logic;

   constant clk_period : time := 50 ns;
begin

  -- Insert values for generic parameters !!
video_scaler_i: entity work.video_scaler 
   generic map (
      G_IN_SIZE   => G_IN_SIZE,
      G_OUT_SIZE  => G_OUT_SIZE,
      G_PHASE_NUM => G_PHASE_NUM,
      G_DWIDTH    => G_DWIDTH )
   port map (
      i_clk       => i_clk,
      i_rst       => i_rst,
      o_ready     => o_ready,

      s_axis_in   => s_axis_in,
      s_axis_out  => s_axis_out,

      i_ready     => i_ready,
      o_pix       => o_pix );

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
      wait for clk_period *10;  
         i_rst <= '0';
      wait;  
   end process;



reg_hs_i: entity work.reg_hs
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => s_pix_i,
      i_valid => s_valid_i,
      o_ready => s_ready_o,
      i_ready => s_axis_out.tready,
      o_valid => s_valid,
      o_data  => s_pix_o);


s_valid_i        <= s_axis_in_gen.tvalid;
s_pix_i          <= s_axis_in_gen.tvalid & s_axis_in_gen.tdata & s_axis_in_gen.tlast & s_axis_in_gen.tuser;

s_axis_in.tvalid <= s_valid;
s_axis_in.tdata  <= s_pix_o(10 -1 downto 2);
s_axis_in.tlast  <= s_pix_o(1);
s_axis_in.tuser  <= s_pix_o(0);



stimulus1: process(i_clk)
      variable vr_start : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            s_axis_in_gen <= t_axis_s_in_rst;
            i_ready       <= '0';
            vr_start      := '1';
         else

            if s_valid_i = '1' and s_ready_o = '1' and vr_start = '1' then

               s_axis_in_gen.tlast <= '0';
               if to_integer(unsigned(s_axis_in_gen.tdata)) >= 8 then
                  s_axis_in_gen.tlast <= '1';
               end if;

               if to_integer(unsigned(s_axis_in_gen.tdata)) >= 9 then
                 -- s_pix_gen.pos  <= (others => '0');
                  s_axis_in_gen.tlast <= '0';
                  s_axis_in_gen <= t_axis_s_in_rst;
               else
                  s_axis_in_gen.tdata <= std_logic_vector(unsigned(s_axis_in_gen.tdata) +1);
               end if;
            end if;

            if (s_valid_i  and   s_ready_o) = '1' then
               vr_start := '1';
            elsif(s_ready_o = '1' and to_integer(unsigned(s_axis_in_gen.tdata)) <= 20 -1) then
               s_axis_in_gen.tvalid <= '1';
            else
               s_axis_in_gen.tvalid <= s_axis_in_gen.tvalid;
               s_axis_in_gen.tvalid <= '0';
            end if;
            i_ready     <=  '1'; --not(i_ready); --
         end if;
      end if;
   end process;

end Behavioral;
