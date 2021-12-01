-----------------------------------------------------------------------------------
-- file name   : ea_bilinear_flt
-- module      : bilinear_flt
-- author      : Nebojsa Markovic
-- emaill      : mnebojsa.etf@gmail.com
-- date        : september 1st, 2021
-----------------------------------------------------------------------------------
-- description :
--        Based on the input pixel pair, pixel pair possition in the original image
--        and scaling factor gives resultat pixels for the result image
-----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;

library common_lib;
    use common_lib.p_common.all;

entity video_scaler is
   generic(
      G_IN_SIZE       : integer               :=  446;
      G_OUT_SIZE      : integer               := 2048;
      G_PHASE_NUM     : integer range 2 to C_MAX_PHASE_NUM := 4;
      G_DWIDTH        : integer range 1 to 64 :=    8);
   port ( 
      -- input clk
      i_clk     : in  std_logic;
      -- input reset
      i_rst     : in  std_logic;
      -- input pixel data
      -- pix0
      -- pix1
      -- last  : std_logic; 
      -- eof   : std_logic;
      i_pix      : in  t_in_pix;

      i_ready   : in  std_logic;
      o_pix     : out t_out_pix
      
      );
   end video_scaler;

architecture Behavioral of video_scaler is

begin

uut_bilinear_flt_i: entity work.bilinear_flt 
   generic map (
      G_IN_SIZE   => G_IN_SIZE,
      G_OUT_SIZE  => G_OUT_SIZE,
      G_PHASE_NUM => G_PHASE_NUM,
      G_DWIDTH    => G_DWIDTH )
   port map (
      i_clk       => i_clk,
      i_rst       => i_rst,
      o_ready     => open, -- : out std_logic;
      i_pix       => i_pix,
      i_ready     => (others => '0'), --from fifo bank : in  std_logic_vector(0 to G_PHASE_NUM -1);
      o_pix       => open); --: out t_out_pix_array);





fifo_bank_i: entity work.fifo_bank
   generic(
      G_RD_DWIDTH   = >
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







pc_switch_i: entity work.pc_switch
    generic map(
      G_DWIDTH    => G_DWIDTH,
      G_NO_INPUT  => G_PHASE_NUM)
    port map(
      i_clk       => i_clk,
      i_rst       => i_rst,

      i_valid     => (others => '0'), --: in  std_logic_vector(G_NO_INPUT -1 downto 0);
      o_ready     => open, -- : out std_logic_vector(G_NO_INPUT -1 downto 0);
      i_pix       => (others => t_out_pix_rst), --: in  t_out_pix_array;

      i_ready     => i_ready,
      o_pix       => o_pix);


end Behavioral;
