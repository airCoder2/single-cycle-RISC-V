-- Date        : Feb 23, 2026
-- File        : Extenders.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a 12 to 32 signed/unsigned extender

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity Extenders is

	port(
         DATA_IN  : in std_logic_vector(11 downto 0);
         FLAG_IN  : in std_logic;
         DATA_OUT : out std_logic_vector(31 downto 0)
        );
	
end entity Extenders;

architecture structural of Extenders is

    component mux2t1_N_dataflow is
        generic(N : integer := 20); -- Generic of type integer for input/output data width
        port(i_S          : in std_logic;
           i_D0         : in std_logic_vector(N-1 downto 0);
           i_D1         : in std_logic_vector(N-1 downto 0);
           o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

    signal signed_mux_out : std_logic_vector(19 downto 0);
    signal mux_out        : std_logic_vector(19 downto 0);

begin

    signed_mux: mux2t1_N_dataflow
        generic map(N => 20)
        port map(
                 i_S  => DATA_IN(11),
                 i_D0 => x"00000",
                 i_D1 => x"FFFFF",
                 o_O  => signed_mux_out);

    mux: mux2t1_N_dataflow
        generic map(N => 20)
        port map(
                 i_S  => FLAG_IN,
                 i_D0 => x"00000",
                 i_D1 => signed_mux_out,
                 o_O  => mux_out);


    DATA_OUT <= mux_out & DATA_IN;

end architecture;
