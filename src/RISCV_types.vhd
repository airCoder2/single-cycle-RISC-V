-- Date        : Feb 16, 2026
-- File        : bus_types_pkg.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a package to be used

-------------------------------------------------------------------------
-- Description: This file contains a skeleton for some types that 381 students
-- may want to use. This file is guarenteed to compile first, so if any types,
-- constants, functions, etc., etc., are wanted, students should declare them
-- here.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package RISCV_types is

	-- 32 inputs x 32-bite wide
	type reg_outs_t is array(31 downto 0) of std_logic_vector(31 downto 0); -- type for signal 

end package RISCV_types;

package body RISCV_types is
  -- Probably won't need anything here... function bodies, etc.
end package body RISCV_types;




