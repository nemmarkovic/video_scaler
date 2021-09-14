-----------------------------------------------------------------------------------
-- file name   : tb_stream_to_rows
-- module      : stream to rows
-- author      : Nebojsa Markovic
-- emaill      : mnebojsa.etf@gmail.com
-- date        : september 1st, 2021
-----------------------------------------------------------------------------------
-- description : basic functionality test bench for stream_to_row module
-----------------------------------------------------------------------------------
library IEEE;
    use IEEE.Std_logic_1164.all;
    use IEEE.Numeric_Std.all;

library common_lib;
    use common_lib.p_common.all;

    use work.p_axi.all;

entity tb_stream_to_rows is
   generic(
      G_RD_DWIDTH   : integer := 8;
      G_WR_DWIDTH   : integer := 8;
      G_FIFO_WDEPTH : integer := 2048);
   end entity tb_stream_to_rows;

architecture bench of tb_stream_to_rows is

  signal s_axis_aclk   : std_logic;
  signal s_axis_arst_n : std_logic;
  signal s_axis_in     : t_axis_s_in;--(tdata(G_WR_DWIDTH -1 downto 0));
  signal s_axis_out    : t_axis_s_out;
  signal o_colmun      : std_logic_vector(11-1 downto 0);
  signal o_pix         :  t_dinfo(data(0 to 1));
  signal i_ready       : std_logic;
  signal o_valid       : std_logic;

  signal data0         : std_logic_vector(7 downto 0);
  signal data1         : std_logic_vector(7 downto 0);

  constant clk_period : time := 10 ns;

begin

  -- Insert values for generic parameters !!
stream_to_rows_i: entity work.stream_to_rows
   generic map (
      G_PIX_WIDTH    => G_RD_DWIDTH,
      G_MAX_ROW_SIZE => G_FIFO_WDEPTH)
   port map (
      s_axis_aclk   => s_axis_aclk,
      s_axis_arst_n => s_axis_arst_n,
      s_axis_in     => s_axis_in,
      s_axis_out    => s_axis_out,
      o_position    => o_colmun,
      o_pix         => o_pix,
      o_valid       => o_valid,
      i_ready       => i_ready );

clk_proc: process
  begin
     s_axis_aclk <= '0';
        wait for clk_period/2; 
     s_axis_aclk <= '1';
        wait for clk_period/2;
  end process;
  
rst_proc: process
  begin
        s_axis_arst_n <= '0';
     wait for clk_period *10; 
     wait until rising_edge(s_axis_aclk);
        s_axis_arst_n <= '1';
     wait;
  end process;


stimulus: process(s_axis_aclk)
      variable v_cnt       : unsigned(7 downto 0);
      variable v_cnt_pause : unsigned(7 downto 0);
   begin
      if rising_edge(s_axis_aclk) then
         if s_axis_arst_n = '0' then
            i_ready          <= '0';
            s_axis_in.tdata  <= (others => '0');
            s_axis_in.tlast  <= '0';
            s_axis_in.tvalid <= '0';
            s_axis_in.tuser  <= '0';
            v_cnt            := (others => '0');
            v_cnt_pause      := (others => '0');
         else
            i_ready <= '1';         

            if v_cnt_pause < to_unsigned(10,8) then
               v_cnt_pause := v_cnt_pause +1;
            else
               s_axis_in.tvalid <= '1';           
               s_axis_in.tdata  <= std_logic_vector(v_cnt);
               v_cnt            := v_cnt+1;
               if v_cnt = 9 then
                  s_axis_in.tlast  <= '1';              
               elsif v_cnt = 10 then
                  v_cnt         := (others => '0');
                  v_cnt_pause   := (others => '0');
                  s_axis_in.tlast  <= '0';
                  s_axis_in.tvalid <= '0';
               end if; 
            end if;
         end if;
      end if;
   end process;

   data0 <= o_pix.data(0);
   data1 <= o_pix.data(1);

end;
