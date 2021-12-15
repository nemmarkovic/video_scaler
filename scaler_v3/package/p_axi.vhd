library ieee;
    use ieee.std_logic_1164.all;

package p_axi is

  type t_axis_s_in is record
     tdata  : std_logic_vector(7 downto 0);
     tlast  : std_logic;
     tvalid : std_logic; 
     tuser  : std_logic;
  end record;

   constant t_axis_s_in_rst : t_axis_s_in :=(
      tdata   => (others => '0'),
      tlast   => '0',
      tvalid  => '0',
      tuser   => '0');

  type t_axis_s_out is record
     tready : std_logic;
  end record;

  type t_axis_m_out is record
     tdata  : std_logic_vector(7 downto 0);
     tlast  : std_logic;
     tvalid : std_logic; 
     tuser  : std_logic;
  end record;

  type t_axis_m_in is record
     tready : std_logic;
  end record;

end package;

package body p_axi is

end p_axi;