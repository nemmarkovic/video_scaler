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

stimulus1: process(i_clk)
      variable vr_start : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            i_pix       <= t_in_pix_rst;
            i_ready     <= '0';
            vr_start    := '0';
         else

            i_pix.pix0  <= std_logic_vector(to_unsigned(1, 8));
            i_pix.pix1  <= std_logic_vector(to_unsigned(2, 8));
            i_pix.last  <= '0'; --: std_logic; 
            i_pix.sof   <= '0'; --: std_logic;
 
            if i_pix.valid = '1' and o_ready = '1' and vr_start = '1' then
               i_pix.pos <= std_logic_vector(unsigned(i_pix.pos) +1);
               i_pix.last <='0';
               if  to_integer(unsigned(i_pix.pos)) >=  G_IN_SIZE -2 then
                  i_pix.last <='1';
               end if;
            elsif  to_integer(unsigned(i_pix.pos)) >=  G_IN_SIZE -1 then
               i_pix.pos <= std_logic_vector(to_unsigned(0,11));
               i_pix.last <='0';
            end if;
 
            if (i_pix.valid  and   o_ready) = '1' then
               --i_valid <= '0';
               vr_start := '1';
            elsif(o_ready = '1') then
               i_pix.valid <= '1';         
            else
               i_pix.valid <= i_pix.valid;            
            end if;
                i_pix.valid <= '1';           
            i_ready     <=  '1';
         end if;
      end if;
   end process;


end;
