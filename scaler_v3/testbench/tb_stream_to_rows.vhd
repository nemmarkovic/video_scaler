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
  signal o_pix         : t_in_pix;
  signal i_ready       : std_logic;

  signal data0         : std_logic_vector(7 downto 0);
  signal data1         : std_logic_vector(7 downto 0);

   signal s_axis_in_gen  : t_axis_s_in;
   signal s_pix_i    : std_logic_vector(11 -1 downto 0);
   signal s_pix_o    : std_logic_vector(11 -1 downto 0);
   signal s_valid_i : std_logic;
   signal s_ready_o : std_logic;
   signal s_valid   : std_logic;


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
      o_pix         => o_pix,
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


reg_hs_i: entity work.reg_hs
   generic map(
      G_DWIDTH => 11)
   port map(
      i_clk   => s_axis_aclk,
      i_rst   => not(s_axis_arst_n),
      i_data  => s_pix_i,
      i_valid => s_valid_i,
      o_ready => s_ready_o,
      i_ready => s_axis_out.tready,
      o_valid => s_valid,
      o_data  => s_pix_o);


s_valid_i        <= s_axis_in_gen.tvalid;
s_pix_i          <= s_axis_in_gen.tvalid & s_axis_in_gen.tdata & s_axis_in_gen.tlast & s_axis_in_gen.tuser;

s_axis_in.tvalid <= s_valid;
s_axis_in.tdata  <= s_pix_o(10 -1 downto 2);
s_axis_in.tlast  <= s_pix_o(1);
s_axis_in.tuser  <= s_pix_o(0);



stimulus1: process(s_axis_aclk)
      variable vr_start : std_logic;
   begin
      if rising_edge(s_axis_aclk) then
         if s_axis_arst_n = '0' then
            s_axis_in_gen <= t_axis_s_in_rst;
            i_ready       <= '0';
            vr_start      := '1';
         else

            if s_valid_i = '1' and s_ready_o = '1' and vr_start = '1' then
 
               s_axis_in_gen.tlast <= '0';
               if to_integer(unsigned(s_axis_in_gen.tdata)) >= 8 then
                  s_axis_in_gen.tlast <= '1';
               end if;

               if to_integer(unsigned(s_axis_in_gen.tdata)) >= 9 then
                 -- s_pix_gen.pos  <= (others => '0');
                  s_axis_in_gen.tlast <= '0';
                  s_axis_in_gen <= t_axis_s_in_rst;
               else
                  s_axis_in_gen.tdata <= std_logic_vector(unsigned(s_axis_in_gen.tdata) +1);
               end if;
            end if;
 
            if (s_valid_i  and   s_ready_o) = '1' then
               vr_start := '1';
            elsif(s_ready_o = '1' and to_integer(unsigned(s_axis_in_gen.tdata)) <= 20 -1) then
               s_axis_in_gen.tvalid <= '1';         
            else
               s_axis_in_gen.tvalid <= s_axis_in_gen.tvalid;            
               s_axis_in_gen.tvalid <= '0'; 
            end if;         
            i_ready     <=  not(i_ready); --'1'; --
         end if;
      end if;
   end process;

end;
