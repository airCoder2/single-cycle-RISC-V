-- Date        : Feb 23, 2026
-- File        : MySecondRISCVDatapath.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a simple riscv datapath with load and store
-- Components  : Register file, AddSub_immedaite, Extenders, Memory, Slicer, 2t1 N bit mux

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;
use IEEE.math_real.all;
use work.bus_types_pkg.all;


entity MySecondRISCVDatapath is
	generic(N : integer := 32); -- you can't actually change this. IT is not configurable
	port (
          imm      : in std_logic_vector(11 downto 0);  -- the 12 bit immediate. Gets extended
		  rs1      : in std_logic_vector(4 downto 0);   -- address of source reg1
		  rs2      : in std_logic_vector(4 downto 0);   -- address of source reg2
		  rd       : in std_logic_vector(4 downto 0);   -- address of destination reg
		  ALU_src  : in std_logic;                      -- wether immediate is used instead of rs2
		  nAdd_sub : in std_logic;                      -- is rs1 + rs2/imm OR rs1 - rs2/imm
		  reset    : in std_logic;                      -- reset all the registers to 0
		  CLOCK_IN : in std_logic;                      -- CLOCK for register file
		  WRITE_EN : in std_logic;                     -- write enable
          mem_WE   : in std_logic;                     -- write enable for memory. has to be controlled
          zero_or_sign_extend_flag : in std_logic;     -- 0 extend the 12 bit imm or sign extend it
          Alu_or_memory_data_flag  : in std_logic     -- flag for selecting which data to write to reg file
        
	);
end entity MySecondRISCVDatapath;

architecture structural of MySecondRISCVDatapath is

	-- using register file
	component Register_file is
		port(CLOCK_IN : in std_logic;                                -- Clock input for registers
			 DATA_TO_WRITE_IN : in std_logic_vector(31 downto 0); 	 -- Data to load
			 WRITE_EN_IN  : in std_logic;                            -- to control the decoder
			 REG_RST_IN   : in std_logic;                            -- to clear all the register
			 WRITE_SEL_IN : in std_logic_vector(4 downto 0); 		 -- select register to load
			 READ_SEL1_IN : in std_logic_vector(4 downto 0);         -- select register 1 to read
			 READ_SEL2_IN : in std_logic_vector(4 downto 0);         -- select register 2 to read
			 DATA_TO_READ1_OUT: out std_logic_vector(31 downto 0); 	 -- selected register 1 out
			 DATA_TO_READ2_OUT: out std_logic_vector(31 downto 0)    -- selected register 2 out
			);
	end component Register_file;

	-- using the adder_subtractor_imm
	component Adder_Subtractor_immediate is
		generic (N : integer);
		port(A  	  : in std_logic_vector(N-1 downto 0);
			 B        : in std_logic_vector(N-1 downto 0);
             imm      : in std_logic_vector(N-1 downto 0);
			 ALU_src  : in std_logic;
			 nAdd_Sub : in std_logic;
			 sum      : out std_logic_vector(N-1 downto 0)); -- outputs is +1 of inputs
	end component Adder_Subtractor_immediate;

    -- using the memory
    component mem is
        generic(
                DATA_WIDTH : natural;
                ADDR_WIDTH : natural);
        port(clk	: in std_logic;
             addr	: in std_logic_vector(9 downto 0);
             data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
             we		: in std_logic := '1';
             q		: out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component mem;

    -- using the extenders
    component Extenders is
        port(DATA_IN  : in std_logic_vector(11 downto 0);
             FLAG_IN  : in std_logic;
             DATA_OUT : out std_logic_vector(31 downto 0));
    end component Extenders;

    -- using the slicer
    component Slicer is
        port(DATA_IN  : in  std_logic_vector(31 downto 0);
             DATA_OUT : out std_logic_vector(9 downto 0));
    end component Slicer;

    -- using a 32 bit 2t1 bus mux
    component mux2t1_N_dataflow is
        generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
        port(i_S          : in std_logic;
             i_D0         : in std_logic_vector(N-1 downto 0);
             i_D1         : in std_logic_vector(N-1 downto 0);
             o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

	signal data_read1_wire  : std_logic_vector(N-1 downto 0);
	signal data_read2_wire  : std_logic_vector(N-1 downto 0);
	signal ALU_out_wire : std_logic_vector(N-1 downto 0);

    signal Slicer_out_wire : std_logic_vector(9 downto 0);
    signal Extender_out_wire : std_logic_vector(31 downto 0);
    signal mem_data_out_wire  : std_logic_vector(31 downto 0);
    signal Alu_or_mem_data_wire : std_logic_vector(31 downto 0);



begin
	REG_FILE: Register_file
			port map(
					 CLOCK_IN => CLOCK_IN,
					 DATA_TO_WRITE_IN => Alu_or_mem_data_wire,
					 WRITE_EN_IN => WRITE_EN,
					 REG_RST_IN  => reset,
					 WRITE_SEL_IN => rd,
					 READ_SEL1_IN => rs1,
					 READ_SEL2_IN => rs2,
					 DATA_TO_READ1_OUT => data_read1_wire,
					 DATA_TO_READ2_OUT => data_read2_wire
				 );


	ADD_SUB_IMM: Adder_Subtractor_immediate
			generic map(N => 32)
			port map(
					 A => data_read1_wire,
			 		 B => data_read2_wire,
				     imm => Extender_out_wire,
			         ALU_src => ALU_src,
				     nAdd_sub => nAdd_sub,
				     sum => ALU_out_wire		 
					);

    MEMORY: mem
            generic map(DATA_WIDTH => 32, ADDR_WIDTH => 10)
            port map(
                     clk  => CLOCK_IN, 
                     addr => Slicer_out_wire,
                     data => data_read2_wire,
                     we	  => mem_WE,
                     q    => mem_data_out_wire
                 );	

    EXTENDER_S: Extenders
            port map(
                     DATA_IN  => imm,
                     FLAG_IN  => zero_or_sign_extend_flag,
                     DATA_OUT => Extender_out_wire
                 );

    SLICE_R: Slicer
            port map(
                     DATA_IN  => ALU_out_wire,
                     DATA_OUT => Slicer_out_wire
                 );

    MUX:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => Alu_or_memory_data_flag,
                     i_D0 => ALU_out_wire,
                     i_D1 => mem_data_out_wire,
                     o_O  => Alu_or_mem_data_wire);

end architecture structural;

