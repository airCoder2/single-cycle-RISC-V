-- Date        : Apr 25, 2026
-- File        : tb_Shifter.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for a shifter 
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_Shifter is
end entity tb_Shifter;

architecture behavioral of tb_Shifter is

    component Shifter is
        port(
            i_data         : in  std_logic_vector(31 downto 0);
            i_shift_amount : in  std_logic_vector(4 downto 0);
            i_logcl_arith  : in  std_logic;
            i_right_left   : in  std_logic;
            o_shifted_data : out std_logic_vector(31 downto 0)
        );
    end component;

    signal i_data         : std_logic_vector(31 downto 0);
    signal i_shift_amount : std_logic_vector(4 downto 0);
    signal i_logcl_arith  : std_logic;
    signal i_right_left   : std_logic;
    signal o_shifted_data : std_logic_vector(31 downto 0);

begin

    UUT : Shifter
        port map(
            i_data         => i_data,
            i_shift_amount => i_shift_amount,
            i_logcl_arith  => i_logcl_arith,
            i_right_left   => i_right_left,
            o_shifted_data => o_shifted_data
        );

    process
    begin
        -- logical left shift by 1
        i_data        <= x"00000001";
        i_shift_amount <= "00001";
        i_logcl_arith  <= '0';
        i_right_left   <= '0';
        wait for 20 ns;

        -- logical left shift by 4
        i_data        <= x"00000001";
        i_shift_amount <= "00100";
        i_logcl_arith  <= '0';
        i_right_left   <= '0';
        wait for 20 ns;

        -- logical right shift by 1
        i_data        <= x"80000000";
        i_shift_amount <= "00001";
        i_logcl_arith  <= '0';
        i_right_left   <= '1';
        wait for 20 ns;

        -- logical right shift by 4
        i_data        <= x"80000000";
        i_shift_amount <= "00100";
        i_logcl_arith  <= '0';
        i_right_left   <= '1';
        wait for 20 ns;

        -- arithmetic right shift by 1 (positive number, MSB=0)
        i_data        <= x"40000000";
        i_shift_amount <= "00001";
        i_logcl_arith  <= '1';
        i_right_left   <= '1';
        wait for 20 ns;

        -- arithmetic right shift by 1 (negative number, MSB=1, sign should extend)
        i_data        <= x"80000000";
        i_shift_amount <= "00001";
        i_logcl_arith  <= '1';
        i_right_left   <= '1';
        wait for 20 ns;

        -- arithmetic right shift by 4 (negative number)
        i_data        <= x"80000000";
        i_shift_amount <= "00100";
        i_logcl_arith  <= '1';
        i_right_left   <= '1';
        wait for 20 ns;

        -- arithmetic left shift by 4
        i_data        <= x"00000001";
        i_shift_amount <= "00100";
        i_logcl_arith  <= '1';
        i_right_left   <= '0';
        wait for 20 ns;

        -- shift by 0 (no change)
        i_data        <= x"DEADBEEF";
        i_shift_amount <= "00000";
        i_logcl_arith  <= '0';
        i_right_left   <= '0';
        wait for 20 ns;

        -- max shift amount (31)
        i_data        <= x"FFFFFFFF";
        i_shift_amount <= "11111";
        i_logcl_arith  <= '0';
        i_right_left   <= '1';
        wait for 20 ns;

        wait;
    end process;

end behavioral;
