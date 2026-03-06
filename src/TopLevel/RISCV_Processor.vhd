-- Date        : March 25, 2026
-- File        : RISCV_Processor.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a single cycle risc-v processor 
-- Components  : Register file, AddSub_immediatee, Extenders, Slicer, 2to1 N bit mux,
              -- control unit, ALU control unit, Data Memory, Instruction Memory,
              -- Program Counter, PC Adder

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0)); -- TODO: Hook this up to the output of the ALU. 
-- It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.

end  RISCV_Processor;

architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
  -- Required register file signals 
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_PC instead
  signal s_PC : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the instruction signal 

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. 
                                      --       (Use WFI with Opcode: 111 0011 func3: 000 and func12: 000100000101 -- func12 is imm field from I-format)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- this signal indicates an overflow exception would have been initiated

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

  -- TODO: You may add any additional signals or components your implementation 
  --       requires below this comment



    -- Components  : 
                  -- control unit, ALU control unit, Data Memory, Instruction Memory,
                  -- Program Counter, PC Adder



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

    -- using the main_control_unit
    
    -- using the ALU_control_unit,

    -- using the program_counter

    -- using the  PC_Adder















	signal data_read1_wire  : std_logic_vector(N-1 downto 0);
	signal data_read2_wire  : std_logic_vector(N-1 downto 0);
	signal ALU_out_wire : std_logic_vector(N-1 downto 0);

    signal Slicer_out_wire : std_logic_vector(9 downto 0);
    signal Extender_out_wire : std_logic_vector(31 downto 0);
    signal mem_data_out_wire  : std_logic_vector(31 downto 0);
    signal Alu_or_mem_data_wire : std_logic_vector(31 downto 0);





























begin
  s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.

  -- TODO: This is required to be your final input to your instruction memory. This provides a feasible method to externally load the memory module,
  --       which means that the synthesis tool must assume it knows nothing about the values stored in the instruction memory.
  --       If this is not included, much, if not all of the design is optimized out because the synthesis tool will believe the memory to be all zeros.
  with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;


  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst);
  
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

  -- TODO: Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 01 0100)

  -- TODO: Implement the rest of your processor below this comment! 

end structure;

