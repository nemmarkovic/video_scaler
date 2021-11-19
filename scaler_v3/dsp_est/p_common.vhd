library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.math_real.ALL;


package p_common is
   type t_coeff is array (natural range <>, natural range <>) of std_logic_vector(8-1 downto 0);

   constant coeff0 : t_coeff:= (0 => (0 => "00000001", --"10000000",  --1 
                                      1 => "00000010", --"01100000",  -- 0.75
                                      2 => "00000011", --"01000000",  -- 0.5
                                      3 => "00000100"), --"00010000"), -- 0.25
                                1 => (0 => "00000100", --"00010000",  -- 0.25
                                      1 => "00000011", --"01000000",  -- 0.5
                                      2 => "00000010", --"01100000",  -- 0.75
                                      3 => "00000001")); --"10000000")); -- 1

end package p_common;

package body p_common is

end package body;