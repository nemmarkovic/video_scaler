-----------------------------------------------------------------------------------
-- file name   : ea_stream_to_rows
-- module      : stream to rows
-- author      : Nebojsa Markovic
-- emaill      : mnebojsa.etf@gmail.com
-- date        : september 1st, 2021
-----------------------------------------------------------------------------------
-- description :
--        The module buffers data from stream (axi stream supported currently) and
--        on the output gives pair of two pixels placed in the same colmun and in
--        neghbour rows.
--        It is expected to receive the pixels in the fashion depicdted bellow:
--        start: 1 -> 2 -> 3 ->4 ->
--               5 -> 6 -> 7 ->8 ->
--                     . . .
--        On the modules output pixels will appear in pairs in the following order
--         
--         . . . (4), (3), (2), (1) -> first pair
--               (8)  (7)  (6)  (5) ->
--        Other info available on the outputs are: 
--         * last      : equals to '1' if last pixel pair from current rows is on
--                       the output
--         * eof       : '1' if last tow pair from the frame is on the module output
--                       frame ends when last = '1' and eof = '1'
--         * possition : current row pair number( starts from zero)
--        The module uses hand-shake for comunication with other modules
-----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.p_axi.all;

library common_lib;
    use common_lib.p_common.all;

entity stream_to_rows is
   generic(
      G_PIX_WIDTH    : integer := 8;
      -- Integer, Range: 16 - 4194304. Default value = 2048
      -- Defines the FIFO Write Depth, must be power of two
      -- NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits. 
      G_MAX_ROW_SIZE : integer := 2048);
   port ( 
		s_axis_aclk	    : in  std_logic;
		s_axis_arst_n	: in  std_logic;
        -- AXI Stream, Slave interface
        s_axis_in       : in  t_axis_s_in;
        s_axis_out      : out t_axis_s_out;

        -- next moule ready to accept the data
        i_ready         : in  std_logic;
        -- output pixel
        -- contains stream info: last, eof
        -- pixel pair (pix0, pix1)
        o_pix           : out t_in_pix);
   end stream_to_rows;

architecture Behavioral of stream_to_rows is
   -- input register signals
   signal s_iREG1_rst    : std_logic;
   signal s_iREG1_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0);
   signal s_oREG1_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0);
   signal s_iREG1_valid  : std_logic;
   signal s_oREG1_ready  : std_logic;
   signal s_iREG1_ready  : std_logic;
   signal s_oREG1_valid  : std_logic;

   signal s_iREG2_rst    : std_logic;
   signal s_iREG2_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0);
   signal s_oREG2_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0);
   signal s_iREG2_valid  : std_logic;
   signal s_oREG2_ready  : std_logic;
   signal s_iREG2_ready  : std_logic;
   signal s_oREG2_valid  : std_logic;

   -- fifo signals
   signal s_iFIFO_rst    : std_logic;
   signal s_oFIFO_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0);
   signal s_oFIFO_empty  : std_logic;
   signal s_oFIFO_full   : std_logic;
   signal s_iFIFO_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0); 
   signal s_oFIFO_dvalid : std_logic;
   signal s_iFIFO_dvalid : std_logic;
   signal s_oFIFO_ready  : std_logic;
   signal s_iFIFO_ready  : std_logic;

   signal s_iREGF_rst    : std_logic;
   signal s_iREGF_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0);
   signal s_oREGF_data   : std_logic_vector(G_PIX_WIDTH +2 -1 downto 0);
   signal s_iREGF_valid  : std_logic;
   signal s_oREGF_ready  : std_logic;
   signal s_iREGF_ready  : std_logic;
   signal s_oREGF_valid  : std_logic;

   signal s_frame_in_progres  : std_logic;
   signal s_col_cnt      : unsigned(11 -1 downto 0);
begin

------------------------------------------------------------------------
-- reg instance
-- used to catch data from stream and to forward it to the fifo and to the
-- outpt register
------------------------------------------------------------------------
   s_iREG1_rst   <= not(s_axis_arst_n);
   s_iREG1_data  <= s_axis_in.tdata & s_axis_in.tlast & s_axis_in.tuser;
   s_iREG1_valid <= s_axis_in.tvalid;
   s_iREG1_ready <= (s_oREG2_ready or (nand(s_col_cnt))) and s_oFIFO_ready;

reg1_i : entity work.reg_hs
   generic map(
      G_DWIDTH => G_PIX_WIDTH +2)
   port map(
      i_clk   => s_axis_aclk,
      i_rst   => s_iREG1_rst,
      i_data  => s_iREG1_data,
      i_valid => s_iREG1_valid,
      o_ready => s_oREG1_ready,
      i_ready => s_iREG1_ready,
      o_valid => s_oREG1_valid,
      o_data  => s_oREG1_data);

------------------------------------------------------------------------
-- reg instance
-- output register, contains pix1
------------------------------------------------------------------------
   s_iREG2_rst   <= not(s_axis_arst_n);
   s_iREG2_data  <= s_oREG1_data;
   s_iREG2_valid <= s_oREG1_valid;
   s_iREG2_ready <= i_ready;

reg2_i : entity work.reg_hs
   generic map(
      G_DWIDTH => G_PIX_WIDTH +2)
   port map(
      i_clk   => s_axis_aclk,
      i_rst   => s_iREG2_rst,
      i_data  => s_iREG2_data,
      i_valid => s_iREG2_valid,
      o_ready => s_oREG2_ready,
      i_ready => s_iREG2_ready,
      o_valid => s_oREG2_valid,
      o_data  => s_oREG2_data);

------------------------------------------------------------------------
-- fifo instance
-- used to buffer one row of frame
------------------------------------------------------------------------
   s_iFIFO_rst    <= not(s_axis_arst_n);
   process(all)
   begin
      s_iFIFO_data <= (others => '0');
      if not(s_oREG1_data(0)) = '1' then
         s_iFIFO_data   <= s_oREG1_data;
      end if;
   end process;
   s_iFIFO_dvalid <= s_oREG1_valid;
   s_iFIFO_ready  <= s_oREGF_ready and s_frame_in_progres and s_oREG1_valid;

fifo_i: entity work.fifo
   generic map(
      G_RD_DWIDTH   => G_PIX_WIDTH +2,
      G_WR_DWIDTH   => G_PIX_WIDTH +2,
      G_FIFO_WDEPTH => G_MAX_ROW_SIZE)
   port map(
      i_wr_clk      => s_axis_aclk,
      i_rd_clk      => s_axis_aclk,
      i_rst         => s_iFIFO_rst,
      i_din         => s_iFIFO_data,
      o_dout        => s_oFIFO_data,
      o_dvalid      => s_oFIFO_dvalid,
      i_dvalid      => s_iFIFO_dvalid,
      o_dready      => s_oFIFO_ready,
      i_dready      => s_iFIFO_ready);

------------------------------------------------------------------------
-- reg instance
-- output used to take data from ffo and sinchronise it with other output
-- reg. Contains pix0
------------------------------------------------------------------------
   s_iREGF_rst   <= not(s_axis_arst_n);
   s_iREGF_data  <= s_oFIFO_data;
   s_iREGF_valid <= s_oFIFO_dvalid;
   s_iREGF_ready <= i_ready and s_frame_in_progres;

reg_fifo_i : entity work.reg_hs
   generic map(
      G_DWIDTH => G_PIX_WIDTH +2)
   port map(
      i_clk   => s_axis_aclk,
      i_rst   => s_iREGF_rst,
      i_data  => s_iREGF_data,
      i_valid => s_iREGF_valid,
      o_ready => s_oREGF_ready,
      i_ready => s_iREGF_ready,
      o_valid => s_oREGF_valid,
      o_data  => s_oREGF_data);


------------------------------------------------------------------------
-- output position calculation
------------------------------------------------------------------------
col_cnt_proc: process(s_axis_aclk)
      variable v_cnt_en  : std_logic;
      variable v_cnt_dis : std_logic;
      variable v_start   : std_logic;
   begin
      if rising_edge(s_axis_aclk) then
         if s_iREG1_rst = '1' then
            s_col_cnt          <= (others => '0');
            s_frame_in_progres <= '0';
            v_cnt_en           := '0';
            v_cnt_dis          := '0';
            v_start            := '0';
         else
 
            if v_start = '1' then
               s_col_cnt          <= s_col_cnt +1; 
            elsif v_cnt_dis = '1' then
               s_col_cnt          <= (others => '0'); 
            end if;
 
           v_start := '0';
           if s_oREG1_valid = '1' and s_oREG1_data(1) = '1' and s_oREG1_data(0) = '1' then                                         
              s_frame_in_progres <= '0';                                                    
              v_cnt_en           := '0'; 
              v_start            := '0'; 
              v_cnt_dis          := '1';                                                   
           elsif s_oREG1_data(1) = '1' and v_cnt_en = '1' then                                                                        
              s_frame_in_progres <= '1'; 
              v_start            := '1';                                                    
           elsif s_oREG1_data(1) = '1' then                                                 
              v_cnt_en           := '1';                                                    
              v_cnt_dis          := '0';
           end if;
         end if;
      end if;
   end process;


----------------------------------------------------------------
-- outputs assignment
----------------------------------------------------------------
   s_axis_out.tready  <= s_oREG1_ready;

   o_pix.pos      <= std_logic_vector(s_col_cnt);
   o_pix.valid    <= s_oREGF_valid and s_oREG2_valid and or(s_col_cnt);
   o_pix.last     <= s_oREGF_data(1);
   o_pix.sof      <= s_oREGF_data(0);
   o_pix.pix0     <= s_oREG2_data(G_PIX_WIDTH +2 -1 downto 2);
   o_pix.pix1     <= s_oREGF_data(G_PIX_WIDTH +2 -1 downto 2);

end Behavioral;
