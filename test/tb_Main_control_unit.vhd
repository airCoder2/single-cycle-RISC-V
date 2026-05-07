library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_Main_control_unit is
end entity tb_Main_control_unit;

architecture behavioral of tb_Main_control_unit is

    component Main_control_unit is
        port(
            i_Opcode     : in  std_logic_vector(6 downto 0);
            o_ALU_op     : out std_logic_vector(1 downto 0);
            o_Imm_select : out std_logic_vector(2 downto 0);
            o_ALU_A_src  : out std_logic;
            o_ALU_src    : out std_logic;
            o_mem_WE     : out std_logic;
            o_ALU_mem    : out std_logic;
            o_reg_file_WE: out std_logic;
            o_lui        : out std_logic;
            o_branch     : out std_logic;
            o_jal        : out std_logic;
            o_jalr       : out std_logic;
            o_halt       : out std_logic
        );
    end component;

    signal i_Opcode      : std_logic_vector(6 downto 0);
    signal o_ALU_op      : std_logic_vector(1 downto 0);
    signal o_Imm_select  : std_logic_vector(2 downto 0);
    signal o_ALU_A_src   : std_logic;
    signal o_ALU_src     : std_logic;
    signal o_mem_WE      : std_logic;
    signal o_ALU_mem     : std_logic;
    signal o_reg_file_WE : std_logic;
    signal o_lui         : std_logic;
    signal o_branch      : std_logic;
    signal o_jal         : std_logic;
    signal o_jalr        : std_logic;
    signal o_halt        : std_logic;

begin

    UUT : Main_control_unit
        port map(
            i_Opcode      => i_Opcode,
            o_ALU_op      => o_ALU_op,
            o_Imm_select  => o_Imm_select,
            o_ALU_A_src   => o_ALU_A_src,
            o_ALU_src     => o_ALU_src,
            o_mem_WE      => o_mem_WE,
            o_ALU_mem     => o_ALU_mem,
            o_reg_file_WE => o_reg_file_WE,
            o_lui         => o_lui,
            o_branch      => o_branch,
            o_jal         => o_jal,
            o_jalr        => o_jalr,
            o_halt        => o_halt
        );

    process
    begin
        -- R-TYPE
        i_Opcode <= "0110011"; wait for 20 ns;

        -- I-TYPE
        i_Opcode <= "0010011"; wait for 20 ns;

        -- LOAD
        i_Opcode <= "0000011"; wait for 20 ns;

        -- STORE
        i_Opcode <= "0100011"; wait for 20 ns;

        -- BRANCH
        i_Opcode <= "1100011"; wait for 20 ns;

        -- JAL
        i_Opcode <= "1101111"; wait for 20 ns;

        -- JALR
        i_Opcode <= "1100111"; wait for 20 ns;

        -- LUI
        i_Opcode <= "0110111"; wait for 20 ns;

        -- AUIPC
        i_Opcode <= "0010111"; wait for 20 ns;

        -- HALT (WFI)
        i_Opcode <= "1110011"; wait for 20 ns;

        wait;
    end process;

end behavioral;
