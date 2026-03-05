-- Date        : Feb 16, 2026
-- File        : bus_types_pkg.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a package to be used

library ieee;
use ieee.std_logic_1164.all;

package bus_types_pkg is
	-- 32 inputs x 32-bite wide
	type reg_outs_t is array(31 downto 0) of std_logic_vector(31 downto 0); -- type for signal 
end package;

package body bus_types_pkg is
end package body;
