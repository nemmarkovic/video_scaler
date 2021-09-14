-----------------------------------------------------------------------------------
-- file name   : ea_scaler
-- module      : scaler
-- author      : Nebojsa Markovic
-- emaill      : mnebojsa.etf@gmail.com
-- date        : september 1st, 2021
-----------------------------------------------------------------------------------
-- description :
--        The module takes video frame from axi stream, resizes it and gives back
--        resized vide on the output axi stream interface
-----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;

    use work.p_axi.all;

library common_lib;
    use common_lib.p_common.all;

entity ea_scaler is
    generic (
      G_MANTISA_WIDTH : integer range 1 to 64 :=    8;
      G_PRESISION     : integer range 1 to 64 :=    6; --= clog2(G_TAP_NO)
      G_TAP_NO        : integer range 2 to 64 :=   64;
      G_IN_SIZE_Y     : integer               :=  448;
      G_OUT_SIZE_Y    : integer               := 1024; --2048;
      G_IN_SIZE_X     : integer               :=  448;
      G_OUT_SIZE_X    : integer               := 1024; --2048;
      -- AXI Data Width
      DWIDTH          : integer               :=    8);
	port (
      axi_aclk    : in std_logic;
      axi_aresetn : in std_logic;
      -- axi in
      s_axis_in   : in  t_axis_s_in;--(tdata(DWIDTH -1 downto 0));
      s_axis_out  : out t_axis_s_out;
	  -- axi_out
	  m_axis_in   : in  t_axis_m_in;
	  m_axis_out  : out t_axis_m_out);
end ea_scaler;

architecture Behavioral of ea_scaler is
   -- string to row signals
   signal s_oST2ROW_colmun        : std_logic_vector(11-1 downto 0);
   signal s_oST2ROW_valid         : std_logic;
   signal s_iST2ROW_ready         : std_logic;
   signal s_oST2ROW_pix           : t_dinfo(data(0 to 1)(G_MANTISA_WIDTH -1 downto 0));
   
   -- vertical filter signals
   signal s_iVFILT_rst            : std_logic;
   signal s_oVFILT_ready          : std_logic;
   signal s_iVFILT_valid          : std_logic;

   signal s_iVFILT_ready          : std_logic;
   signal s_oVFILT_valid          : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_iVFILT_pix            : t_dinfo(data(0 to 1)(G_MANTISA_WIDTH -1 downto 0));
   signal s_iVFILT_colmun         : std_logic_vector(11-1 downto 0);
   signal s_oVFILT_pix            : t_dinfo_array(0 to G_TAP_NO-1)(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));

   -- fifo bank signals
   signal s_iFBANK_rst            : std_logic;

   signal s_oFBANK_dready         : std_logic;
   signal s_iFBANK_dvalid         : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_oFBANK_dvalid         : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_iFBANK_pix            : t_dinfo_array(0 to G_TAP_NO-1)(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));

   signal s_oFBANK_pix            : t_dinfo_array(0 to G_TAP_NO-1)(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));
   signal s_iFBANK_dready         : std_logic_vector(G_TAP_NO -1 downto 0);

   -- switch signals
   signal s_iSW_rst               : std_logic;

   signal s_iSW_valid             : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_oSW_ready             : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_iSW_pix               : t_dinfo_array(0 to G_TAP_NO-1)(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));

   signal s_oSW_pix               : t_dinfo(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));
   signal s_iSW_ready             : std_logic;
   signal s_oSW_valid             : std_logic;


   -- registers rows to pixel pairs for horisontal filter
   signal s_iHFREG1_rst    : std_logic;
   signal s_iHFREG1_data   : std_logic_vector(G_MANTISA_WIDTH +2 -1 downto 0);
   signal s_oHFREG1_data   : std_logic_vector(G_MANTISA_WIDTH +2 -1 downto 0);
   signal s_iHFREG1_valid  : std_logic;
   signal s_oHFREG1_ready  : std_logic;
   signal s_iHFREG1_ready  : std_logic;
   signal s_oHFREG1_valid  : std_logic;

   signal s_iHFREG2_rst    : std_logic;
   signal s_iHFREG2_data   : std_logic_vector(G_MANTISA_WIDTH +2 -1 downto 0);
   signal s_oHFREG2_data   : std_logic_vector(G_MANTISA_WIDTH +2 -1 downto 0);
   signal s_iHFREG2_valid  : std_logic;
   signal s_oHFREG2_ready  : std_logic;
   signal s_iHFREG2_ready  : std_logic;
   signal s_oHFREG2_valid  : std_logic;

   -- adjustment 
   signal s_iADJ_rst        : std_logic;
   signal s_oADJ_ready      : std_logic;
   signal s_iADJ_valid      : std_logic;
   signal s_iADJ_pix        : t_dinfo(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));
   signal s_oADJ_pix        : t_dinfo(data(0 to 1)(G_MANTISA_WIDTH -1 downto 0));
   signal s_iADJ_ready      : std_logic;
   signal s_oADJ_valid      : std_logic;
   signal s_oADJ_row_num    : std_logic_vector(11-1 downto 0);


   -- horisontal filter signals
   signal s_iHFILT_rst            : std_logic;
   signal s_oHFILT_ready          : std_logic;
   signal s_iHFILT_valid          : std_logic;

   signal s_iHFILT_ready          : std_logic;
   signal s_oHFILT_valid          : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_iHFILT_pix            : t_dinfo(data(0 to 1)(G_MANTISA_WIDTH -1 downto 0));
   signal s_iHFILT_row            : std_logic_vector(11-1 downto 0);
   signal s_oHFILT_pix            : t_dinfo_array(0 to G_TAP_NO-1)(data(0 to 0)(G_MANTISA_WIDTH -1 downto 0));


   signal s_iFIFO_rst             : std_logic;
   signal s_iFIFO_valid           : std_logic_vector(G_TAP_NO -1 downto 0);
   signal s_oFIFO_ready           : std_logic;
   signal s_iFIFO_pix             : std_logic_vector(G_TAP_NO * (G_MANTISA_WIDTH +2) -1 downto 0);
   signal s_oFIFO_pix             : std_logic_vector(2*(G_MANTISA_WIDTH +2)              -1 downto 0);
   signal s_oFIFO_valid           : std_logic;
   signal s_iFIFO_ready           : std_logic;

begin

----------------------------------------------
-- Stream To Row instance
-- The Module buffers stream data 
-- Module outputs are 2 pixels on the same x
-- and neigbour y
----------------------------------------------
s_iST2ROW_ready <= s_oVFILT_ready;

stream_to_rows_i: entity work.stream_to_rows
   generic map(
      G_PIX_WIDTH    => DWIDTH,
      G_MAX_ROW_SIZE  => 1024)--2048)
   port map( 
      s_axis_aclk    => axi_aclk,
      s_axis_arst_n  => axi_aresetn,
      s_axis_in      => s_axis_in,
      s_axis_out     => s_axis_out,

      i_ready        => s_iST2ROW_ready,
      o_valid        => s_oST2ROW_valid,
      o_position     => s_oST2ROW_colmun,
      o_pix          => s_oST2ROW_pix);

----------------------------------------------
-- Vertical filter
-- Takes pixel pair and as a result gives 
-- output pixels generated from the ones on
-- the input and colmun info
----------------------------------------------
   s_iVFILT_rst    <= not(axi_aresetn);
   s_iVFILT_valid  <= s_oST2ROW_valid;
   s_iVFILT_pix    <= s_oST2ROW_pix;
   s_iVFILT_colmun <= s_oST2ROW_colmun;
   s_iVFILT_ready  <= s_oFBANK_dready;

vert_filter_i: entity work.bilinear_flt
   generic map(
      G_MANTISA_WIDTH => G_MANTISA_WIDTH,
      G_PRESISION     => G_PRESISION,
      G_TAP_NO        => G_TAP_NO,
      G_IN_SIZE       => G_IN_SIZE_Y,
      G_OUT_SIZE      => G_OUT_SIZE_Y)
   port map( 
      i_clk           => axi_aclk,
      i_rst           => s_iVFILT_rst,

      o_ready         => s_oVFILT_ready,
      i_valid         => s_iVFILT_valid,
      i_pix           => s_iVFILT_pix,
      i_position      => s_iVFILT_colmun,

      i_ready         => s_iVFILT_ready,
      o_valid         => s_oVFILT_valid,
      o_pix           => s_oVFILT_pix);

----------------------------------------------
-- Fifo bank
-- Catches result pixels from vertical bilinear
-- filter
----------------------------------------------
s_iFBANK_rst      <= not(axi_aresetn);
s_iFBANK_dvalid   <= s_oVFILT_valid;
s_iFBANK_pix      <= s_oVFILT_pix;
s_iFBANK_dready   <= s_oSW_ready;


fifo_bank_i : entity work.fifo_bank
   generic map(
      G_RD_DWIDTH   => G_MANTISA_WIDTH,
      G_WR_DWIDTH   => G_MANTISA_WIDTH,
      G_TAP_NO      => G_TAP_NO,
      G_FIFO_WDEPTH => C_MAX_IMAGE_DIM)
   port map(
      i_wr_clk => axi_aclk,
      i_rd_clk => axi_aclk,
      i_rst    => s_iFBANK_rst,

      o_dready => s_oFBANK_dready,
      i_valid  => s_iFBANK_dvalid,
      i_din    => s_iFBANK_pix,

      o_dout   => s_oFBANK_pix,
      o_valid  => s_oFBANK_dvalid,
      i_dready => s_iFBANK_dready);

----------------------------------------------
-- Priority Coder Switch
-- Used to read valid data from fifo_bank
-- row by row
----------------------------------------------
   s_iSW_rst     <= not(axi_aresetn);
   s_iSW_valid   <= s_oFBANK_dvalid;
   s_iSW_pix     <= s_oFBANK_pix;
   s_iSW_ready   <= s_oHFREG1_ready;

pc_switch_i : entity work.pc_switch
    generic map(
      G_DWIDTH    => G_MANTISA_WIDTH,
      G_NO_INPUT  => G_TAP_NO)
    port map(
       i_clk      => axi_aclk,
       i_rst      => s_iSW_rst,

       o_ready    => s_oSW_ready,
       i_valid    => s_iSW_valid,
       i_pix      => s_iSW_pix,

       o_pix      => s_oSW_pix,
       o_valid    => s_oSW_valid,
       i_ready    => s_iSW_ready);


-------------------------------------------------------
--
-------------------------------------------------------
   s_iADJ_rst      <= not(axi_aresetn);
   s_iADJ_valid    <= s_oSW_valid;
   s_iADJ_pix      <= s_oSW_pix;
   s_iADJ_ready    <= s_oHFILT_ready;
 
adj_i : entity work.adj
   generic map(
      G_DWIDTH => G_MANTISA_WIDTH)
   port map( 
      i_clk           => axi_aclk,
      i_rst           => s_iADJ_rst,
      o_ready         => s_oADJ_ready,
      i_valid         => s_iADJ_valid, 
      i_pix           => s_iADJ_pix,      
      o_pix           => s_oADJ_pix,   
      i_ready         => s_iADJ_ready, 
      o_valid         => s_oADJ_valid, 
      o_position      => s_oADJ_row_num);


----------------------------------------------
-- 
----------------------------------------------
   s_iHFILT_rst         <= not(axi_aresetn);
   s_iHFILT_valid       <= s_oHFREG1_valid and s_oHFREG2_valid;
   s_iHFILT_pix.data(0) <= s_oHFREG1_data(G_MANTISA_WIDTH -1 downto 0);
   s_iHFILT_pix.data(1) <= s_oHFREG2_data(G_MANTISA_WIDTH -1 downto 0);
   s_iHFILT_row         <= s_oADJ_row_num;
   s_iHFILT_ready       <= s_oFIFO_ready;

horiz_filter_i: entity work.bilinear_flt
   generic map(
      G_MANTISA_WIDTH => G_MANTISA_WIDTH,
      G_PRESISION     => G_PRESISION,
      G_TAP_NO        => G_TAP_NO,
      G_IN_SIZE       => G_IN_SIZE_Y,
      G_OUT_SIZE      => G_OUT_SIZE_Y)
   port map( 
      i_clk           => axi_aclk,
      i_rst           => s_iHFILT_rst,

      o_ready         => s_oHFILT_ready,
      i_valid         => s_iHFILT_valid,
      i_pix           => s_iHFILT_pix,
      i_position      => s_iHFILT_row,

      i_ready         => s_iHFILT_ready,
      o_valid         => s_oHFILT_valid,
      o_pix           => s_oHFILT_pix);


---------------------------------------------------------------
--
---------------------------------------------------------------
   s_iFIFO_rst     <= not(axi_aresetn);
   s_iFIFO_valid   <= s_oHFILT_valid;
gen_array:
   for gen_arr in 0 to G_TAP_NO -1 generate
      s_iFIFO_pix((gen_arr +1)*(G_MANTISA_WIDTH +2) -1 downto gen_arr *(G_MANTISA_WIDTH +2) )     <= s_oHFILT_pix(gen_arr).data(0) & s_oHFILT_pix(gen_arr).last & s_oHFILT_pix(gen_arr).eof;
   end generate;

   s_iFIFO_ready   <= m_axis_in.tready;

fifo_scaler_i : entity work.fifo
   generic map(
      G_WR_DWIDTH   => G_TAP_NO * (G_MANTISA_WIDTH +2),
      G_RD_DWIDTH   => 2*(G_MANTISA_WIDTH +2),
      G_FIFO_WDEPTH => 128)
   port map(
       i_wr_clk   => axi_aclk,
       i_rd_clk   => axi_aclk, 
       i_rst      => s_iFIFO_rst,
       i_dvalid   => or s_iFIFO_valid,
       o_dready   => s_oFIFO_ready,
       i_din      => s_iFIFO_pix,
       o_dout     => s_oFIFO_pix,
       o_dvalid   => s_oFIFO_valid,
       i_dready   => s_iFIFO_ready);

-------------------------------------------------------------------------
--
-------------------------------------------------------------------------
   m_axis_out.tdata  <= s_oFIFO_pix(G_MANTISA_WIDTH +2 -1 downto 2);
   m_axis_out.tvalid <= s_oFIFO_valid;
   m_axis_out.tlast  <= s_oFIFO_pix(1);
   m_axis_out.tuser  <= s_oFIFO_pix(0);


end Behavioral;
