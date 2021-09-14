-----------------------------------------------------------------------------------
-- file name   : ea_adj
-- module      : adj
-- author      : Nebojsa Markovic
-- emaill      : mnebojsa.etf@gmail.com
-- date        : september 1st, 2021
-----------------------------------------------------------------------------------
-- description :
-----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library common_lib;
    use common_lib.p_common.all;

entity adj is
   generic(
      G_DWIDTH : positive := 8);
   port ( 
      i_clk : in std_logic;
      i_rst : in std_logic;
      -- next moule ready to accept the data
      o_ready         : out std_logic;
      -- valid data on the output
      i_valid         : in  std_logic;
      -- output pixel
      -- contains stream info: last, eof
      -- pixel pair (pix0, pix1)
      i_pix           : in t_dinfo(data(0 to 0)(G_DWIDTH -1 downto 0));        
      -- next moule ready to accept the data
      i_ready         : in  std_logic;
      -- valid data on the output
      o_valid         : out std_logic;
      -- position info - gives info about row-pair number
      o_position      : out std_logic_vector(11-1 downto 0);
      -- output pixel
      -- contains stream info: last, eof
      -- pixel pair (pix0, pix1)
      o_pix           : out t_dinfo(data(0 to 1)(G_DWIDTH -1 downto 0)) );
   end adj;

architecture Behavioral of adj is
   -- registers rows to pixel pairs for horisontal filter
   signal s_iHFREG1_data   : std_logic_vector(G_DWIDTH +2 -1 downto 0);
   signal s_oHFREG1_data   : std_logic_vector(G_DWIDTH +2 -1 downto 0);
   signal s_iHFREG1_valid  : std_logic;
   signal s_oHFREG1_ready  : std_logic;
   signal s_iHFREG1_ready  : std_logic;
   signal s_oHFREG1_valid  : std_logic;

   signal s_iHFREG2_data   : std_logic_vector(G_DWIDTH +2 -1 downto 0);
   signal s_oHFREG2_data   : std_logic_vector(G_DWIDTH +2 -1 downto 0);
   signal s_iHFREG2_valid  : std_logic;
   signal s_oHFREG2_ready  : std_logic;
   signal s_iHFREG2_ready  : std_logic;
   signal s_oHFREG2_valid  : std_logic;

   signal s_position       : unsigned(11-1 downto 0);
begin

------------------------------------------------
---- 
------------------------------------------------
   s_iHFREG1_data  <= i_pix.data(0) & i_pix.last & i_pix.eof;
   s_iHFREG1_valid <= i_valid;
   s_iHFREG1_ready <= s_oHFREG2_ready and i_ready;

reg_to_hf_1_i : entity work.reg
   generic map(
      G_DWIDTH => G_DWIDTH +2)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => s_iHFREG1_data,
      i_valid => s_iHFREG1_valid,
      o_ready => s_oHFREG1_ready,
      i_ready => s_iHFREG1_ready,
      o_valid => s_oHFREG1_valid,
      o_data  => s_oHFREG1_data);


 s_iHFREG2_data  <= s_oHFREG1_data;
 s_iHFREG2_valid <= s_oHFREG1_valid;
 s_iHFREG2_ready <= i_ready;

reg_to_hf_2_i : entity work.reg
   generic map(
      G_DWIDTH => G_DWIDTH +2)
   port map(
      i_clk   => i_clk,
      i_rst   => i_rst,
      i_data  => s_iHFREG2_data,
      i_valid => s_iHFREG2_valid,
      o_ready => s_oHFREG2_ready,
      i_ready => s_iHFREG2_ready,
      o_valid => s_oHFREG2_valid,
      o_data  => s_oHFREG2_data);


------------------------------------------------------------------------
-- output position calculation
------------------------------------------------------------------------
col_cnt_proc: process(i_clk)
      variable v_cnt_en  : std_logic;
      variable v_cnt_dis : std_logic;
      variable v_start   : std_logic;
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            s_position          <= (others => '0');
--            s_frame_in_progres <= '0';
            v_cnt_en           := '0';
            v_cnt_dis          := '0';
            v_start            := '0';
         else
 
            if v_start = '1' then
               s_position          <= s_position +1; 
            elsif v_cnt_dis = '1' then
               s_position          <= (others => '0'); 
            end if;
 
           v_start := '0';
 --          if s_oREG1_valid = '1' and s_oREG1_data(1) = '1' and s_oREG1_data(0) = '1' then                                         
 --             s_frame_in_progres <= '0';                                                    
              v_cnt_en           := '0'; 
              v_start            := '0'; 
              v_cnt_dis          := '1';                                                   
--           elsif s_oREG1_data(1) = '1' and v_cnt_en = '1' then                                                                        
--              s_frame_in_progres <= '1'; 
              v_start            := '1';                                                    
--           elsif s_oREG1_data(1) = '1' then                                                 
              v_cnt_en           := '1';                                                    
              v_cnt_dis          := '0';
           end if;
         end if;
--      end if;
   end process;

--------------------------------------------------------------
-- output assignment
--------------------------------------------------------------
   o_ready         <= s_oHFREG1_ready;

   o_valid         <= s_oHFREG2_valid and s_oHFREG1_valid;
   o_position      <= std_logic_vector(s_position);
   o_pix.data(0)   <= s_oHFREG1_data(G_DWIDTH +2 -1 downto 2);
   o_pix.data(1)   <= s_oHFREG2_data(G_DWIDTH +2 -1 downto 2);
   o_pix.last      <= '0';
   o_pix.eof       <= '0';

end Behavioral;
