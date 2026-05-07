library IEEE;
use IEEE.std_logic_1164.all;

entity tb_XOR_unit is
end entity tb_XOR_unit;

architecture behavioral of tb_XOR_unit is

    component XOR_unit is
        port (
            i_A   : in  std_logic_vector(31 downto 0);
            i_B   : in  std_logic_vector(31 downto 0);
            o_out : out std_logic_vector(31 downto 0)
        );
    end component;

    signal i_A   : std_logic_vector(31 downto 0);
    signal i_B   : std_logic_vector(31 downto 0);
    signal o_out : std_logic_vector(31 downto 0);

begin

    UUT : XOR_unit
        port map (
            i_A   => i_A,
            i_B   => i_B,
            o_out => o_out
        );

    process
    begin

        -- all zeros XOR all zeros
        i_A <= x"00000000";
        i_B <= x"00000000";
        wait for 20 ns;

        -- all ones XOR all ones
        i_A <= x"FFFFFFFF";
        i_B <= x"FFFFFFFF";
        wait for 20 ns;

        -- alternating bit patterns
        i_A <= x"AAAAAAAA";
        i_B <= x"55555555";
        wait for 20 ns;

        -- lower half ones XOR upper half ones
        i_A <= x"0000FFFF";
        i_B <= x"FFFF0000";
        wait for 20 ns;

        -- random test vector 1
        i_A <= x"12345678";
        i_B <= x"87654321";
        wait for 20 ns;

        -- random test vector 2
        i_A <= x"DEADBEEF";
        i_B <= x"0F0F0F0F";
        wait for 20 ns;

        -- identical operands (result should be zero)
        i_A <= x"CAFEBABE";
        i_B <= x"CAFEBABE";
        wait for 20 ns;

        -- one operand zero
        i_A <= x"FFFFFFFF";
        i_B <= x"00000000";
        wait for 20 ns;

        -- mixed values
        i_A <= x"F0F0F0F0";
        i_B <= x"FF00FF00";
        wait for 20 ns;

        -- inverse patterns
        i_A <= x"AAAAAAAA";
        i_B <= x"FFFFFFFF";
        wait for 20 ns;

        wait;

    end process;

end architecture behavioral;
