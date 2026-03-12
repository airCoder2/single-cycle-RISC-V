-- date        : march 25, 2026
-- file        : alu_control_unit.vhd     
-- designer    : salah nasriddinov
-- description : this file implements an ALU_control_unit


library ieee;
use ieee.std_logic_1164.all;

entity ALU_control_unit is

    port(i_alu_op      : in  std_logic_vector(1 downto 0);
         i_func3       : in  std_logic_vector(2 downto 0);
         i_func7_5     : in  std_logic;
         o_alu_control : out std_logic_vector(3 downto 0));
         -- I though about doing it one hot encoded signal, but not efficient.
         -- Because I have to them multiplex all the results and chose one.
         -- for that, I can use alu_control as a selector
         

end entity ALU_control_unit;


architecture behavioral of ALU_control_unit is

    
    -- alu operation encodings
    constant ALU_ADD : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB : std_logic_vector(3 downto 0) := "0001";
    constant ALU_AND : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OR  : std_logic_vector(3 downto 0) := "0011";
    constant ALU_XOR : std_logic_vector(3 downto 0) := "0100";
    constant ALU_SLL : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SRL : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRA : std_logic_vector(3 downto 0) := "0111";
    constant ALU_SLT : std_logic_Vector(3 downto 0) := "1000";


begin

    o_ALU_control <=
        -- Main control cases
        ALU_ADD when ((i_ALU_op = "00") or  -- load, store
                      (i_ALU_op = "10" and i_func3 = "000") or -- addi
                      (i_ALU_op = "11" and i_func3 = "000" and i_func7_5 = '0')) else -- add


        ALU_SUB when ((i_ALU_op = "01") or -- branch 
                      (i_ALU_op = "11" and i_func3 = "000" and i_func7_5 = '1')) else -- sub 

        ALU_SLL when i_func3 = "001" else

        ALU_SLT when i_func3 = "010" else

        ALU_XOR when i_func3 = "100" else

        ALU_SRL when i_func3 = "101" and i_func7_5 = '0' else

        ALU_SRA when i_func3 = "101" and i_func7_5 = '1' else


        ALU_OR  when i_func3 = "110" else

        ALU_AND when i_func3 = "111" else

        ALU_ADD; -- default


end architecture behavioral;














































