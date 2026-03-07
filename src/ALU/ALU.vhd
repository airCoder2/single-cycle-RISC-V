-- Date        : March 7, 2026
-- File        : ALU.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file is the top level ALU 
-- Components  : Adder_subtractor_imm, Decoder_4:16, Mux_32bit 16 to 1

library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity ALU is
	port( i_reg1_data  	 : in std_logic_vector(31 downto 0);
		  i_reg2_data    : in std_logic_vector(31 downto 0);
		  i_extended_imm : in std_logic_vector(31 downto 0);
          i_ALU_control  : out std_logic_vector(3 downto 0));
		  i_ALU_src      : in std_logic;
	      i_nAdd_Sub     : in std_logic;
		  o_ALU_out      : out std_logic_vector(31 downto 0)); -- outputs is +1 of inputs
end entity ALU;

architecture structural of ALU is

    -- adder subtractor immediate
    component Adder_Subtractor_immediate is
        generic (N : integer := 32);
        port( A  	   : in std_logic_vector(N-1 downto 0);
              B        : in std_logic_vector(N-1 downto 0);
              imm      : in std_logic_vector(N-1 downto 0);
              ALU_src  : in std_logic;
              nAdd_Sub : in std_logic;
              sum      : out std_logic_vector(N-1 downto 0)); -- outputs is +1 of inputs
    end component Adder_Subtractor_immediate;

    -- 4 to 16 decoder
    component Decoder_4_to_16 is
        port(EN_IN   : in std_logic; -- input to enable the decoder. Otherwise outputs 0
             CODE_IN : in std_logic_vector(3 downto 0); -- we have 4 bits for code
             F_OUT   : out std_logic_vector(15 downto 0)); -- we have 16 bit output
    end component Decoder_4_to_16;

    -- 16 to 1 bus mux
    component Bus_32_bit_Mux_16_to_1 is
        port(BUS_IN     : in reg_outs_t; --defined inside the package I made
             SELECT_IN  : in std_logic_vector(3 downto 0);
             MUX_OUT    : out std_logic_vector(31 downto 0));
    end component Bus_32_bit_Mux_16_to_1;


begin
    Adder_subtractor: Adder_Subtractor_immediate
        generic map(N => 32)
        port map( 
                 A 	      => , 
                 B        => , 
                 imm      => , 
                 ALU_src  => ,
                 nAdd_Sub => , 
                 sum      => );
    end component Adder_Subtractor_immediate;

    -- 4 to 16 decoder
    component Decoder_4_to_16 is
        port(EN_IN   => ,
             CODE_IN => , 
             F_OUT   => );
    end component Decoder_4_to_16;

    -- 16 to 1 bus mux
    component Bus_32_bit_Mux_16_to_1 is
        port(BUS_IN    => ,
             SELECT_IN => ,
             MUX_OUT   => );
    end component Bus_32_bit_Mux_16_to_1;



end architecture structural;


