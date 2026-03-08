-- Date        : March 5, 2026
-- File        : Main_conrol_unit.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements the main control unit 

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Main_control_unit is

	port(
         i_Opcode  : in std_logic_vector(6 downto 0); -- the opcode we are decoding
         o_ALU_op  : out std_logic_vector(1 downto 0); -- two bit ALU opcode
         o_ALU_src : out std_logic; -- control for choosing between imm or rs2 out
         o_mem_WE  : out std_logic; -- control to when data mem can be written
         o_zero_sign: out std_logic; -- control either zero or sign extend 
         o_ALU_mem : out std_logic;  -- control for writing to reg from ALU or memory
         o_reg_file_WE  : out std_logic;  -- control for when data to reg file is written 
         o_halt : out std_logic --used as wfi

        );
	
end entity Main_control_unit;

architecture behavioral of Main_control_unit is

    constant OP_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
    constant OP_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
    constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
    constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
    constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
    constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
    constant OP_HALT   : std_logic_vector(6 downto 0) := "1110011";

begin
    with i_Opcode select
        o_ALU_op <=
            2b"10" when OP_RTYPE, -- depends on func3 and func7
            2b"10" when OP_ITYPE, -- depends on func3 and func7
            2b"00" when OP_LOAD,  -- add immediate + addr to generate full address
            2b"00" when OP_STORE, -- add immediate + addr to generate full address
            2b"00" when others; 
            
    with i_Opcode select
        o_reg_file_WE <= 
            '1' when OP_RTYPE, -- R type instructions like add, sub write to regFile
            '1' when OP_ITYPE, -- I type instructions like addi write to regFile
            '1' when OP_LOAD,  -- Load writes to RegFile, loads value from mem to regFile
            '0' when OP_STORE, -- Store doesn't write to RegFile, only reads it
            '0' when others;

    with i_Opcode select
        o_mem_WE <= 
            '0' when OP_RTYPE, -- R type instructions like add, sub don't write to ram
            '0' when OP_ITYPE, -- I type instructions like addi don't write to ram
            '0' when OP_LOAD,  -- Load doesn't write to ram, it reads it
            '1' when OP_STORE, -- Store writes to ram 
            '0' when others;

    with i_Opcode select
        o_ALU_mem <=
            '0' when OP_RTYPE, -- R type instructions like add, sub write to reg file from ALU
            '0' when OP_ITYPE, -- I type instructions like addi write to reg file from ALU
            '1' when OP_LOAD,  -- Load writes to reg file from Memory
            '-' when OP_STORE, -- Store doesn't write to memory. Therefore, don't care
            '0' when others;


    with i_Opcode select
        o_ALU_src <=
            '0' when OP_RTYPE, -- R type instructions like add, sub take both opearands from regFile
            '1' when OP_ITYPE, -- I type instructions like addi, take operands from regFile and extended imm
            '1' when OP_LOAD,  -- Load takes operands from regFile and extended imm
            '1' when OP_STORE, -- Store takes operands from regFile and extended imm
            '0' when others;



    with i_Opcode select
        o_zero_sign <=
            '-' when OP_RTYPE, -- R type instructions like add, sub don't use immediates
            '1' when OP_ITYPE, -- I type instructions like addi use sign extended immediates
            '1' when OP_LOAD,  -- Load uses sign extended immediate
            '1' when OP_STORE, -- Store uses sign extended immediate
            '0' when others;

    with i_Opcode select
        o_halt <=
            '1' when OP_HALT, 
            '0' when others;

end behavioral;

