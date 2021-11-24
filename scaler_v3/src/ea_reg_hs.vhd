library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

entity reg_hs is
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
   end reg_hs;

architecture Behavioral of reg_hs is
   signal r_reg_data : std_logic_vector(G_DWIDTH -1 downto 0);
   signal l_reg_data : std_logic_vector(G_DWIDTH -1 downto 0);

   signal l_dvalid   : std_logic;
   signal r_dvalid   : std_logic;

   signal r_dready   : std_logic;
   signal l_dready   : std_logic;
begin



comb_proc: process(all)
      variable vl_valid    : std_logic;
      variable vl_data     : std_logic_vector(G_DWIDTH -1 downto 0);
      variable vl_dready   : std_logic;
   begin
      vl_data       := r_reg_data;
      vl_valid      := r_dvalid;
      vl_dready     := r_dready;

      if i_rst = '0' then
      -- side i_ready i_valid
      if (r_dvalid and not(i_ready)) = '1' then
         vl_dready := '0';
      elsif (r_dvalid and i_ready and i_valid) = '1' then
         vl_dready := '1';
      elsif not(r_dvalid) = '1' then
         vl_dready := '1';
      end if;

      if (i_valid and not(r_dvalid)) = '1' then
         vl_valid  := '1';
         vl_data   := i_data; 
      elsif (i_valid and r_dvalid and i_ready) = '1' then
         vl_valid  := '1';
         vl_data   := i_data;
      elsif (not(i_valid) and i_ready) = '1' then
         vl_valid  := '0';
      end if;
      end if;

      l_reg_data     <= vl_data;
      l_dvalid       <= vl_valid;
      l_dready       <= vl_dready;
   end process;


reg_proc: process(i_clk)
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            r_reg_data <= (others => '0');
            r_dvalid   <= '0';
            r_dready   <= '0';
         else
            r_reg_data <= l_reg_data;
            r_dvalid   <= l_dvalid;
            r_dready   <= l_dready;
         end if;
      end if;
   end process;

   o_ready <= l_dready;
   o_valid <= r_dvalid;
   o_data  <= r_reg_data;

end Behavioral;
