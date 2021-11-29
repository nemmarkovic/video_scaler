library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

library ieee_proposed;
    use ieee_proposed.fixed_pkg.all;

library common_lib;
    use common_lib.p_common.all;

entity tb_cf_indx is
     generic(
        G_IN_SIZE       : integer               :=  4;
        G_OUT_SIZE      : integer               :=  21;
        G_PHASE_NUM     : integer range 2 to 64 :=    4;
        G_DWIDTH        : integer range 1 to 64 :=    8);
end;

architecture bench of tb_cf_indx is

  signal i_clk            : std_logic;
  signal i_rst            : std_logic;
  signal i_valid          : std_logic;
  signal i_pos            : std_logic_vector(11 -1 downto 0);
  signal i_ready_indx     : std_logic;

  signal i_start_pos_valid : std_logic;
  signal o_start_pos_ready : std_logic;
  signal i_start_pos       : std_logic_vector(11 -1 downto 0);

  signal o_start_pos_valid : std_logic;
  signal i_start_pos_ready : std_logic;
  signal o_start_pos       : std_logic_vector(11 -1 downto 0);

  signal o_ready          : std_logic;
  signal o_cf             : t_cf_indx_array;

  signal i_start_pos_valid_reg : std_logic;
  signal i_start_pos_reg       : std_logic_vector(11 -1 downto 0);

  signal l_valid          : std_logic;
  signal l_pos            : std_logic_vector(11 -1 downto 0);
  signal l_ready_indx     : std_logic;

   constant clk_period : time := 50 ns;
begin

  -- Insert values for generic parameters !!
uut: entity work.cf_indx_calc 
   generic map (
      G_IN_SIZE         => G_IN_SIZE,
      G_OUT_SIZE        => G_OUT_SIZE,
      G_PHASE_NUM       => G_PHASE_NUM,
      G_DWIDTH          => G_DWIDTH )
   port map ( 
      i_clk             => i_clk,
      i_rst             => i_rst,
      i_valid           => i_valid,
      o_ready           => o_ready,
      i_pos             => i_pos,
      i_start_pos_valid => i_start_pos_valid,
      o_start_pos_ready => o_start_pos_ready,
      i_start_pos       => i_start_pos,

      o_start_pos_valid => o_start_pos_valid,
      i_start_pos_ready => i_start_pos_ready,
      o_start_pos       => o_start_pos,
      i_ready           => i_ready_indx,
      o_cf              => o_cf );

reg_start_pos: entity work.reg_hs
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => i_start_pos_reg,
      i_valid => i_start_pos_valid_reg,
      o_ready => i_start_pos_ready,
      i_ready => o_start_pos_ready,
      o_valid => i_start_pos_valid,
      o_data  => i_start_pos);

process(all)
   variable v_start : std_logic;
begin
   if i_rst = '1' then
      i_start_pos_reg       <= (others => '0');
      i_start_pos_valid_reg <= '0';
      v_start               := '0';
   else 
      if v_start = '0' then
         i_start_pos_valid_reg <= '1';
         i_start_pos_reg       <= (others => '0');
         if o_ready = '1' then
            v_start               := '1';
         end if;
      else
         i_start_pos_reg       <= o_start_pos;
         i_start_pos_valid_reg <= o_start_pos_valid;
      end if;
   end if;
end process;

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
              wait for clk_period *100; 
      wait;  
   end process;

  stimulus_comb: process(all)
   begin
      l_ready_indx <= i_ready_indx;
      l_valid <= i_valid;
      l_pos   <= i_pos;   
 
      if (i_valid and o_ready) = '1' then
        l_valid <= not i_valid;
        l_pos   <= std_logic_vector((unsigned(i_pos) + 1) mod (G_IN_SIZE));

      elsif o_ready <= '1' then
        l_valid <= '1';
      end if;
   end process;

   
  stimulus: process(i_clk)
      variable vr_start : std_logic;
      variable vr_cf_valid : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
--            i_ready_indx     <= '0';
            i_valid          <= '0';
            i_pos            <= (others => '0');
            vr_start         := '0';
         else
            i_pos   <= l_pos;
            i_valid <= l_valid;
            for i in 0 to 3 loop
               if o_cf(i).cf_indx_valid = '1' then
                  vr_cf_valid := '1';
               end if;
            end loop;
            if vr_cf_valid = '1' then
 --              i_ready_indx <= not l_ready_indx;
               vr_cf_valid := '0';
            end if;
            if vr_start = '0' then
 --              i_ready_indx <= '1';
               vr_start     := '1';
            end if;
         end if;
      end if;
   end process;


 stimulus2: process
    begin
       i_ready_indx     <= '0';
       wait for clk_period * 20;
       wait until rising_edge(i_clk);

       i_ready_indx <= '1';
       wait for clk_period * 2;
       wait until rising_edge(i_clk);
       i_ready_indx <= '0';

       wait for clk_period * 20;
       wait until rising_edge(i_clk);

       i_ready_indx <= '1';

       wait;
     end process;

end;
