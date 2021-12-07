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

      o_ready   : out std_logic;
      i_ready   : in  std_logic;
      o_pix     : out t_out_pix
      
      );
   end video_scaler;

architecture Behavioral of video_scaler is
   signal w_bfilter_ready_i         : std_logic;
   signal w_bfilter_pix_o           : t_out_pix_array;
   signal w_bfilter_start_pix_sel_o : std_logic_vector(11 - clog2(G_PHASE_NUM) -1 downto 0);


   signal w_fifob_ready_o    : std_logic;
   signal w_fifob_valid_i    : std_logic_vector(G_PHASE_NUM -1 downto 0);
   signal w_fifob_pix_i      : t_out_pix_array;
   signal w_fifob_valid_o    : std_logic_vector(G_PHASE_NUM -1 downto 0);  
   signal w_fifob_ready_i    : std_logic_vector(G_PHASE_NUM -1 downto 0);  
   signal w_fifob_data_o     : t_out_pix_array;
   
   signal w_pcsw_valid_i     : std_logic_vector(G_PHASE_NUM -1 downto 0);  
   signal w_pcsw_ready_o     : std_logic_vector(G_PHASE_NUM -1 downto 0);  
   signal w_pcsw_data_i      : t_out_pix_array;
   
   
begin

   w_bfilter_ready_i <= w_fifob_ready_o;

uut_bilinear_flt_i: entity work.bilinear_flt 
   generic map (
      G_TYPE      => "V",
      G_IN_SIZE   => G_IN_SIZE,
      G_OUT_SIZE  => G_OUT_SIZE,
      G_PHASE_NUM => G_PHASE_NUM,
      G_DWIDTH    => G_DWIDTH )
   port map (
      i_clk       => i_clk,
      i_rst       => i_rst,
      o_ready     => o_ready,
      i_pix       => i_pix,
      i_ready     => w_bfilter_ready_i,
      o_sel_start_pos => w_bfilter_start_pix_sel_o,
      o_pix           => w_bfilter_pix_o); --: out t_out_pix_array);


gl: for i in 0 to 3 generate
   w_fifob_valid_i(i) <= w_bfilter_pix_o(i).valid;
end generate;
   w_fifob_pix_i      <= w_bfilter_pix_o;
   w_fifob_ready_i    <= w_pcsw_ready_o;
   
fifo_bank_i: entity work.fifo_bank
   generic map(
      G_RD_DWIDTH   => G_DWIDTH,
      G_WR_DWIDTH   => G_DWIDTH,
      G_PHASE_NUM   => G_PHASE_NUM,
      G_FIFO_WDEPTH => 2048)
   port map(
      i_wr_clk       => i_clk,
      i_rd_clk       => i_clk,
      i_rst          => i_rst,
      o_dready       => w_fifob_ready_o,
      i_valid        => w_fifob_valid_i,
      i_din          => w_fifob_pix_i,
      o_dout         => w_fifob_data_o,--: out t_out_pix_array;
      o_valid        => w_fifob_valid_o,
      i_dready       => w_fifob_ready_i);--: in  std_logic_vector(G_PHASE_NUM -1 downto 0));



   w_pcsw_valid_i <= w_fifob_valid_o;
   w_pcsw_data_i  <= w_fifob_data_o;
   
pc_switch_i: entity work.pc_switch
    generic map(
      G_DWIDTH    => G_DWIDTH,
      G_NO_INPUT  => G_PHASE_NUM)
    port map(
      i_clk       => i_clk,
      i_rst       => i_rst,

      i_valid     => w_pcsw_valid_i,
      o_ready     => w_pcsw_ready_o,
      i_pix       => w_pcsw_data_i, --(others => t_out_pix_rst), --: in  t_out_pix_array;

      i_ready     => i_ready,
      o_pix       => o_pix);


end Behavioral;
