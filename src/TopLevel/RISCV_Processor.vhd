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

-- all the external connections are used by the ToolFlow
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

    -- mem component is used to infer Memory to store Instructions and Data
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

    -- PC componnet is used to 
    component PC is
        generic(Reset_value : std_logic_vector(31 downto 0));
        port(i_pc_in  : in  std_logic_vector(31 downto 0); -- new data to be written
             o_pc_out : out std_logic_vector(31 downto 0); -- pc output
             i_reset  : in  std_logic; -- reset to 0
             i_clk    : in  std_logic); -- clock
    end component PC;

    component PC_adder is
        port(i_current_pc : in  std_logic_vector(31 downto 0); -- current pc, 
             o_new_pc     : out std_logic_vector(31 downto 0)); -- output (current + 4)
    end component PC_adder;

    component ripple_carry_N_bit_adder is
        generic (N : integer);
        port( x  	   : in std_logic_vector(N-1 downto 0);
              y        : in std_logic_vector(N-1 downto 0);
              c_in     : in std_logic;
              sum      : out std_logic_vector(N-1 downto 0); -- outputs is +1 of inputs
              c_out    : out std_logic;
              overflow : out std_logic);
    end component ripple_carry_N_bit_adder;

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
        port( i_A        	 : in std_logic_vector(31 downto 0);   -- 1st operand rs1/pc
              i_B            : in std_logic_vector(31 downto 0);   -- 2nd operand rs2/imm
              i_ALU_select   : in std_logic_vector(2 downto 0);    -- ALU mux select
              i_ALU_nAdd_sub : in std_logic;                       -- ALU add sub control
              i_logcl_arith  : in std_logic;                       -- is the shfit logical or arithmetic
              i_right_left   : in std_logic;                       -- is the shift to the right or left
              i_jal_or_jalr  : in std_logic;                       -- mux select that adds 0x4 to A
              o_eq           : out std_logic;
              o_lt           : out std_logic;
              o_ltu          : out std_logic;
              o_ge           : out std_logic;
              o_geu          : out std_logic;
              o_ALU_out      : out std_logic_vector(31 downto 0)); -- output
    end component ALU;

    component Extenders_wrapper is
        port(
             i_instruction  : in std_logic_vector(31 downto 7);
             i_imm_select   : in std_logic_vector(2 downto 0);
             o_extended_imm : out std_logic_vector(31 downto 0)
            );
    end component Extenders_wrapper;

    component Main_control_unit is
	port(
            i_Opcode  : in std_logic_vector(6 downto 0); -- the opcode we are decoding
            o_ALU_op  : out std_logic_vector(1 downto 0); -- two bit ALU opcode
            o_Imm_select : out std_logic_vector(2 downto 0); -- which immediate ALU should use  
            o_ALU_A_src : out std_logic; -- control for choosing between pc  or rs1 out
            o_ALU_src : out std_logic; -- control for choosing between imm or rs2 out
            o_mem_WE  : out std_logic; -- control to when data mem can be written
            o_ALU_mem : out std_logic;  -- control for writing to reg from ALU or memory
            o_reg_file_WE  : out std_logic;  -- control for when data to reg file is written 
            o_lui     : out std_logic; -- when 1, routes immediate and not the ALU out to reg
            o_branch  : out std_logic; -- should branch or no
            o_jal     : out std_logic;
            o_jalr    : out std_logic;
            o_halt : out std_logic --used as wfi
        );
    end component Main_control_unit;


    component ALU_control_unit is
        port(i_alu_op      : in  std_logic_vector(1 downto 0);
             i_func3       : in  std_logic_vector(2 downto 0);
             i_func7_5     : in  std_logic;
             i_lui         : in  std_logic; -- if lui, then just route i_B to out
             o_alu_select  : out std_logic_vector(2 downto 0); -- choose what output should chose
             o_nAdd_sub    : out std_logic; -- add subtraction flag for ALU
             o_logcl_arith : out std_logic;
             o_right_left  : out std_logic
         );
    end component ALU_control_unit;

    component mux2t1_N_dataflow is
        generic(N : integer); -- Generic of type integer for input/output data width. Default value is 32.
        port(i_S          : in std_logic;
           i_D0         : in std_logic_vector(N-1 downto 0);
           i_D1         : in std_logic_vector(N-1 downto 0);
           o_O          : out std_logic_vector(N-1 downto 0));
    end component mux2t1_N_dataflow;

    component Byte_half_word_selector is
        port (
              i_mem_out_word  : in std_logic_vector(31 downto 0); -- the full word
              i_mem_b_hw_addr : in std_logic_vector(1 downto 0);  -- the two sliced lsbs of full address
              i_func3         : in std_logic_vector(2 downto 0);
              o_selected_data : out std_logic_vector(31 downto 0)
          );
    end component Byte_half_word_selector;

    component branch_decision is
        port (
              i_eq            : in std_logic;
              i_lt            : in std_logic;
              i_ltu           : in std_logic;
              i_ge            : in std_logic;
              i_geu           : in std_logic;
              i_is_branch     : in std_logic;
              i_func3         : in std_logic_vector(2 downto 0);
              o_should_branch : out std_logic);
    end component branch_decision;
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
    signal s_Next_pc: std_logic_vector(31 downto 0); -- either from pc+4 or branch
    signal s_DATA_TO_READ1 : std_logic_vector(31 downto 0); -- the 1st output of reg file
    signal s_DATA_TO_READ2 : std_logic_vector(31 downto 0); -- the 2nd output of reg file
    signal s_Extended_imm  : std_logic_vector(31 downto 0); -- connected to ALU's imm
    signal s_Imm_select    : std_logic_vector(2 downto 0);  -- select with extended immediate ALU should use
    signal s_ALU_A         : std_logic_vector(31 downto 0); -- one of rs1 or PC
    signal s_ALU_B         : std_logic_vector(31 downto 0); -- one of rs2 or imm
    signal s_lui       : std_logic;  -- signal that goes to ALU, so it routes shifted immediate directly to reg when lui
    signal s_ALU_op : std_logic_vector(1 downto 0); -- ALU opcode
    signal s_ALU_src : std_logic; -- reg2 or imm
    signal s_ALU_A_src : std_logic; -- reg1 or pc
    signal s_ALU_mem   : std_logic; -- ALU or memory data written to reg file
    signal s_branch    : std_logic; -- is this instruction a branch instruction
    signal s_jal       : std_logic;
    signal s_jalr      : std_logic;
    signal s_ALU_select : std_logic_vector(2 downto 0); -- ALU mux select
    signal s_logcl_arith : std_logic;  -- this is logical or arithmetic flag
    signal s_right_left  : std_logic; -- this is the right of left shift flag
    signal s_ALU_nAdd_sub : std_logic; -- ALU add or sub flag, driven by ALU control unit
    signal s_ALU_out : std_logic_vector(31 downto 0);
    signal s_selected_mem_data : std_logic_vector(31 downto 0); -- this is after it goes through selector, final data to be written
    signal s_should_branch : std_logic; -- the output of the branch decision box

    signal s_branch_pc_addr : std_logic_vector(31 downto 0); -- in case brnach is taken calculated address
    signal s_branch_pc_addr_input_A : std_logic_vector(31 downto 0);


    -- flags from ALU going to branch decision box
    signal s_ALU_eq : std_logic; 
    signal s_ALU_lt : std_logic;
    signal s_ALU_ltu : std_logic; 
    signal s_ALU_ge  : std_logic;
    signal s_ALU_geu : std_logic;

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
        generic map(Reset_value => 32x"00400000")
        port map(
                 i_pc_in  => s_Next_pc, -- connect pc_in to pc_adder out
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
                 o_Imm_select  => s_Imm_select,
                 o_ALU_A_src   => s_ALU_A_src,
                 o_ALU_src     => s_ALU_src,
                 o_mem_WE      => s_DMemWr, --must
                 o_ALU_mem     => s_ALU_mem,
                 o_reg_file_WE => s_RegWr, -- must
                 o_lui         => s_lui, -- chose shifter lui imm over ALU output
                 o_branch      => s_branch,
                 o_jal         => s_jal,
                 o_jalr        => s_jalr,
                 o_halt        => s_Halt --must
            );


    ALU_control_unit_inst: ALU_control_unit 
        port map(
                 i_alu_op      => s_ALU_op,
                 i_func3       => s_Inst(14 downto 12), -- must 
                 i_func7_5     => s_Inst(30), --must
                 i_lui         => s_lui, -- lui control signal coming from main control
                 o_alu_select  => s_ALU_select, -- ALU mux select
                 o_nAdd_sub    => s_ALU_nAdd_sub, -- add sub flag
                 o_logcl_arith => s_logcl_arith,  -- this is logical or arithmetic flag
                 o_right_left  => s_right_left    -- this is the right of left shift flag
                 );


    Extenders_s: Extenders_wrapper
            port map(
                     i_instruction  => s_Inst(31 downto 7), --must
                     i_imm_select   => s_Imm_select, 
                     o_extended_imm => s_Extended_imm
                 );

    -- select either rs1 or extended PC
    Mux2t1_N_ALU_A:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ALU_A_src,
                     i_D0 => s_DATA_TO_READ1,
                     i_D1 => s_PC,
                     o_O  => s_ALU_A); 

    -- select either rs2 or extended imm
    Mux2t1_N_ALU_B:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ALU_src,
                     i_D0 => s_DATA_TO_READ2,
                     i_D1 => s_Extended_imm,
                     o_O  => s_ALU_B); 

    ALU_inst: ALU
        port map( 
                 i_A            => s_ALU_A, -- either rs1 or pc 
                 i_B            => s_ALU_B, -- either rs2 or imm
                 i_ALU_select   => s_ALU_select, -- which component's output should ALU output. 3 bit select
                 i_ALU_nAdd_sub => s_ALU_nAdd_sub,
                 i_logcl_arith  => s_logcl_arith,                       -- is the shfit logical or arithmetic
                 i_right_left   => s_right_left,                    -- is the shift to the right or left
                 i_jal_or_jalr  => s_jal or s_jalr,
                 o_eq           => s_ALU_eq,
                 o_lt           => s_ALU_lt,
                 o_ltu          => s_ALU_ltu,
                 o_ge           => s_ALU_ge,
                 o_geu          => s_ALU_geu,
                 o_ALU_out      => s_ALU_out --must, because ALU out is also connected to Dmem Addr
             ); 

    -- selects the appropriate slice or all of the word depending on lb, lh or lw
    Selector_ins: Byte_half_word_selector
        port map(
              i_mem_out_word  => s_DMemOut,
              i_mem_b_hw_addr => s_DMemAddr(1 downto 0),
              i_func3         => s_Inst(14 downto 12),
              o_selected_data => s_selected_mem_data
          );

    Mux2t1_N_dataflow_inst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_ALU_mem,
                     i_D0 => s_ALU_out, --change its name and assign DMemData to that because now confusing
                     i_D1 => s_selected_mem_data, --must
                     o_O  => s_RegWrData); --must

    branch_brain: branch_decision 
        port map(
              i_eq         =>  s_ALU_eq,
              i_lt         =>  s_ALU_lt,
              i_ltu        =>  s_ALU_ltu,
              i_ge         =>  s_ALU_ge,
              i_geu        =>  s_ALU_geu,
              i_is_branch  =>  s_branch,   
              i_func3      =>  s_Inst(14 downto 12), 
              o_should_branch => s_should_branch
              );

    Mux2t1_N_jalr:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_jalr,
                     i_D0 => s_PC, --changed
                     i_D1 => s_DATA_TO_READ1,
                     o_O  => s_branch_pc_addr_input_A);

    Branch_adder: ripple_carry_N_bit_adder
        generic map(N => 32)
        port map(x    => s_Extended_imm,  
                 y    => s_branch_pc_addr_input_A,  -- add pc to immedaite
                 c_in => '0',  
                 sum  => s_branch_pc_addr); -- outputs is +1 of inputs

    Mux2t1_N_Bnst:  mux2t1_N_dataflow
            generic map(N => 32)
            port map(
                     i_S  => s_should_branch or s_jal or s_jalr,
                     i_D0 => s_New_pc, --change its name and assign DMemData to that because now confusing
                     i_D1 => s_branch_pc_addr, --must
                     o_O  => s_Next_pc); --must
    -- s_Halt is connected to an output control from decoding the Halt instruction (Opcode: 01 0100)


end structure;

