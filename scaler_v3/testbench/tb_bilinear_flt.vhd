library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library ieee_proposed;
    use ieee_proposed.fixed_pkg.all;

library common_lib;
    use common_lib.p_common.all;

entity tb_bilinear_flt is
     generic(
        G_IN_SIZE       : integer               :=  4;
        G_OUT_SIZE      : integer               := 21;
        G_PHASE_NUM     : integer range 2 to C_MAX_PHASE_NUM := 4;
        G_DWIDTH        : integer range 1 to 64 :=    8);
   end;

architecture bench of tb_bilinear_flt is

   signal i_clk  : std_logic;
   signal i_rst  : std_logic;
   signal o_ready: std_logic;
   signal i_pix  : t_in_pix;
   signal i_ready: std_logic;
   signal o_pix  : t_out_pix_array;
   signal o_start_pos : std_logic_vector(11 -1 downto 0);
   signal o_bank_sel  : std_logic_vector(11 downto 0);

   signal s_pix_gen  : t_in_pix;
   signal s_pix_i    : std_logic_vector(11 +2 +G_DWIDTH*2 +1-1 downto 0);
   signal s_pix_o    : std_logic_vector(11 +2 +G_DWIDTH*2 +1-1 downto 0);
   signal s_valid_i : std_logic;
   signal s_ready_o : std_logic;


   constant clk_period : time := 50 ns;
begin

  -- Insert values for generic parameters !!
uut_bilinear_flt_i: entity work.bilinear_flt 
   generic map (
      G_IN_SIZE   => G_IN_SIZE,
      G_OUT_SIZE  => G_OUT_SIZE,
      G_PHASE_NUM => G_PHASE_NUM,
      G_DWIDTH    => G_DWIDTH )
   port map (
      i_clk       => i_clk,
      i_rst       => i_rst,
      o_start_pos => o_start_pos,
      o_ready     => o_ready,
      i_pix       => i_pix,
      i_ready     => i_ready,
      o_pix       => o_pix,
      o_bank_sel  => o_bank_sel );


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
      G_DWIDTH => 11 +2 +G_DWIDTH*2 +1)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => s_pix_i,
      i_valid => s_valid_i,
      o_ready => s_ready_o,
      i_ready => o_ready,
      o_valid => i_pix.valid,
      o_data  => s_pix_o);

s_valid_i <= s_pix_gen.valid;
s_pix_i <= s_pix_gen.valid & s_pix_gen.pix0 & s_pix_gen.pix1 & s_pix_gen.pos & s_pix_gen.last & s_pix_gen.sof;
--i_pix.valid <= s_pix_o(11 +2 +G_DWIDTH*2);
i_pix.pix0  <= s_pix_o(11 +2 +G_DWIDTH*2 -1 downto 11 +2 +G_DWIDTH);
i_pix.pix1  <= s_pix_o(11 +2 +G_DWIDTH -1 downto 11 +2);
i_pix.pos   <= s_pix_o(11 +2 -1 downto 2);
i_pix.last  <= s_pix_o(1);
i_pix.sof   <= s_pix_o(0);



stimulus1: process(i_clk)
      variable vr_start : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            s_pix_gen       <= t_in_pix_rst;
            i_ready     <= '0';
            vr_start    := '1';
         else
            

            s_pix_gen.pix0  <= std_logic_vector(to_unsigned(1, 8));
            s_pix_gen.pix1  <= std_logic_vector(to_unsigned(2, 8));
 
            if s_valid_i = '1' and s_ready_o = '1' and vr_start = '1' then -- and to_integer(unsigned(i_pix.pos)) < G_IN_SIZE -1 
 
               s_pix_gen.last <= '0';
               if to_integer(unsigned(s_pix_gen.pos)) >= G_IN_SIZE -2 then
                  s_pix_gen.last <= '1';
               end if;

               if to_integer(unsigned(s_pix_gen.pos)) >= G_IN_SIZE -1 then
                 -- s_pix_gen.pos  <= (others => '0');
                  s_pix_gen.last <= '0';
               else
                  s_pix_gen.pos <= std_logic_vector(unsigned(s_pix_gen.pos) +1);
               end if;
              -- i_start_pos <= std_logic_vector(unsigned(i_start_pos) +4);
 
--            elsif to_integer(unsigned(s_pix_gen.pos)) > G_IN_SIZE -1 then
--               s_pix_gen.pos <= std_logic_vector(to_unsigned(0,11));
            end if;
 
            if (s_valid_i  and   s_ready_o) = '1' then
              -- s_pix_gen.valid <= '0';
               vr_start := '1';
            elsif(s_ready_o = '1' and to_integer(unsigned(s_pix_gen.pos)) <= G_IN_SIZE -1) then
               s_pix_gen.valid <= '1';         
            else
               s_pix_gen.valid <= s_pix_gen.valid;            
               s_pix_gen.valid <= '0'; 
            end if;
            --i_pix.valid <= '1';           
            i_ready     <=  '1';
         end if;
      end if;
   end process;

end;
