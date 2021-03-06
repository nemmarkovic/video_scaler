library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.numeric_STD.ALL;
    use IEEE.math_real.all;

library common_lib;
    use common_lib.p_common.all;

entity pc_switch is
    generic (
      G_DWIDTH        : positive :=  8;
      G_NO_INPUT      : positive :=  64);
    port (
       i_clk     : in  std_logic;
       i_rst     : in  std_logic;

       i_valid   : in  std_logic_vector(G_NO_INPUT -1 downto 0);
       o_ready   : out std_logic_vector(G_NO_INPUT -1 downto 0);
       i_pix     : in  t_dinfo_array(0 to G_NO_INPUT -1)(data(0 to 0)(G_DWIDTH -1 downto 0));

       i_ready   : in  std_logic;
       o_valid   : out std_logic;
       o_pix     : out t_dinfo(data(0 to 0)(G_DWIDTH -1 downto 0)));--(data(G_DWIDTH   -1 downto 0)));
   end pc_switch;

architecture Behavioral of pc_switch is

    signal s_cnt      : unsigned(integer(ceil(log2(real(G_NO_INPUT)))) -1 downto 0);
    signal s_valid    : std_logic;

    signal s_ready    : std_logic_vector(G_NO_INPUT -1 downto 0);
    signal s_oREG_ready    : std_logic_vector(G_NO_INPUT -1 downto 0);
    signal s_oREG_valid    : std_logic_vector(G_NO_INPUT -1 downto 0);
    signal s_oREG_data     : t_byte_array(0 to G_NO_INPUT -1)(G_DWIDTH +2 -1 downto 0);

    signal s_oREGO_ready    : std_logic;
    signal s_oREGO_dout     : std_logic_vector(G_DWIDTH -1 downto 0);
begin

in_reg_gen:
   for gen_ver in 0 to G_NO_INPUT -1 generate
      reg_in: entity work.reg
         generic map(
            G_DWIDTH => G_DWIDTH +2)
         port map(
            i_clk   => i_clk,
            i_rst   => i_rst,
            i_data  => i_pix(gen_ver).data(0) & i_pix(gen_ver).last & i_pix(gen_ver).eof, --in  std_logic_vector(G_DWIDTH -1 downto 0);
            i_valid => i_valid(gen_ver),
            o_ready => s_oREG_ready(gen_ver),
            i_ready => s_ready(gen_ver),
            o_valid => s_oREG_valid(gen_ver),
            o_data  => s_oREG_data(gen_ver));
      end generate;


gen_din: process(i_clk)
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            s_cnt      <= (others => '0');
            s_ready    <= (others => '0');
            s_valid    <= '0';
         else
            s_ready    <= (others => '0');
            s_ready(to_integer(s_cnt)) <= i_ready;

            if i_pix(to_integer(s_cnt)).last = '1' and i_pix(to_integer(s_cnt)).eof = '1' then
               s_cnt      <= (others => '0');
            elsif i_pix(to_integer(s_cnt)).last = '1' then
               s_cnt      <= s_cnt +1;
            end if;
         end if;
      end if;
   end process;
-----------------------------------------------------------------------------------------------------------
-- outputs assignment
-----------------------------------------------------------------------------------------------------------
   o_ready        <= s_oREG_ready;

   o_pix.data(0)  <= s_oREG_data(to_integer(s_cnt))(G_DWIDTH +2 -1 downto 2);
   o_pix.last     <= s_oREG_data(to_integer(s_cnt))(1);
   o_pix.eof      <= s_oREG_data(to_integer(s_cnt))(0);
   o_valid        <= s_oREG_valid(to_integer(s_cnt));
end Behavioral;
