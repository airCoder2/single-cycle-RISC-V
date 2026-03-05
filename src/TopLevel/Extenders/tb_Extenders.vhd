-- Date        : Feb 23, 2026
-- File        : Extenders.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for a 12 to 32 signed/unsigned extender

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_Extenders is
end entity tb_Extenders;


architecture behavioral of tb_Extenders is

    component Extenders is
        port(
             DATA_IN  : in std_logic_vector(11 downto 0);
             FLAG_IN  : in std_logic;
             DATA_OUT : out std_logic_vector(31 downto 0)
            );
    end component;

    signal FLAG_IN_wire  : std_logic;
    signal DATA_IN_wire  : std_logic_vector(11 downto 0);
    signal DATA_OUT_wire : std_logic_vector(31 downto 0);

begin
    DUT: Extenders
        port map(
                 DATA_IN  => DATA_IN_wire,
                 FLAG_IN  => FLAG_IN_wire,
                 DATA_OUT => DATA_OUT_wire);

    process
    begin

        DATA_IN_wire <= b"1010_0000_1111";
        FLAG_IN_wire <= '0';
        wait for 10 ns;
        
        DATA_IN_wire <= b"0010_0000_1111";
        FLAG_IN_wire <= '1';
        wait for 10 ns;
        
        DATA_IN_wire <= b"1010_1110_1111";
        FLAG_IN_wire <= '0';
        wait for 10 ns;
        
        DATA_IN_wire <= b"1010_0000_1111";
        FLAG_IN_wire <= '0';
        wait for 10 ns;
        
        DATA_IN_wire <= b"0010_0000_1111";
        FLAG_IN_wire <= '1';
        wait for 10 ns;
        
        DATA_IN_wire <= b"1010_0000_1111";
        FLAG_IN_wire <= '1';
        wait for 10 ns;
        
        DATA_IN_wire <= b"1010_0000_1111";
        FLAG_IN_wire <= '1';
        wait for 10 ns;
        
        DATA_IN_wire <= b"1010_1111_1111";
        FLAG_IN_wire <= '0';
        wait for 10 ns;
        
        DATA_IN_wire <= b"1000_0000_1111";
        FLAG_IN_wire <= '0';
        wait for 10 ns;
        
        DATA_IN_wire <= b"1010_0000_1111";
        FLAG_IN_wire <= '1';
        wait for 10 ns;
        
        DATA_IN_wire <= b"0010_0000_1111";
        FLAG_IN_wire <= '1';
        wait for 10 ns;

        wait;
    end process;
end architecture;

