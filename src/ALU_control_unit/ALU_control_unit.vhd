-- Date        : March 25, 2026
-- File        : ALU_control_unit.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements an ALU_control_unit


library IEEE;
use IEEE.std_logic_1164.all;

entity ALU_control_unit is

    port(i_ALU_op      : in  std_logic_vector(1 downto 0);
         i_func7       : in  std_logic_vector(31 downto 25);
         i_func3       : in  std_logic_vector(14 downto 12);
         o_ALU_control : out std_logic_vector(3 downto 0));
         

end entity ALU_control_unit;


architecture structural of ALU_control_unit is


begin

end architecture structural;
