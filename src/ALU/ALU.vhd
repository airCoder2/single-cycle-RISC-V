-- Date        : March 7, 2026
-- File        : ALU.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file is the top level ALU 
-- Components  : Adder_subtractor, AND, OR, XOR

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity ALU is
	port( i_A        	 : in std_logic_vector(31 downto 0);   -- 1st operand rs1/pc
		  i_B            : in std_logic_vector(31 downto 0);   -- 2nd operand rs2/imm
          i_ALU_select   : in std_logic_vector(2 downto 0);    -- ALU mux select
          i_ALU_nAdd_sub : in std_logic;                       -- ALU add sub control
          i_ALU_lui      : in std_logic;                       -- mux select to chose shifted lui imm
		  o_ALU_out      : out std_logic_vector(31 downto 0)); -- output
end entity ALU;

architecture structural of ALU is

    component Adder_Subtractor is
	generic (N : integer := 32);
        port( A  	   : in std_logic_vector(N-1 downto 0);
              B        : in std_logic_vector(N-1 downto 0);
              nAdd_Sub : in std_logic;
              sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
              c_out    : out std_logic;
              overflow : out std_logic);
    end component Adder_Subtractor;

    component AND_unit is
        port (
              i_A   : in std_logic_vector(31 downto 0);
              i_B   : in std_logic_vector(31 downto 0);
              o_out : out std_logic_vector(31 downto 0));
    end component AND_unit;

    component OR_unit is
        port (
              i_A   : in std_logic_vector(31 downto 0);
              i_B   : in std_logic_vector(31 downto 0);
              o_out : out std_logic_vector(31 downto 0));
    end component OR_unit;

    component XOR_unit is
        port (
              i_A   : in std_logic_vector(31 downto 0);
              i_B   : in std_logic_vector(31 downto 0);
              o_out : out std_logic_vector(31 downto 0));
    end component XOR_unit;

    signal s_Adder_out : std_logic_vector(31 downto 0);
    signal s_ALU_AND_out : std_logic_vector(31 downto 0);
    signal s_ALU_OR_out  : std_logic_vector(31 downto 0);
    signal s_ALU_XOR_out : std_logic_vector(31 downto 0);
    signal s_ALU_component_out : std_logic_vector(31 downto 0);

begin

    -- adder subtract unit
    Adder_subtractor_inst: Adder_Subtractor
        generic map(N => 32)
        port map(A 	      => i_A, 
                 B        => i_B, 
                 nAdd_Sub => i_ALU_nAdd_sub, -- driven by ALU_control unit
                 sum      => s_Adder_out);

    AND_unit_inst: AND_unit
        port map(
                 i_A => i_A,
                 i_B => i_B,
                 o_out => s_ALU_AND_out);

    OR_unit_inst: OR_unit
        port map(
                 i_A => i_A,
                 i_B => i_B,
                 o_out => s_ALU_OR_out);

    XOR_unit_inst: XOR_unit
        port map(
                 i_A => i_A,
                 i_B => i_B,
                 o_out => s_ALU_XOR_out);

        with i_ALU_select select
            s_ALU_component_out <= s_Adder_out when 3b"000", -- add other cases for different components
                                   s_ALU_AND_out when 3b"011",
                                   s_ALU_OR_out  when 3b"100",
                                   s_ALU_XOR_out when 3b"101",
                                   32x"00000000" when others;

        -- when lui is 1, route immediate, which is i_B to reg
        with i_ALU_lui select
            o_ALU_out <= s_ALU_component_out when '0', -- when not lui, then one of the chosen components
                         i_B when '1', -- when lui, imm << 12
                         32x"00000000" when others;

end architecture structural;


