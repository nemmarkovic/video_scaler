library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.math_real.ALL;


package p_common is
   constant C_MAX_IMAGE_DIM : positive := 2048;
   constant C_SF_WIDTH      : positive := integer(ceil(log2(real(C_MAX_IMAGE_DIM))) +1.0);
   constant C_MAX_TAP_NO    : positive := 64;

   type t_byte_array is array (natural range <>) of std_logic_vector;

   type t_dinfo is record
      data  : t_byte_array(open)(open);
      last  : std_logic; 
      eof   : std_logic;
   end record t_dinfo;

   type t_dinfo_array is array (natural range <>) of t_dinfo(data(open)(open));

end package p_common;

package body p_common is

end package body;