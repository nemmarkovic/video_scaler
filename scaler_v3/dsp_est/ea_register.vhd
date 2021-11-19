library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

entity reg is
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
   end reg;

architecture Behavioral of reg is
   signal r_latch_data     : std_logic_vector(G_DWIDTH -1 downto 0);
   signal r_ready          : std_logic;
   signal r_valid          : std_logic;

   signal l_latch_data     : std_logic_vector(G_DWIDTH -1 downto 0);
   signal l_ready          : std_logic;
   signal l_valid          : std_logic;
begin

--------------------------------------------------
--
--------------------------------------------------
letch_proc: process(all)
   begin
      l_latch_data <= r_latch_data;
      l_ready      <= r_ready;
      l_valid      <= r_valid;
      if (i_valid and o_ready) = '1' then
         l_latch_data <= i_data;
         l_ready      <= '0';
         l_valid      <= '1';
      end if;

      if (o_valid and i_ready) = '1' then
         l_ready      <= '1';
         l_valid      <= '0';
         l_latch_data <= (others => '0');
         if (i_valid and o_ready) = '1' then
            l_latch_data <= i_data;
            l_valid      <= '1';
         end if;
      elsif i_ready = '1' then
         l_ready      <= '1';
      end if;

   end process; 

reg_proc: process(i_clk)
      variable vr_valid     : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_latch_data <= (others => '0');
            r_ready      <= '0';
            r_valid      <= '0';
         else
            r_latch_data <= l_latch_data;
            r_ready      <= l_ready;
            r_valid      <= l_valid;
         end if;
      end if;
   end process; 

   o_valid <= r_valid;
   o_ready <= r_ready;
   o_data  <= r_latch_data;

end Behavioral;
