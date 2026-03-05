-- Date		   : Feb 23, 2026
-- File		   : tb_MySecondRISCVDatapath.vhd	 
-- Designer    : Salah Nasriddinov
-- Description : This file implements a testbench for my second datapath


library IEEE;
use IEEE.std_logic_1164.all;

entity tb_MySecondRISCVDatapath is
	generic(CLK_PERIOD : time := 10 ns);
end tb_MySecondRISCVDatapath;

architecture behavior of tb_MySecondRISCVDatapath is

	component MySecondRISCVDatapath is
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
	end component MySecondRISCVDatapath;

	constant N : integer := 32;


	signal CLK_wire : std_logic;
	signal imm_wire : std_logic_vector(11 downto 0);
	signal rs1_wire : std_logic_vector(4 downto 0);
	signal rs2_wire : std_logic_vector(4 downto 0);
	signal rd_wire : std_logic_vector(4 downto 0);
	signal ALU_src_wire : std_logic;
	signal nAdd_sub_wire : std_logic;
	signal reset_wire : std_logic;
	signal WRITE_EN_wire : std_logic;
    
    signal mem_WE_wire : std_logic;
    signal zero_or_sign_extend_flag_wire : std_logic;
    signal Alu_or_memory_data_flag_wire : std_logic;

begin
	DUT: MySecondRISCVDatapath
			generic map(N => 32)
			port map(
					 imm	   => imm_wire,		  -- the immediate value
					 rs1	   => rs1_wire,		  -- address of source reg1
					 rs2	   => rs2_wire,		  -- address of source reg2
					 rd		   => rd_wire,		  -- address of destination reg
					 ALU_src   => ALU_src_wire,   -- wether immediate is used instead of rs2
					 nAdd_sub  => nAdd_sub_wire,  -- is rs1 + rs2/imm OR rs1 - rs2/imm
					 reset	   => reset_wire,	  -- reset all the registers to 0
					 CLOCK_IN  => CLK_wire,		  -- CLOCK for register file
					 WRITE_EN  => WRITE_EN_wire,  -- write enable
                     mem_WE    => mem_WE_wire,    -- enabling memory writes
                     zero_or_sign_extend_flag => zero_or_sign_extend_flag_wire,
                     Alu_or_memory_data_flag  => Alu_or_memory_data_flag_wire
				 );

  -- This process sets the clock value (low for gCLK_HPER, then high
  -- for gCLK_HPER). Absent a "wait" command, processes restart 
  -- at the beginning once they have reached the final statement.
	P_CLK: process
	begin
		CLK_wire <= '1';
		wait for CLK_PERIOD/2; -- half of it is 1
		CLK_wire <= '0';
		wait for CLK_PERIOD/2; -- half of it is 0
	end process;

	RESET_R_FILE: process
	begin
		reset_wire <= '0';
		wait for CLK_PERIOD/4;
		reset_wire <= '1';
		wait for CLK_PERIOD;
		reset_wire <= '0';
		wait;
	end process;

	P_STIMULI: process
	begin
		wait for CLK_PERIOD;   -- for waveform clarity;
		wait for CLK_PERIOD/4; -- for waveform clarity;

        -- for loads, lw rd, imm(rs1) (comment: rs2 doesn't matter)
        -- for store, sw rs2,imm(rs1) (comment: rd doesn't matter) not writing to any reg

        -- addi x10 ,zero ,1280 
		rs1_wire <= 5x"00";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"0A";
		imm_wire <= 12x"500";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '0';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   

        -- lw x25 , 0( x10)
		rs1_wire <= 5x"0A";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"19";
		imm_wire <= 12x"000";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   

        -- lw x27 , 0( x10)
		rs1_wire <= 5x"0A";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"1B";
		imm_wire <= 12x"000";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   

        -- addi x11 ,zero ,1536 
		rs1_wire <= 5x"00";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"0B";
		imm_wire <= 12x"600";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '0';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   

        -- lw x26 , 0( x11)
		rs1_wire <= 5x"0B";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"1A";
		imm_wire <= 12x"000";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   

        -----  above are the loads   


        -- after above:
        -- x25 = 0x10010000
        -- x26 = 0x10010100
        -- x27 = 0x10010000


        -- lw x1 , 0( x25)
		rs1_wire <= 5x"19";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"01";
		imm_wire <= 12x"000";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   


        -- lw x2 , 4( x25)
		rs1_wire <= 5x"19";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"02";
		imm_wire <= 12x"004";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   



        -- add x1 , x1 , x2
		rs1_wire <= 5x"01";
		rs2_wire <= 5x"02";
		rd_wire  <= 5x"01";
		imm_wire <= 12x"0--";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '0';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '-';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   

        -- STOPPED HERE MY STORE IS NOT WORKIGN FOR NOW NEED TO DEBUG

        -- sw x1 , 0( x26) 
		rs1_wire <= 5x"1A";
		rs2_wire <= 5x"01";
		rd_wire  <= 5x"0-";
		imm_wire <= 12x"000";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '0';

        mem_WE_wire <= '1';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '-';
		wait for CLK_PERIOD;   

        -- lw x2 , 8( x25)
		rs1_wire <= 5x"19";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"02";
		imm_wire <= 12x"008";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   


        -- add x1 , x1 , x2 
		rs1_wire <= 5x"01";
		rs2_wire <= 5x"02";
		rd_wire  <= 5x"01";
		imm_wire <= 12x"0--";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '0';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '-';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   


        -- sw x1 , 4( x26) 
		rs1_wire <= 5x"1A";
		rs2_wire <= 5x"01";
		rd_wire  <= 5x"0-";
		imm_wire <= 12x"004";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '0';

        mem_WE_wire <= '1';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '-';
		wait for CLK_PERIOD;   

        -- lw x2 , 12( x25)
		rs1_wire <= 5x"19";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"02";
		imm_wire <= 12x"00C";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   



        -- add x1 , x1 , x2
		rs1_wire <= 5x"01";
		rs2_wire <= 5x"02";
		rd_wire  <= 5x"01";
		imm_wire <= 12x"0--";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '0';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '-';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   


        -- sw x1 , 8( x26)
		rs1_wire <= 5x"1A";
		rs2_wire <= 5x"01";
		rd_wire  <= 5x"0-";
		imm_wire <= 12x"008";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '0';

        mem_WE_wire <= '1';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '-';
		wait for CLK_PERIOD;   

        -- lw x2 , 16( x25)
		rs1_wire <= 5x"19";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"02";
		imm_wire <= 12x"010";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   


        -- add x1 , x1 , x2
		rs1_wire <= 5x"01";
		rs2_wire <= 5x"02";
		rd_wire  <= 5x"01";
		imm_wire <= 12x"0--";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '0';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '-';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   


        -- sw x1 , 12( x26)
		rs1_wire <= 5x"1A";
		rs2_wire <= 5x"01";
		rd_wire  <= 5x"0-";
		imm_wire <= 12x"00C";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '0';

        mem_WE_wire <= '1';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '-';
		wait for CLK_PERIOD;   

        -- lw x2 , 20( x25)
		rs1_wire <= 5x"19";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"02";
		imm_wire <= 12x"014";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   


        -- add x1 , x1 , x2
		rs1_wire <= 5x"01";
		rs2_wire <= 5x"02";
		rd_wire  <= 5x"01";
		imm_wire <= 12x"0--";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '0';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '-';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   


        -- sw x1 , 16( x26)
		rs1_wire <= 5x"1A";
		rs2_wire <= 5x"01";
		rd_wire  <= 5x"0-";
		imm_wire <= 12x"010";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '0';

        mem_WE_wire <= '1';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '-';
		wait for CLK_PERIOD;   

        -- lw x2 , 24( x25)
		rs1_wire <= 5x"19";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"02";
		imm_wire <= 12x"018";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '1';
		wait for CLK_PERIOD;   


        -- add x1 , x1 , x2
		rs1_wire <= 5x"01";
		rs2_wire <= 5x"02";
		rd_wire  <= 5x"01";
		imm_wire <= 12x"0--";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '0';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '-';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   


        -- addi x27 , x27 , 512 
		rs1_wire <= 5x"1B";
		rs2_wire <= 5x"0-";
		rd_wire  <= 5x"1B";
		imm_wire <= 12x"200";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '1';

        mem_WE_wire <= '0';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '0';
		wait for CLK_PERIOD;   

        -- sw x1 , -4(x27)
		rs1_wire <= 5x"1B";
		rs2_wire <= 5x"01";
		rd_wire  <= 5x"0-";
		imm_wire <= 12x"FFC";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '0';

        mem_WE_wire <= '1';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '-';
		wait for CLK_PERIOD;   

        -- sw x1 , -4(x27)
		rs1_wire <= 5x"1B";
		rs2_wire <= 5x"01";
		rd_wire  <= 5x"0-";
		imm_wire <= 12x"FFC";
		nAdd_sub_wire <= '0';
		ALU_src_wire  <= '1';
		WRITE_EN_wire <= '0';

        mem_WE_wire <= '1';
        zero_or_sign_extend_flag_wire <= '1';
        Alu_or_memory_data_flag_wire <= '-';
		wait for CLK_PERIOD;   



		WRITE_EN_wire <= '0';
        mem_WE_wire <= '0';


		wait;
	end process;
  
end behavior;
