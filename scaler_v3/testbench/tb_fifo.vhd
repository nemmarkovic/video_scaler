library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity tb_fifo is
     generic(
        G_RD_DWIDTH   : integer := 8;
        G_WR_DWIDTH   : integer := 8;
        G_FIFO_WDEPTH : integer := 16);
   end;

architecture bench of tb_fifo is

  signal i_rst   : std_logic;
  signal i_dready: std_logic;
  signal o_dvalid: std_logic;
  signal o_dout  : std_logic_vector(G_RD_DWIDTH -1 downto 0);
  signal i_din   : std_logic_vector(G_WR_DWIDTH -1 downto 0);
  signal i_dvalid: std_logic;
  signal o_dready: std_logic;

  signal l_dready: std_logic;
  signal l_din   : std_logic_vector(G_WR_DWIDTH -1 downto 0);
  signal l_dvalid: std_logic;

   signal i_clk   : std_logic;

   constant clk_period : time := 10 ns;
begin

  -- Insert values for generic parameters !!
uut_fifo: entity work.fifo
   generic map (
      G_RD_DWIDTH   => G_RD_DWIDTH,
      G_WR_DWIDTH   => G_WR_DWIDTH,
      G_FIFO_WDEPTH => G_FIFO_WDEPTH )
   port map (
      i_wr_clk      => i_clk,
      i_rd_clk      => i_clk,
      i_rst         => i_rst,
      i_dready      => i_dready,
      o_dvalid      => o_dvalid,
      o_dout        => o_dout,
      i_din         => i_din,
      i_dvalid      => i_dvalid,
      o_dready      => o_dready );


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
     wait until rising_edge(i_clk);
        i_rst <= '0';
     wait;
  end process;



  stimulus_comb: process(all)
   begin
      l_dready <= i_dready;
      l_dvalid <= i_dvalid;
      l_din    <= i_din;   
     -- if (i_dvalid and o_dready) = '1' then
          l_dvalid <= '1';
     -- end if;
   end process;

   
  stimulus: process(i_clk)
      variable vr_start : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            i_dready         <= '0';
            i_dvalid         <= '0';
            i_din            <= (others => '0');
            vr_start         := '0';
         else
            i_din    <= l_din;
            i_dvalid <= l_dvalid;
            if l_dvalid = '1' then
               i_din   <= std_logic_vector(unsigned(l_din) + 1);
            end if;
            i_dready <= not l_dready;
            if vr_start = '0' then
               i_dready     <= '0';
               vr_start     := '1';
            end if;
         end if;
      end if;
   end process;

end;
