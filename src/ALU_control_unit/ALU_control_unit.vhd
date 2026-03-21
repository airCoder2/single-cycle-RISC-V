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
         o_alu_select  : out std_logic_vector(2 downto 0); -- choose what output should chose
         o_nAdd_sub    : out std_logic); -- add subtraction flag for ALU

end entity ALU_control_unit;


architecture behavioral of ALU_control_unit is

    
    -- alu operation encodings
    constant ALU_ADDER   : std_logic_vector(2 downto 0) := "000";
    constant ALU_SLT     : std_logic_Vector(2 downto 0) := "001";
    constant ALU_SLTU    : std_logic_Vector(2 downto 0) := "010";
    constant ALU_AND     : std_logic_vector(2 downto 0) := "011";
    constant ALU_OR      : std_logic_vector(2 downto 0) := "100";
    constant ALU_XOR     : std_logic_vector(2 downto 0) := "101";
    constant ALU_SHIFTER : std_logic_vector(2 downto 0) := "110";

begin

    process(i_alu_op, i_func3, i_func7_5)
    begin
        if((i_ALU_op = "00") or  -- loads, stores, jal, jalr, auipc
           (i_ALU_op = "10" and i_func3 = "000") or -- addi
           (i_ALU_op = "11" and i_func3 = "000" and i_func7_5 = '0')) then --add
               o_alu_select <= ALU_ADDER;
               o_nAdd_sub    <= '0';

        elsif((i_ALU_op = "01") or -- branches 
              (i_ALU_op = "11" and i_func3 = "000" and i_func7_5 = '1')) then -- sub 
                   o_alu_select <= ALU_ADDER;
                   o_nAdd_sub    <= '1';

        elsif (i_func3 = "001") then -- SLL
               o_alu_select <= ALU_SHIFTER;
               o_nAdd_sub    <= '-';
               -- should add flag that controls the shifter

        elsif (i_func3 = "101" and i_func7_5 = '0') then -- SRL
               o_alu_select <= ALU_SHIFTER;
               o_nAdd_sub    <= '-';
               -- should add flag that controls the shifter

        elsif (i_func3 = "101" and i_func7_5 = '1') then -- SRA
               o_alu_select <= ALU_SHIFTER;
               o_nAdd_sub    <= '-';
               -- should add flag that controls the shifter

        elsif (i_func3 = "010") then -- SLT/SLTI
               o_alu_select <= ALU_SLT;
               o_nAdd_sub    <= '1';


        elsif (i_func3 = "011") then -- SLTU/SLTIU 
               o_alu_select <= ALU_SLTU;
               o_nAdd_sub    <= '1';

        elsif (i_func3 = "100") then -- XOR 
               o_alu_select <= ALU_XOR;
               o_nAdd_sub    <= '-';

        elsif (i_func3 = "110") then -- OR 
               o_alu_select <= ALU_OR;
               o_nAdd_sub    <= '-';

        elsif (i_func3 = "111") then -- AND 
               o_alu_select <= ALU_AND;
               o_nAdd_sub    <= '-';
        else
               o_alu_select <= ALU_ADDER;
               o_nAdd_sub    <= '0';
        end if;
    end process;


end architecture behavioral;
