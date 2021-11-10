library ieee;
    use ieee.STD_LOGIC_1164.ALL;
    use ieee.math_real.ALL;


package p_common is

   function clog2(x : natural) return natural;

   constant C_MAX_IMAGE_DIM : positive := 2048;
   constant C_SF_WIDTH      : positive := integer(ceil(log2(real(C_MAX_IMAGE_DIM))) +1.0);
   constant C_MAX_PHASE_NUM : positive := 64;

   type t_in_pix is record
      pix0  : std_logic_vector(8-1 downto 0);
      pix1  : std_logic_vector(8-1 downto 0);
      last  : std_logic; 
      sof   : std_logic;
   end record t_in_pix;

   type t_coef_num is array (0 to C_MAX_PHASE_NUM) of std_logic_vector(integer(ceil(log2(real(4))))-1 downto 0);

   type t_byte_array is array (0 to C_MAX_PHASE_NUM) of std_logic_vector(8 -1 downto 0);

   type t_dinfo is record
      data  : t_byte_array;
      last  : std_logic_vector(0 to C_MAX_PHASE_NUM -1); 
      sof   : std_logic_vector(0 to C_MAX_PHASE_NUM -1);
   end record t_dinfo;

--   type t_dinfo_array is array (natural range <>) of t_dinfo(data(open)(open));

end package p_common;

package body p_common is
   -----------------------------------------------------------------------------
   -- Logarithm base 2 with rounding up.
   -----------------------------------------------------------------------------
   function clog2(x : natural) return natural is
   begin
      return integer(ceil(log2(real(x))));
   end function;
end package body;