library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_alu is
end entity;

architecture behavioral of tb_alu is

    --------------------------------------------------------------------
    -- DUT component (OLD ALU, unchanged)
    --------------------------------------------------------------------
    component ALU is
        port(
            i_A             : in  std_logic_vector(31 downto 0);
            i_B             : in  std_logic_vector(31 downto 0);
            i_ALU_select    : in  std_logic_vector(2 downto 0);
            i_ALU_nAdd_sub  : in  std_logic;
            i_logcl_arith   : in  std_logic;
            i_right_left    : in  std_logic;
            i_ALU_lui       : in  std_logic;
            i_jal_or_jalr   : in  std_logic;
            o_eq            : out std_logic;
            o_lt            : out std_logic;
            o_ltu           : out std_logic;
            o_ge            : out std_logic;
            o_geu           : out std_logic;
            o_ALU_out       : out std_logic_vector(31 downto 0)
        );
    end component;

    --------------------------------------------------------------------
    -- ALU op constants (NO DESIGN CHANGE)
    --------------------------------------------------------------------
    constant ALU_ADD   : std_logic_vector(2 downto 0) := "000";
    constant ALU_SLT   : std_logic_vector(2 downto 0) := "001";
    constant ALU_SLTU  : std_logic_vector(2 downto 0) := "010";
    constant ALU_AND   : std_logic_vector(2 downto 0) := "011";
    constant ALU_OR    : std_logic_vector(2 downto 0) := "100";
    constant ALU_XOR   : std_logic_vector(2 downto 0) := "101";
    constant ALU_SHIFT : std_logic_vector(2 downto 0) := "110";

    --------------------------------------------------------------------
    -- signals
    --------------------------------------------------------------------
    signal i_A, i_B : std_logic_vector(31 downto 0);
    signal i_ALU_select : std_logic_vector(2 downto 0);

    signal i_ALU_nAdd_sub : std_logic;
    signal i_logcl_arith  : std_logic;
    signal i_right_left   : std_logic;
    signal i_ALU_lui      : std_logic;
    signal i_jal_or_jalr  : std_logic;

    signal o_eq, o_lt, o_ltu, o_ge, o_geu : std_logic;
    signal o_ALU_out : std_logic_vector(31 downto 0);

begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    UUT : ALU
        port map(
            i_A => i_A,
            i_B => i_B,
            i_ALU_select => i_ALU_select,
            i_ALU_nAdd_sub => i_ALU_nAdd_sub,
            i_logcl_arith => i_logcl_arith,
            i_right_left => i_right_left,
            i_ALU_lui => i_ALU_lui,
            i_jal_or_jalr => i_jal_or_jalr,
            o_eq => o_eq,
            o_lt => o_lt,
            o_ltu => o_ltu,
            o_ge => o_ge,
            o_geu => o_geu,
            o_ALU_out => o_ALU_out
        );

    --------------------------------------------------------------------
    -- TEST PLAN
    --------------------------------------------------------------------
    process
    begin

        ----------------------------------------------------------------
        -- RESET CONTROL SIGNALS
        ----------------------------------------------------------------
        i_ALU_nAdd_sub <= '0';
        i_logcl_arith  <= '0';
        i_right_left   <= '0';
        i_ALU_lui      <= '0';
        i_jal_or_jalr  <= '0';


    -- ADD tricky: overflow case
    i_ALU_select <= ALU_ADD;
    i_A <= x"7FFFFFFF"; i_B <= x"00000001"; wait for 20 ns;

    -- SUB tricky: negative result / sign boundary
    i_ALU_select <= ALU_ADD;
    i_ALU_nAdd_sub <= '1';
    i_A <= x"00000000"; i_B <= x"00000001"; wait for 20 ns;
    i_ALU_nAdd_sub <= '0';

    -- SLT tricky: negative vs positive comparison
    i_ALU_select <= ALU_SLT;
    i_A <= x"FFFFFFFF"; i_B <= x"00000001"; wait for 20 ns;

    -- SLTU tricky: unsigned max vs small value
    i_ALU_select <= ALU_SLTU;
    i_A <= x"FFFFFFFF"; i_B <= x"00000001"; wait for 20 ns;

    -- AND tricky: complementary bit pattern test
    i_ALU_select <= ALU_AND;
    i_A <= x"AAAAAAAA"; i_B <= x"55555555"; wait for 20 ns;

    -- OR tricky: all-zero vs all-one
    i_ALU_select <= ALU_OR;
    i_A <= x"00000000"; i_B <= x"FFFFFFFF"; wait for 20 ns;

    -- XOR tricky: identical operands (should zero out)
    i_ALU_select <= ALU_XOR;
    i_A <= x"FFFFFFFF"; i_B <= x"FFFFFFFF"; wait for 20 ns;

    -- SHIFT tricky: sign bit shift test
    i_ALU_select <= ALU_SHIFT;
    i_right_left <= '1';
    i_logcl_arith <= '0';
    i_A <= x"80000000"; i_B <= x"00000001"; wait for 20 ns;





        ----------------------------------------------------------------
        -- 1. ADD (normal + edge)
        ----------------------------------------------------------------
        i_ALU_select <= ALU_ADD;

        i_A <= x"00000001"; i_B <= x"00000001"; wait for 20 ns;
        i_A <= x"7FFFFFFF"; i_B <= x"00000001"; wait for 20 ns; -- overflow
        i_A <= x"FFFFFFFF"; i_B <= x"00000001"; wait for 20 ns; -- wrap
        i_A <= x"00000000"; i_B <= x"00000000"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 2. SUB (positive, negative, edge)
        ----------------------------------------------------------------
        i_ALU_nAdd_sub <= '1';

        i_A <= x"00000005"; i_B <= x"00000003"; wait for 20 ns;
        i_A <= x"00000003"; i_B <= x"00000005"; wait for 20 ns;
        i_A <= x"80000000"; i_B <= x"00000001"; wait for 20 ns;

        i_ALU_nAdd_sub <= '0';

        ----------------------------------------------------------------
        -- 3. AND (masking patterns)
        ----------------------------------------------------------------
        i_ALU_select <= ALU_AND;

        i_A <= x"FFFFFFFF"; i_B <= x"0F0F0F0F"; wait for 20 ns;
        i_A <= x"AAAAAAAA"; i_B <= x"55555555"; wait for 20 ns;
        i_A <= x"00000000"; i_B <= x"FFFFFFFF"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 4. OR (bit coverage)
        ----------------------------------------------------------------
        i_ALU_select <= ALU_OR;

        i_A <= x"00000000"; i_B <= x"00000000"; wait for 20 ns;
        i_A <= x"F0F0F0F0"; i_B <= x"0F0F0F0F"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 5. XOR (difference detection)
        ----------------------------------------------------------------
        i_ALU_select <= ALU_XOR;

        i_A <= x"AAAAAAAA"; i_B <= x"55555555"; wait for 20 ns;
        i_A <= x"FFFFFFFF"; i_B <= x"FFFFFFFF"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 6. SLT (signed comparisons)
        ----------------------------------------------------------------
        i_ALU_select <= ALU_SLT;

        i_A <= x"FFFFFFFF"; i_B <= x"00000001"; wait for 20 ns;
        i_A <= x"00000001"; i_B <= x"FFFFFFFF"; wait for 20 ns;
        i_A <= x"7FFFFFFF"; i_B <= x"80000000"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 7. SLTU (unsigned comparisons)
        ----------------------------------------------------------------
        i_ALU_select <= ALU_SLTU;

        i_A <= x"FFFFFFFF"; i_B <= x"00000001"; wait for 20 ns;
        i_A <= x"00000001"; i_B <= x"FFFFFFFF"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 8. SHIFT LEFT LOGICAL
        ----------------------------------------------------------------
        i_ALU_select <= ALU_SHIFT;
        i_logcl_arith <= '0';
        i_right_left <= '0';

        i_A <= x"00000001"; i_B <= x"00000001"; wait for 20 ns;
        i_A <= x"00000001"; i_B <= x"00000010"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 9. SHIFT RIGHT LOGICAL
        ----------------------------------------------------------------
        i_right_left <= '1';
        i_logcl_arith <= '0';

        i_A <= x"80000000"; i_B <= x"00000001"; wait for 20 ns;
        i_A <= x"FFFFFFFF"; i_B <= x"00000004"; wait for 20 ns;

        ----------------------------------------------------------------
        -- 10. SHIFT RIGHT ARITHMETIC
        ----------------------------------------------------------------
        i_logcl_arith <= '1';

        i_A <= x"80000000"; i_B <= x"00000001"; wait for 20 ns;
        i_A <= x"F0000000"; i_B <= x"00000004"; wait for 20 ns;

        wait;

    end process;

end architecture;
