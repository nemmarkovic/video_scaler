library ieee;
    use ieee.std_logic_1164.all;

library common_lib;
    use common_lib.p_common.all;

entity fifo_bank is
   generic(
      G_RD_DWIDTH   : integer :=  8;
      G_WR_DWIDTH   : integer :=  8;
      G_PHASE_NUM     : integer range 2 to C_MAX_PHASE_NUM := 4;
      -- Integer, Range: 16 - 4194304. Default value = 2048
      -- Defines the FIFO Write Depth, must be power of two
      -- NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits. 
      G_FIFO_WDEPTH : integer := 2048);
   port (
      i_wr_clk     : in  std_logic;
      i_rd_clk     : in  std_logic;
      -- Reset: Must be synchronous to wr_clk. The clock(s) can be
      -- unstable at the time of applying reset, but reset must be released
      -- only after the clock(s) is/are stable.
      i_rst        : in  std_logic;
      -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
      -- writing the FIFO.
      o_dready     : out std_logic;
      i_valid      : in  std_logic_vector(G_PHASE_NUM -1 downto 0);
      -- output pixel data
      -- data = pix0[G_MANTISA_WIDTH -1 : -G_PRESISION], 
      -- last  : std_logic; 
      -- eof   : std_logic;
      i_din        : in  t_out_pix_array;
      --! Read Data Valid: When asserted, this signal indicates
      --! that valid data is available on the output bus (dout).
      -- READ_DATA_WIDTH-bit output:
      -- Read Data: The output data bus is driven when reading the FIFO.
      o_dout       : out t_out_pix_array;
      o_valid      : out std_logic_vector(G_PHASE_NUM -1 downto 0);
      i_dready     : in  std_logic_vector(G_PHASE_NUM -1 downto 0));
   end fifo_bank;

architecture Behavioral of fifo_bank is
   signal s_oFIFO_data   : std_logic_vector((G_RD_DWIDTH +3) * G_PHASE_NUM -1 downto 0);
   signal s_iFIFO_data   : std_logic_vector((G_WR_DWIDTH +3) * G_PHASE_NUM -1 downto 0);
   signal s_oFIFO_dvalid : std_logic_vector(G_PHASE_NUM -1 downto 0);
   signal s_iFIFO_dvalid : std_logic_vector(G_PHASE_NUM -1 downto 0);
   signal s_oFIFO_ready  : std_logic_vector(G_PHASE_NUM -1 downto 0);
   signal s_iFIFO_ready  : std_logic_vector(G_PHASE_NUM -1 downto 0);
begin

fifo_bank_gen:
   for gen_var in 0 to G_PHASE_NUM -1 generate
      s_iFIFO_ready(gen_var)  <= i_dready(gen_var);

      s_iFIFO_dvalid(gen_var) <= i_valid(gen_var);
      s_iFIFO_data((gen_var +1) * (G_WR_DWIDTH +3) -1 downto gen_var * (G_WR_DWIDTH +3)) <= i_din(gen_var).pix & i_din(gen_var).last & i_din(gen_var).sof & i_valid(gen_var);

      fifo_i: entity work.fifo
         generic map(
            G_RD_DWIDTH   => G_RD_DWIDTH +3,
            G_WR_DWIDTH   => G_WR_DWIDTH +3,
            G_FIFO_WDEPTH => G_FIFO_WDEPTH)
         port map(
            i_wr_clk      => i_wr_clk,
            i_rd_clk      => i_rd_clk,
            i_rst         => i_rst,
            i_din         => s_iFIFO_data((gen_var +1) * (G_WR_DWIDTH +3) -1 downto gen_var * (G_WR_DWIDTH +3)),
            o_dout        => s_oFIFO_data((gen_var +1) * (G_RD_DWIDTH +3) -1 downto gen_var * (G_RD_DWIDTH +3)),
            o_dvalid      => s_oFIFO_dvalid(gen_var),
            i_dvalid      => s_iFIFO_dvalid(gen_var),
            o_dready      => s_oFIFO_ready(gen_var),
            i_dready      => s_iFIFO_ready(gen_var));
      end generate;

-------------------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------------------
fifo_k_gen:
   for gen_var in 0 to G_PHASE_NUM -1 generate
      o_dout(gen_var).pix      <= s_oFIFO_data((gen_var +1) * (G_RD_DWIDTH +3) -1 downto gen_var * (G_RD_DWIDTH +3) +3);
      o_dout(gen_var).last     <= s_oFIFO_data(gen_var * (G_RD_DWIDTH +3) +2);
      o_dout(gen_var).sof      <= s_oFIFO_data(gen_var * (G_RD_DWIDTH +3) +1);
      o_valid(gen_var)         <= s_oFIFO_data(gen_var * (G_RD_DWIDTH +3));
   end generate;

o_dready   <= and(s_oFIFO_ready);

end Behavioral;
