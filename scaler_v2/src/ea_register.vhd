library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

entity reg is
   generic(
      G_DWIDTH : positive := 8);
   port (
      i_clk   : in  std_logic;
      i_rst   : in  std_logic;
      i_data  : in  std_logic_vector(G_DWIDTH -1 downto 0);
      i_valid : in  std_logic;
      o_ready : out std_logic;
      i_ready : in  std_logic;
      o_valid : out std_logic;
      o_data  : out std_logic_vector(G_DWIDTH -1 downto 0));
   end reg;

architecture Behavioral of reg is
   signal s_reg_data : std_logic_vector(G_DWIDTH -1 downto 0);
   signal s_ovalid   : std_logic;
   signal s_dstored  : std_logic;
begin

reg_proc: process(i_clk)
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            s_reg_data <= (others => '0');
            s_ovalid   <= '0';
            s_dstored  <= '0';
         elsif i_valid = '1' and s_dstored = '0' then
            s_reg_data <= i_data;
            s_ovalid   <= '1';
            s_dstored  <= '1';
         elsif i_valid = '1' and i_ready = '1' then
            s_reg_data <= i_data;
            s_ovalid   <= '1';
            s_dstored  <= '1';
         elsif i_valid = '0' and i_ready = '1' and s_dstored = '1' then
            s_reg_data <= (others => '0');
            s_ovalid   <= '0';
            s_dstored  <= '0';
         elsif s_dstored = '0' then
            s_reg_data <= (others => '0');
            s_ovalid   <= '0';
            s_dstored  <= '0';
         end if;
      end if;
   end process;

   o_ready <= i_ready or not(s_dstored);
   o_valid <= s_ovalid;
   o_data  <= s_reg_data;

end Behavioral;
