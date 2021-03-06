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
  signal o_ready          : std_logic;
  signal i_pos            : std_logic_vector(11 -1 downto 0);
  signal i_start_pos      : std_logic_vector(11 -1 downto 0);
  signal o_pos_ready      : std_logic;
  signal o_start_pos_ready: std_logic;
  signal o_start_pos      : std_logic_vector(11 -1 downto 0);
  signal i_ready_indx     : std_logic;
  signal o_valid_indx     : std_logic_vector(0 to G_PHASE_NUM -1);
  signal o_cf             : t_cf_indx_array;
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
      i_start_pos       => i_start_pos,
      o_pos_ready       => o_pos_ready,
      o_start_pos_ready => o_start_pos_ready,
      o_start_pos       => o_start_pos,
      i_ready           => i_ready_indx,
      o_cf              => o_cf );

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
     begin
      if rising_edge(i_clk) then
        if i_rst = '1' then
           i_start_pos <= (others => '0');
        else
           if o_start_pos_ready = '1' and to_integer(unsigned(o_start_pos)) < G_OUT_SIZE then
               i_start_pos <= o_start_pos;
           end if;
        end if;
        end if;
   end process;
   
  stimulus: process(i_clk)
      variable vr_start : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            i_valid          <= '0';
            i_pos            <= (others => '0');--: std_logic_vector(11 -1 downto 0);
            --i_start_pos      <= (others => '0');--: std_logic_vector(11 -1 downto 0);
            i_ready_indx     <= '0';--: std_logic_vector(0 to G_PHASE_NUM -1);        
            vr_start         := '1';
         else
            i_ready_indx     <= '1';

            if (i_valid  and   o_ready) = '1' then
               --i_valid <= '0';
            elsif(o_ready = '1') then
               i_valid <= '1';         
            else
               i_valid <= i_valid;            
            end if;

            if i_valid = '1' and o_pos_ready = '1' and to_integer(unsigned(i_pos)) < G_IN_SIZE -1 then
               i_pos <= std_logic_vector(unsigned(i_pos) +1);
              -- i_start_pos <= std_logic_vector(unsigned(i_start_pos) +4);
            end if;

         end if;
      end if;
   end process;


end;
