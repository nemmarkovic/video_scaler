library IEEE;
    use IEEE.Std_logic_1164.all;
    use IEEE.Numeric_Std.all;

entity tb_reg is
   generic(
      G_DWIDTH : positive := 8);
   end;

architecture bench of tb_reg is

  signal i_clk   : std_logic;
  signal i_rst   : std_logic;
  signal i_data  : std_logic_vector(G_DWIDTH -1 downto 0);
  signal i_valid : std_logic;
  signal o_ready : std_logic;
  signal i_ready : std_logic;
  signal o_valid : std_logic;
  signal o_data  : std_logic_vector(G_DWIDTH -1 downto 0);

   constant clk_period : time := 10 ns;
begin

  -- Insert values for generic parameters !!
uut: entity work.reg
   generic map (
      G_DWIDTH =>  G_DWIDTH)
   port map ( 
      i_clk    => i_clk,
      i_rst    => i_rst,
      i_data   => i_data,
      i_valid  => i_valid,
      o_ready  => o_ready,
      i_ready  => i_ready,
      o_valid  => o_valid,
      o_data   => o_data );

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

stimulus: process(i_clk)
     variable v_cnt : integer;
     variable v_cnt_pause : integer;
  begin
     if rising_edge(i_clk) then
        if i_rst = '1' then
           i_valid <= '1';
           i_data  <= (others => '1');
           i_ready <= '0';
           v_cnt    := 0;
           v_cnt_pause    := 0;
        else
           if o_ready = '1' then
              i_data <= std_logic_vector(unsigned(i_data) +1);
           end if;

           if o_valid = '1' and v_cnt <= 10 then 
              i_ready <= '1';
              v_cnt := v_cnt +1;
            elsif v_cnt >= 10 and v_cnt_pause <= 10 then
              i_ready <= '0';
              v_cnt_pause := v_cnt_pause +1;
            else
               v_cnt    := 0;
               v_cnt_pause    := 0;
            end if;
        end if;
     end if;
  end process;


end;
