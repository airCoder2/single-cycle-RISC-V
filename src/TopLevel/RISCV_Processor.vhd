-- Date        : March 5, 2026
-- File        : RISCV_Processor.vhd     
-- Designer    : Salah Nasriddinov
-- Description : This file implements a single cycle risc-v processor 
-- Components  : Register file, AddSub_immediatee, Extenders, Slicer, 2to1 N bit mux,
              -- control unit, ALU control unit, Data Memory, Instruction Memory,
              -- Program Counter, PC Adder

-- Updates:
-- Mar 8 04:10 -> Alhamdulillah addi passed test. not synthesizing



library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
    generic(N : integer := 32);
    port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(31 downto 0);
       iInstExt        : in std_logic_vector(31 downto 0);
       oALUOut         : out std_logic_vector(31 downto 0)); -- Hook this up to the output of the ALU

end  RISCV_Processor;


architecture structure of RISCV_Processor is

    ----------------- COMPONENTS ---------------

    component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector(9 downto 0);
          data         : in std_logic_vector(31 downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector(31 downto 0));
    end component;

    component PC is
        port(i_pc_in  : in  std_logic_vector(31 downto 0); -- new data to be written
             o_pc_out : out std_logic_vector(31 downto 0); -- pc output
             i_reset  : in  std_logic; -- reset to 0
             i_clk    : in  std_logic); -- clock
    end component PC;

    component PC_adder is
        port(i_current_pc : in  std_logic_vector(31 downto 0); -- current pc, 
             o_new_pc     : out std_logic_vector(31 downto 0)); -- output (current + 4)
    end component PC_adder;

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

    component ALU is
        port( i_reg1_data  	 : in std_logic_vector(31 downto 0);   -- 1st reg data
              i_reg2_data    : in std_logic_vector(31 downto 0);   -- 2nd reg data
              i_extended_imm : in std_logic_vector(31 downto 0);   -- imm data 
              i_ALU_control  : in std_logic_vector(3 downto 0);    -- ALU conrol bus
              i_ALU_src      : in std_logic;                       -- flag from control unit
              o_ALU_out      : out std_logic_vector(31 downto 0)); -- output
    end component ALU;


    component Extenders is
        port(
             DATA_IN  : in std_logic_vector(11 downto 0);
             FLAG_IN  : in std_logic;
             DATA_OUT : out std_logic_vector(31 downto 0)
            );
    end component Extenders;

    component Main_control_unit is
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
    end component Main_control_unit;


    component ALU_control_unit is
        port(i_alu_op      : in  std_logic_vector(1 downto 0);
             i_func3       : in  std_logic_vector(2 downto 0);
             i_func7_5     : in  std_logic;
             o_alu_control : out std_logic_vector(3 downto 0));
    end component ALU_control_unit;

    component mux2t1_N_dataflow is
        generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
        port(i_S          : in std_logic;
           i_D0         : in std_logic_vector(N-1 downto 0);
           i_D1         : in std_logic_vector(N-1 downto 0);
           o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

    ----------------- SIGNALS ---------------

    -- Required data memory signals
    signal s_DMemWr       : std_logic; -- active high data memory write enable signal
    signal s_DMemAddr     : std_logic_vector(31 downto 0); -- data memory address input
    signal s_DMemData     : std_logic_vector(31 downto 0); -- data memory data input
    signal s_DMemOut      : std_logic_vector(31 downto 0); -- data memory output

    -- Required register file signals 
    signal s_RegWr        : std_logic; -- active high write enable input to the register file
    signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- destination register address input
    signal s_RegWrData    : std_logic_vector(31 downto 0); -- data memory data input

    -- Required instruction memory signals
    signal s_IMemAddr     : std_logic_vector(31 downto 0); -- Do not assign this signal, assign to s_PC instead
    signal s_PC : std_logic_vector(31 downto 0); -- instruction memory address input.
    signal s_Inst         : std_logic_vector(31 downto 0); -- instruction signal 

    -- Required halt signal -- for simulation
    signal s_Halt         : std_logic;  -- wfi. Opcode: 1110011 func3: 000 and func12: 000100000101 

    -- Required overflow signal -- for overflow exception detection
    signal s_Ovfl         : std_logic;  -- overflow exception would have been initiated

    -- My Own Signal

    signal s_New_pc : std_logic_vector(31 downto 0); -- the output of the pc adder
    signal s_DATA_TO_READ1 : std_logic_vector(31 downto 0); -- the 1st output of reg file
    signal s_DATA_TO_READ2 : std_logic_vector(31 downto 0); -- the 2nd output of reg file
    signal s_Extended_imm  : std_logic_vector(31 downto 0); -- connected to ALU's imm
    signal s_ALU_op : std_logic_vector(1 downto 0); -- ALU opcode
    signal s_ALU_src : std_logic; -- reg2 or imm
    signal s_zero_sign : std_logic; -- zero extend or sign extend
    signal s_ALU_mem   : std_logic; -- ALU or memory data written to reg file
    signal s_ALU_control : std_logic_vector(3 downto 0); -- ALU opocde
    signal s_ALU_out : std_logic_vector(31 downto 0);

begin
    s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.
    -- This is required to be your final input to your instruction memory. 
    -- This provides a feasible method to externally load the memory module which means that the synthesis tool 
    -- must assume it knows nothing about the values stored in the instruction memory. If this is not included,
    -- much, if not all of the design is optimized out because
    -- the synthesis tool will believe the memory to be all zeros.

    -- multiplex the instruction mem address. if instructon memeory is being written then connect
    -- the address that toolflow controls, otherwise coneect the s_PC, which is current pc
    with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;



    IMem: mem -- Instruction memory is filled out by toolflow
        generic map(ADDR_WIDTH => 10,
                    DATA_WIDTH => 32)
        port map(clk  => iCLK,
                 addr => s_IMemAddr(11 downto 2), 
                 data => iInstExt,
                 we   => iInstLd,
                 q    => s_Inst);

    s_DMemData <= s_DATA_TO_READ2;
    s_DMemAddr <= s_ALU_out; 
    oALUOut    <= s_ALU_out;

    DMem: mem
        generic map(ADDR_WIDTH => 10,
                    DATA_WIDTH => 32)
        port map(clk  => iCLK,
                 addr => s_DMemAddr(11 downto 2),
                 data => s_DMemData,
                 we   => s_DMemWr,
                 q    => s_DMemOut);

    PC_inst: PC
        port map(
                 i_pc_in  => s_New_pc, -- connect pc_in to pc_adder out
                 o_pc_out => s_PC, --must
                 i_reset  => iRST, --must
                 i_clk    => iCLK); --must

    PC_adder_inst: PC_adder
        port map(
                 i_current_pc => s_PC, --must
                 o_new_pc     => s_New_pc); -- connect the output of the pc to s_New_pc

    s_RegWrAddr <= s_Inst(11 downto 7); -- Write address from instruction
    Register_file_inst: Register_file
        port map(
                 CLOCK_IN          => iCLK, --must
                 DATA_TO_WRITE_IN  => s_RegWrData, -- must
                 WRITE_EN_IN       => s_RegWr, -- must
                 REG_RST_IN        => iRST, --must
                 WRITE_SEL_IN      => s_RegWrAddr, -- must
                 READ_SEL1_IN      => s_Inst(19 downto 15), -- must 
                 READ_SEL2_IN      => s_Inst(24 downto 20), -- must
                 DATA_TO_READ1_OUT => s_DATA_TO_READ1,
                 DATA_TO_READ2_OUT => s_DATA_TO_READ2
             );

    Main_control_inst: Main_control_unit 
        port map(
                 i_Opcode      => s_Inst(6 downto 0), --must
                 o_ALU_op      => s_ALU_op,
                 o_ALU_src     => s_ALU_src,
                 o_mem_WE      => s_DMemWr, --must
                 o_zero_sign   => s_zero_sign,
                 o_ALU_mem     => s_ALU_mem,
                 o_reg_file_WE => s_RegWr, -- must
                 o_halt        => s_Halt --must
            );


    ALU_control_unit_inst: ALU_control_unit 
        port map(
                 i_alu_op      => s_ALU_op,
                 i_func3       => s_Inst(14 downto 12), -- must 
                 i_func7_5     => s_Inst(30), --must
                 o_alu_control => s_ALU_control
                 );


    Extenders_s: Extenders
            port map(
                     DATA_IN  => s_Inst(31 downto 20), --must
                     FLAG_IN  => s_zero_sign,  
                     DATA_OUT => s_Extended_imm
                 );

    ALU_inst: ALU
        port map( 
                 i_reg1_data    => s_DATA_TO_READ1, 
                 i_reg2_data    => s_DATA_TO_READ2, 
                 i_extended_imm => s_Extended_imm,
                 i_ALU_control  => s_ALU_control,
                 i_ALU_src      => s_ALU_src,
                 o_ALU_out      => s_ALU_out --must, because ALU out is also connected to Dmem Addr
             ); 

    Mux2t1_N_dataflow_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ALU_mem,
                     i_D0 => s_ALU_out, --change its name and assign DMemData to that because now confusing
                     i_D1 => s_DMemOut, --must
                     o_O  => s_RegWrData); --must

    -- s_Halt is connected to an output control from decoding the Halt instruction (Opcode: 01 0100)


end structure;

