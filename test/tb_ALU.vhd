library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_ALU is
end entity tb_ALU;

architecture behavioral of tb_ALU is

    component ALU is
        port(
            i_A            : in  std_logic_vector(31 downto 0);
            i_B            : in  std_logic_vector(31 downto 0);
            i_ALU_select   : in  std_logic_vector(2 downto 0);
            i_ALU_nAdd_sub : in  std_logic;
            i_logcl_arith  : in  std_logic;
            i_right_left   : in  std_logic;
            i_ALU_lui      : in  std_logic;
            i_jal_or_jalr  : in  std_logic;
            o_eq           : out std_logic;
            o_lt           : out std_logic;
            o_ltu          : out std_logic;
            o_ge           : out std_logic;
            o_geu          : out std_logic;
            o_ALU_out      : out std_logic_vector(31 downto 0)
        );
    end component;

    signal i_A            : std_logic_vector(31 downto 0);
    signal i_B            : std_logic_vector(31 downto 0);
    signal i_ALU_select   : std_logic_vector(2 downto 0);
    signal i_ALU_nAdd_sub : std_logic;
    signal i_logcl_arith  : std_logic;
    signal i_right_left   : std_logic;
    signal i_ALU_lui      : std_logic;
    signal i_jal_or_jalr  : std_logic;
    signal o_eq           : std_logic;
    signal o_lt           : std_logic;
    signal o_ltu          : std_logic;
    signal o_ge           : std_logic;
    signal o_geu          : std_logic;
    signal o_ALU_out      : std_logic_vector(31 downto 0);

begin

    UUT : ALU
        port map(
            i_A            => i_A,
            i_B            => i_B,
            i_ALU_select   => i_ALU_select,
            i_ALU_nAdd_sub => i_ALU_nAdd_sub,
            i_logcl_arith  => i_logcl_arith,
            i_right_left   => i_right_left,
            i_ALU_lui      => i_ALU_lui,
            i_jal_or_jalr  => i_jal_or_jalr,
            o_eq           => o_eq,
            o_lt           => o_lt,
            o_ltu          => o_ltu,
            o_ge           => o_ge,
            o_geu          => o_geu,
            o_ALU_out      => o_ALU_out
        );

    process
    begin

        -- ---------------------------------------------------------
        -- ADD  (select=000, nAdd_sub=0)
        -- expected: 30
        -- ---------------------------------------------------------
        i_A <= x"0000000A"; i_B <= x"00000014";
        i_ALU_select <= "000"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- SUB  (select=000, nAdd_sub=1)
        -- expected: 10 (20 - 10), o_lt=0, o_eq=0, o_ge=1
        -- ---------------------------------------------------------
        i_A <= x"00000014"; i_B <= x"0000000A";
        i_ALU_select <= "000"; i_ALU_nAdd_sub <= '1';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- SUB producing 0: expected o_eq=1, o_ge=1
        i_A <= x"0000000A"; i_B <= x"0000000A";
        i_ALU_select <= "000"; i_ALU_nAdd_sub <= '1';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- SLT  (select=001, nAdd_sub=1)
        -- A < B signed: expected out=1, o_lt=1
        -- ---------------------------------------------------------
        i_A <= x"00000005"; i_B <= x"0000000A";
        i_ALU_select <= "001"; i_ALU_nAdd_sub <= '1';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- A > B signed: expected out=0, o_lt=0, o_ge=1
        i_A <= x"0000000A"; i_B <= x"00000005";
        i_ALU_select <= "001"; i_ALU_nAdd_sub <= '1';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- negative A < positive B: expected out=1
        i_A <= x"FFFFFFFF"; i_B <= x"00000001";
        i_ALU_select <= "001"; i_ALU_nAdd_sub <= '1';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- SLTU (select=010, nAdd_sub=1)
        -- 1 <u 0xFFFFFFFF: expected out=1, o_ltu=1
        -- ---------------------------------------------------------
        i_A <= x"00000001"; i_B <= x"FFFFFFFF";
        i_ALU_select <= "010"; i_ALU_nAdd_sub <= '1';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- 0xFFFFFFFF >=u 1: expected out=0, o_ltu=0, o_geu=1
        i_A <= x"FFFFFFFF"; i_B <= x"00000001";
        i_ALU_select <= "010"; i_ALU_nAdd_sub <= '1';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- AND  (select=011)
        -- 0xFF & 0x0F = 0x0F
        -- ---------------------------------------------------------
        i_A <= x"000000FF"; i_B <= x"0000000F";
        i_ALU_select <= "011"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- OR   (select=100)
        -- 0xF0 | 0x0F = 0xFF
        -- ---------------------------------------------------------
        i_A <= x"000000F0"; i_B <= x"0000000F";
        i_ALU_select <= "100"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- XOR  (select=101)
        -- 0xFF xor 0xFF = 0x00
        -- ---------------------------------------------------------
        i_A <= x"000000FF"; i_B <= x"000000FF";
        i_ALU_select <= "101"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- SLL  (select=110, right_left=0, logcl_arith=0)
        -- 1 << 4 = 16
        -- ---------------------------------------------------------
        i_A <= x"00000001"; i_B <= x"00000004";
        i_ALU_select <= "110"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- SRL  (select=110, right_left=1, logcl_arith=0)
        -- 0x80000000 >> 1 logical = 0x40000000
        -- ---------------------------------------------------------
        i_A <= x"80000000"; i_B <= x"00000001";
        i_ALU_select <= "110"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '1';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- SRA  (select=110, right_left=1, logcl_arith=1)
        -- 0x80000000 >> 1 arithmetic = 0xC0000000
        -- ---------------------------------------------------------
        i_A <= x"80000000"; i_B <= x"00000001";
        i_ALU_select <= "110"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '1'; i_right_left <= '1';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- LUI  (i_ALU_lui=1)
        -- output should just be i_B regardless of select
        -- ---------------------------------------------------------
        i_A <= x"00000000"; i_B <= x"DEADB000";
        i_ALU_select <= "000"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '1'; i_jal_or_jalr <= '0';
        wait for 20 ns;

        -- ---------------------------------------------------------
        -- JAL/JALR  (i_jal_or_jalr=1)
        -- B is replaced with 0x4, so output = A + 4
        -- A=0x100 -> expected 0x104
        -- ---------------------------------------------------------
        i_A <= x"00000100"; i_B <= x"00000000";
        i_ALU_select <= "000"; i_ALU_nAdd_sub <= '0';
        i_logcl_arith <= '0'; i_right_left <= '0';
        i_ALU_lui <= '0'; i_jal_or_jalr <= '1';
        wait for 20 ns;

        wait;
    end process;

end behavioral;
