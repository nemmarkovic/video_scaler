library ieee;
    use ieee.std_logic_1164.all;

library xpm;
    use xpm.vcomponents.all;

entity fifo is
   generic(
      G_RD_DWIDTH   : integer := 8;
      G_WR_DWIDTH   : integer := 8;
      -- Integer, Range: 16 - 4194304. Default value = 2048
      -- Defines the FIFO Write Depth, must be power of two
      -- NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits. 
      G_FIFO_WDEPTH : integer := 8);
   port (
      i_wr_clk     : in  std_logic;
      i_rd_clk     : in  std_logic;
      -- Reset: Must be synchronous to wr_clk. The clock(s) can be
      -- unstable at the time of applying reset, but reset must be released
      -- only after the clock(s) is/are stable.
      i_rst        : in  std_logic;
      i_dready     : in  std_logic;
      --! Read Data Valid: When asserted, this signal indicates
      --! that valid data is available on the output bus (dout).
      o_dvalid     : out std_logic;
      -- READ_DATA_WIDTH-bit output:
      -- Read Data: The output data bus is driven when reading the FIFO.
      o_dout       : out std_logic_vector(G_RD_DWIDTH -1 downto 0);
      -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
      -- writing the FIFO.
      i_din        : in  std_logic_vector(G_WR_DWIDTH -1 downto 0);
      i_dvalid     : in  std_logic;
      o_dready     : out std_logic);
   end fifo;

architecture Behavioral of fifo is
   -- "auto"- Allow Vivado Synthesis to choose                                                                          |
   -- "block"- Block RAM FIFO                                                                                           |
   -- "distributed"- Distributed RAM FIFO                                                                               |
   -- "ultra"- URAM FIFO   
   constant C_FIFO_MEMORY_TYPE : string := "auto";


   -- input register signals
   signal s_iREGI_rst    : std_logic;
   signal s_iREGI_din    : std_logic_vector(G_WR_DWIDTH -1 downto 0);
   signal s_iREGI_dvalid : std_logic;
   signal s_oREGI_dready : std_logic;
   signal s_iREGI_dready : std_logic;
   signal s_oREGI_dvalid : std_logic;
   signal s_oREGI_dout   : std_logic_vector(G_WR_DWIDTH -1 downto 0);


   -- Write Enable: If the FIFO is not full, asserting this
   -- signal causes data (on din) to be written to the FIFO Must be held
   -- active-low when rst or wr_rst_busy or rd_rst_busy is active high
   signal s_iFIFO_wr_en       : std_logic;
   signal s_iFIFO_rd_en       : std_logic;
   signal s_oFIFO_rd_rst_busy : std_logic;
   signal s_oFIFO_wr_rst_busy : std_logic;
   signal s_oFIFO_ready       : std_logic;
 
   signal s_iFIFO_din         : std_logic_vector(G_WR_DWIDTH -1 downto 0);
   -- Empty Flag: When asserted, this signal indicates that the FIFO is empty.
   -- Read requests are ignored when the FIFO is empty,
   -- initiating a read while empty is not destructive to the FIFO.
   signal s_oFIFO_empty       : std_logic;
      -- Full Flag: When asserted, this signal indicates that the
      -- FIFO is full. Write requests are ignored when the FIFO is full,
      -- initiating a write when the FIFO is full is not destructive to the
      -- contents of the FIFO.
   signal s_oFIFO_full        : std_logic;
      -- Write Acknowledge: This signal indicates that a write
      -- request (wr_en) during the prior clock cycle is succeeded.
   signal s_oFIFO_wr_ack      : std_logic;
   signal s_oFIFO_dvalid      : std_logic;
   signal s_oFIFO_dout        : std_logic_vector(G_RD_DWIDTH -1 downto 0);  



   -- output register signals
   signal s_iREGO_rst    : std_logic;
   signal s_iREGO_din    : std_logic_vector(G_RD_DWIDTH -1 downto 0);
   signal s_iREGO_dvalid : std_logic;
   signal s_oREGO_dready : std_logic;
   signal s_iREGO_dready : std_logic;
   signal s_oREGO_dvalid : std_logic;
   signal s_oREGO_dout   : std_logic_vector(G_RD_DWIDTH -1 downto 0);

   signal s_iREGO1_rst    : std_logic;
   signal s_iREGO1_din    : std_logic_vector(G_RD_DWIDTH -1 downto 0);
   signal s_iREGO1_dvalid : std_logic;
   signal s_oREGO1_dready : std_logic;
   signal s_iREGO1_dready : std_logic;
   signal s_oREGO1_dvalid : std_logic;
   signal s_oREGO1_dout   : std_logic_vector(G_RD_DWIDTH -1 downto 0);
begin

-----------------------------------------------------
--
-----------------------------------------------------
   s_iREGI_rst    <= i_rst;
   s_iREGI_din    <= i_din;
   s_iREGI_dvalid <= i_dvalid;
   s_iREGI_dready <= s_oFIFO_ready;

reg_in_i: entity work.reg
   generic map(
      G_DWIDTH => G_WR_DWIDTH)
   port map(
      i_clk    => i_wr_clk,
      i_rst    => s_iREGI_rst,
      i_data   => s_iREGI_din,
      i_valid  => s_iREGI_dvalid,
      o_ready  => s_oREGI_dready, -- to output for previous stepen
      i_ready  => s_iREGI_dready,
      o_valid  => s_oREGI_dvalid,
      o_data   => s_oREGI_dout);

-----------------------------------------------------
--
-----------------------------------------------------
   s_iFIFO_wr_en <= s_oREGI_dvalid and s_oFIFO_ready;
   s_iFIFO_din   <= s_oREGI_dout;

   -- 1 Must be held active-low when rd_rst_busy is active high.
   s_iFIFO_rd_en <= i_dready and s_oREGO_dready and not(s_oFIFO_empty) and not(s_oFIFO_rd_rst_busy); -- s_oREGO_dready 

   -- xpm_fifo_sync: Synchronous FIFO
   -- Xilinx Parameterized Macro, version 2020.1
xpm_fifo_sync_i : xpm_fifo_sync
   generic map (
      DOUT_RESET_VALUE    => "0",
      ECC_MODE            => "no_ecc",
      FIFO_MEMORY_TYPE    => C_FIFO_MEMORY_TYPE,
      FIFO_READ_LATENCY   => 0,
      FIFO_WRITE_DEPTH    => G_FIFO_WDEPTH,   -- In standard READ_MODE, the effective depth = FIFO_WRITE_DEPTH
      FULL_RESET_VALUE    => 0,               -- In FWFT READ_MODE     , the effective depth = FIFO_WRITE_DEPTH+2  
      PROG_EMPTY_THRESH   => 10,
      PROG_FULL_THRESH    => 10,
      RD_DATA_COUNT_WIDTH => 1,
      READ_DATA_WIDTH     => G_RD_DWIDTH,
      READ_MODE           => "fwft", --"std", --
      SIM_ASSERT_CHK      => 1,
      USE_ADV_FEATURES    => "1707",
      WAKEUP_TIME         => 0,
      WRITE_DATA_WIDTH    => G_WR_DWIDTH,
      WR_DATA_COUNT_WIDTH => 1)
   port map (
      almost_empty => open, 
      almost_full  => open,
      data_valid   => s_oFIFO_dvalid,
      dbiterr      => open,
      dout         => s_oFIFO_dout,
      empty        => s_oFIFO_empty,
      full         => s_oFIFO_full,
      overflow     => open, 
      prog_empty   => open,
      prog_full    => open,
      rd_data_count=> open,
      rd_rst_busy  => s_oFIFO_rd_rst_busy,
      sbiterr      => open,
      underflow    => open,
      wr_ack       => s_oFIFO_wr_ack, 
      wr_data_count=> open,
      wr_rst_busy  => s_oFIFO_wr_rst_busy,
      din          => s_iFIFO_din,
      injectdbiterr=> '0', 
      injectsbiterr=> '0',
      rd_en        => s_iFIFO_rd_en,
      rst          => i_rst, 
      sleep        => '0',
      wr_clk       => i_wr_clk,
      wr_en        => s_iFIFO_wr_en);

    s_oFIFO_ready <= not(s_oFIFO_wr_rst_busy or s_oFIFO_full);


-----------------------------------------------------
--
-----------------------------------------------------
   s_iREGO_rst    <= i_rst or s_oFIFO_rd_rst_busy;
   s_iREGO_din    <= s_oFIFO_dout;
   s_iREGO_dvalid <= s_oFIFO_dvalid;
   s_iREGO_dready <= i_dready and s_oREGO1_dready;      -- next module ready - reead the data

reg_out_i: entity work.reg
   generic map(
      G_DWIDTH => G_RD_DWIDTH)
   port map(
      i_clk    => i_rd_clk,
      i_rst    => s_iREGO_rst,
      i_data   => s_iREGO_din,
      i_valid  => s_iREGO_dvalid,
      o_ready  => s_oREGO_dready,
      i_ready  => s_iREGO_dready,
      o_valid  => s_oREGO_dvalid,
      o_data   => s_oREGO_dout);

-----------------------------------------------------
--
-----------------------------------------------------
   s_iREGO1_rst    <= i_rst or s_oFIFO_rd_rst_busy;
   s_iREGO1_din    <= s_oREGO_dout;
   s_iREGO1_dvalid <= s_oREGO_dvalid;
   s_iREGO1_dready <= i_dready;      -- next module ready - reead the data

reg_out1_i: entity work.reg
   generic map(
      G_DWIDTH => G_RD_DWIDTH)
   port map(
      i_clk    => i_rd_clk,
      i_rst    => s_iREGO1_rst,
      i_data   => s_iREGO1_din,
      i_valid  => s_iREGO1_dvalid,
      o_ready  => s_oREGO1_dready,
      i_ready  => s_iREGO1_dready,
      o_valid  => s_oREGO1_dvalid,
      o_data   => s_oREGO1_dout);

-----------------------------------------------------------
--
-----------------------------------------------------------
   o_dready <= s_oREGI_dready;
   o_dvalid <= s_oREGO1_dvalid;
   o_dout   <= s_oREGO1_dout;
end Behavioral;
