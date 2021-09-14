library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

--library ieee_proposed;
--    use ieee_proposed.fixed_pkg.all;

library common_lib;
    use common_lib.p_common.all;

entity tb_bilinear_flt is
   generic(
      G_MANTISA_WIDTH : integer range 1 to 64 :=  8;
      G_PRESISION     : integer range 1 to 64 :=  8; --= clog2(G_TAP_NO)
      G_TAP_NO        : integer range 2 to 64 := 64;
      G_IN_SIZE_Y     : integer :=  10;
      G_OUT_SIZE_Y    : integer :=  20);
   end entity tb_bilinear_flt;

architecture bench of tb_bilinear_flt is

   signal i_clk : std_logic;
   signal i_rst : std_logic;

   signal o_ready   : std_logic;
   signal i_pix     : T_HAND_SHAKE_d1out;--(data(G_MANTISA_WIDTH downto 0));
   signal i_colmun  : std_logic_vector(11 -1 downto 0);
   signal i_ready   : std_logic;
   signal o_pix     : T_HAND_SHAKE_d1_ARRAY;--(0 to G_TAP_NO -1)(data(G_MANTISA_WIDTH + G_PRESISION -1 downto 0));
   
   signal s_done : std_logic;
   signal colmun: natural;

   constant clk_period : time := 10 ns;

begin

  -- Insert values for generic parameters !!
   vert_filter_i: entity work.bilinear_flt
      generic map (
         G_MANTISA_WIDTH => G_MANTISA_WIDTH,
         G_PRESISION     => G_PRESISION,
         G_TAP_NO        => G_TAP_NO,
         G_IN_SIZE       => G_IN_SIZE_Y,
         G_OUT_SIZE      => G_OUT_SIZE_Y)
      port map (
         i_clk           => i_clk,
         i_rst           => i_rst,
         o_ready         => o_ready,
         i_pix           => i_pix,
         i_colmun        => i_colmun,
         i_ready         => i_ready,
         o_pix           => o_pix);

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

  stimulus: process
  begin

       s_done <= '0';
  
        i_pix.last <= '0';
        i_pix.eof <= '0';
        i_pix.data(15 downto 8)   <= std_logic_vector(to_unsigned(30, G_MANTISA_WIDTH));
        i_pix.data( 7 downto 0)   <= std_logic_vector(to_unsigned(90, G_MANTISA_WIDTH));

       wait for clk_period *10;
       s_done <= '1';

    wait;
  end process;


  process(i_clk)
     variable v_mjau : integer;
  begin
     if rising_edge(i_clk) then
     if i_rst = '1' then
           i_pix.valid <= '0';
           colmun <= 0;
          -- v_mjau :=0;
           i_colmun <= (others => '0');
           i_ready  <= '0';
     else
        i_ready  <= '1';
        if s_done = '0' then
           i_pix.valid <= '0';
           colmun <= 0;
         --  v_mjau :=0;
           i_ready  <= '0';
       -- elsif v_mjau = 1 then 
       --    i_pix.valid <= '1';
       --    v_mjau := v_mjau +1;
        elsif colmun < G_IN_SIZE_Y -1 then--and v_mjau = 2 then            
           colmun <= colmun +1;
           i_pix.valid <= '1';
           v_mjau := 0;
        else
           colmun <= 0;
           --v_mjau := v_mjau +1;
           i_pix.valid <= '0';
        end if;
        i_colmun <= std_logic_vector(to_unsigned(colmun, 11));
     end if;
     end if;
  end process;

end;

