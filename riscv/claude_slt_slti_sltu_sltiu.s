# ============================================================
# RISC-V Stress Test — SLT, SLTI, SLTU, SLTIU
# (plus all previously verified instructions)
# ============================================================
# SLT  rd, rs1, rs2  — rd = (rs1 < rs2)  signed,   1 or 0
# SLTI rd, rs1, imm  — rd = (rs1 < imm)  signed,   1 or 0
# SLTU rd, rs1, rs2  — rd = (rs1 < rs2)  unsigned, 1 or 0
# SLTIU rd, rs1, imm — rd = (rs1 < imm)  unsigned, 1 or 0
#
# Key correctness axes:
#   - Result is exactly 0 or 1, never anything else
#   - Signed vs unsigned interpretation of the same bit pattern
#   - Boundary: equal operands -> result must be 0 (strictly less than)
#   - Negative numbers: signed -1 < 0, unsigned 0xFFFFFFFF > 0
#   - INT32_MIN < 0 signed, but INT32_MIN > anything unsigned (except itself)
#   - SLTIU sign-extends the 12-bit immediate before unsigned compare
#   - RAW hazards: SLT result consumed next cycle
#   - SLT result fed into logic, memory, and arithmetic
# ============================================================

.data
scratch: .space 64

.text
.global _start

_start:
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)

    # --------------------------------------------------------
    # Phase 1: SLT basics — signed comparison
    # --------------------------------------------------------
    # 1 < 2  -> 1
    addi x1, x0, 1
    addi x2, x0, 2
    slt  x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # 2 < 1  -> 0
    slt  x3, x2, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # equal: 1 < 1 -> 0
    slt  x3, x1, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # -1 < 0  -> 1  (signed)
    addi x1, x0, -1
    addi x2, x0,  0
    slt  x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # 0 < -1  -> 0  (signed)
    slt  x3, x2, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # INT32_MIN < 0  -> 1
    lui  x1, 0x80000        # x1 = INT32_MIN
    addi x2, x0, 0
    slt  x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # 0 < INT32_MIN  -> 0
    slt  x3, x2, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # INT32_MIN < INT32_MAX  -> 1
    lui  x1, 0x80000        # INT32_MIN
    lui  x2, 0x80000
    addi x2, x2, -1         # INT32_MAX = 0x7FFFFFFF
    slt  x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # INT32_MAX < INT32_MIN  -> 0
    slt  x3, x2, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # -1 < INT32_MAX  -> 1
    addi x1, x0, -1
    slt  x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # INT32_MAX < -1  -> 0
    slt  x3, x2, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # --------------------------------------------------------
    # Phase 2: SLTU basics — unsigned comparison
    # Same bit patterns, different meaning
    # --------------------------------------------------------
    # 1 < 2 unsigned -> 1
    addi x1, x0, 1
    addi x2, x0, 2
    sltu x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # 2 < 1 unsigned -> 0
    sltu x3, x2, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # equal: 5 < 5 -> 0
    addi x1, x0, 5
    sltu x3, x1, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # 0xFFFFFFFF(-1 signed) > 0 unsigned -> sltu(0, -1)=1
    addi x1, x0, 0
    addi x2, x0, -1         # 0xFFFFFFFF unsigned = largest
    sltu x3, x1, x2         # 0 < 0xFFFFFFFF unsigned -> 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # 0xFFFFFFFF < 0 unsigned -> 0
    sltu x3, x2, x1         # x3 = 0
    add  x4, x3, x3         # 0

    # INT32_MIN (0x80000000) is LARGE unsigned
    # 0 < INT32_MIN unsigned -> 1
    addi x1, x0, 0
    lui  x2, 0x80000        # 0x80000000
    sltu x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # INT32_MIN unsigned > INT32_MAX unsigned -> sltu(INT32_MAX, INT32_MIN)=1
    lui  x1, 0x80000
    addi x2, x1, -1         # INT32_MAX = 0x7FFFFFFF
    sltu x3, x2, x1         # 0x7FFFFFFF < 0x80000000 unsigned -> 1
    addi x4, x0, 1
    sub  x5, x3, x4         # 0

    # INT32_MIN < INT32_MAX unsigned -> 0
    sltu x3, x1, x2         # 0
    add  x4, x3, x3         # 0

    # --------------------------------------------------------
    # Phase 3: SLT vs SLTU contrast — same operands, opposite results
    # -1 (0xFFFFFFFF) vs 0:
    #   SLT:  -1 < 0  = 1  (signed)
    #   SLTU:  0 < -1 would be 1, but we want sltu(-1, 0):
    #          0xFFFFFFFF < 0 unsigned = 0
    # --------------------------------------------------------
    addi x1, x0, -1         # 0xFFFFFFFF
    addi x2, x0,  0

    slt  x3, x1, x2         # signed:   -1 < 0  -> 1
    sltu x4, x1, x2         # unsigned: 0xFFFFFFFF < 0 -> 0
    # x3=1, x4=0 -> x3 XOR x4 = 1
    xor  x5, x3, x4
    addi x6, x0, 1
    sub  x7, x5, x6         # 0

    # INT32_MIN vs 1:
    #   SLT:  INT32_MIN < 1  -> 1  (negative < positive)
    #   SLTU: INT32_MIN > 1 unsigned -> 0
    lui  x1, 0x80000        # INT32_MIN
    addi x2, x0, 1

    slt  x3, x1, x2         # 1
    sltu x4, x1, x2         # 0
    xor  x5, x3, x4         # 1
    sub  x7, x5, x6         # 0  (x6 still = 1)

    # --------------------------------------------------------
    # Phase 4: SLTI — signed immediate compare
    # --------------------------------------------------------
    addi x1, x0, 0
    slti x2, x1, 1          # 0 < 1  -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    slti x2, x1, 0          # 0 < 0  -> 0 (equal)
    add  x3, x2, x2         # 0

    slti x2, x1, -1         # 0 < -1 -> 0 (signed: 0 > -1)
    add  x3, x2, x2         # 0

    addi x1, x0, -1
    slti x2, x1, 0          # -1 < 0 -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    slti x2, x1, -1         # -1 < -1 -> 0 (equal)
    add  x3, x2, x2         # 0

    slti x2, x1, 1          # -1 < 1  -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    # max positive imm: 2047
    addi x1, x0, 2047
    slti x2, x1, 2047       # equal -> 0
    add  x3, x2, x2         # 0

    addi x1, x0, 2046
    slti x2, x1, 2047       # 2046 < 2047 -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    # min negative imm: -2048
    addi x1, x0, -2048
    slti x2, x1, -2048      # equal -> 0
    add  x3, x2, x2         # 0

    slti x2, x1, -2047      # -2048 < -2047 -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    addi x1, x0, -2047
    slti x2, x1, -2048      # -2047 < -2048 -> 0
    add  x3, x2, x2         # 0

    # --------------------------------------------------------
    # Phase 5: SLTIU — unsigned immediate compare
    # NOTE: the 12-bit immediate is sign-extended THEN treated
    # as unsigned. So sltiu x, x, -1 compares against 0xFFFFFFFF.
    # --------------------------------------------------------
    addi x1, x0, 0
    sltiu x2, x1, 1         # 0 < 1 unsigned -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    sltiu x2, x1, 0         # 0 < 0 -> 0 (equal)
    add  x3, x2, x2         # 0

    # SLTIU with imm=-1: sign-extended to 0xFFFFFFFF
    # any value < 0xFFFFFFFF unsigned -> 1, except 0xFFFFFFFF itself
    addi x1, x0, 0
    sltiu x2, x1, -1        # 0 < 0xFFFFFFFF unsigned -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    addi x1, x0, -1         # x1 = 0xFFFFFFFF
    sltiu x2, x1, -1        # 0xFFFFFFFF < 0xFFFFFFFF -> 0 (equal)
    add  x3, x2, x2         # 0

    # SLTIU imm=-1 acts as "not equal to zero" / "nonzero test" for x!=0xFFFFFFFF
    addi x1, x0, 1
    sltiu x2, x1, -1        # 1 < 0xFFFFFFFF -> 1
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    # SLTIU imm=1: only 0 is less than 1 unsigned -> "x == 0" test
    addi x1, x0, 0
    sltiu x2, x1, 1         # 0 < 1 -> 1  (x1 is zero)
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    addi x1, x0, 1
    sltiu x2, x1, 1         # 1 < 1 -> 0  (not zero)
    add  x3, x2, x2         # 0

    addi x1, x0, -1         # 0xFFFFFFFF
    sltiu x2, x1, 1         # 0xFFFFFFFF < 1 unsigned -> 0
    add  x3, x2, x2         # 0

    # --------------------------------------------------------
    # Phase 6: SLTI vs SLTIU contrast — sign-extended immediate
    # imm = -1: SLTI sees -1, SLTIU sees 0xFFFFFFFF
    #   x1 = 0:
    #     SLTI  x, 0, -1  = 0  (0 is not < -1 signed)
    #     SLTIU x, 0, -1  = 1  (0 < 0xFFFFFFFF unsigned)
    # --------------------------------------------------------
    addi x1, x0, 0
    slti  x2, x1, -1        # 0
    sltiu x3, x1, -1        # 1
    xor   x4, x2, x3        # 1
    addi  x5, x0, 1
    sub   x6, x4, x5        # 0

    #   x1 = -1 (0xFFFFFFFF):
    #     SLTI  x, -1, -1 = 0  (equal)
    #     SLTIU x, -1, -1 = 0  (equal)
    addi x1, x0, -1
    slti  x2, x1, -1        # 0
    sltiu x3, x1, -1        # 0
    or    x4, x2, x3        # 0
    add   x5, x4, x4        # 0

    # --------------------------------------------------------
    # Phase 7: RAW hazards — SLT result consumed next cycle
    # --------------------------------------------------------
    addi x1, x0, 3
    addi x2, x0, 5
    slt  x3, x1, x2         # x3 = 1   (3 < 5)
    add  x4, x3, x3         # x4 = 2   RAW on x3
    slt  x5, x3, x4         # x5 = 1   RAW on both (1 < 2)
    addi x6, x0, 1
    sub  x7, x5, x6         # 0

    sltu x3, x1, x2         # x3 = 1
    addi x4, x3, 0          # x4 = 1   RAW (addi immediate chain)
    sltu x5, x4, x2         # x5 = 1   RAW on x4
    sub  x6, x5, x4         # 0

    addi x1, x0, 10
    slti  x2, x1, 20        # x2 = 1
    sltiu x3, x2, 2         # x3 = 1   (1 < 2)  RAW on x2
    add   x4, x2, x3        # x4 = 2   RAW on both
    slti  x5, x4, 3         # x5 = 1   (2 < 3)  RAW on x4
    addi  x6, x0, 1
    sub   x7, x5, x6        # 0

    # --------------------------------------------------------
    # Phase 8: SLT result is strictly 0 or 1 — never other values
    # Feed SLT output into ANDI 1: must be unchanged.
    # --------------------------------------------------------
    addi x1, x0, 7
    addi x2, x0, 3

    slt  x3, x1, x2         # 0
    andi x4, x3, 1          # still 0
    sub  x5, x4, x3         # 0

    slt  x3, x2, x1         # 1
    andi x4, x3, 1          # still 1
    sub  x5, x4, x3         # 0

    sltu x3, x1, x2         # 0
    andi x4, x3, 1
    sub  x5, x4, x3         # 0

    sltu x3, x2, x1         # 1
    andi x4, x3, 1
    sub  x5, x4, x3         # 0

    slti  x3, x1, 10        # 1  (7 < 10)
    andi  x4, x3, 1
    sub   x5, x4, x3        # 0

    sltiu x3, x1, 10        # 1
    andi  x4, x3, 1
    sub   x5, x4, x3        # 0

    # --------------------------------------------------------
    # Phase 9: SLT result stored and loaded back
    # --------------------------------------------------------
    addi x1, x0, 1
    addi x2, x0, 2
    slt  x3, x1, x2         # 1
    sw   x3, 0(x31)
    lw   x4, 0(x31)
    sub  x5, x4, x3         # 0

    slt  x3, x2, x1         # 0
    sw   x3, 4(x31)
    lw   x4, 4(x31)
    sub  x5, x4, x3         # 0

    sltu x3, x1, x2         # 1
    sw   x3, 8(x31)
    lw   x4, 8(x31)
    sub  x5, x4, x3         # 0

    # --------------------------------------------------------
    # Phase 10: SLT/SLTU used to build absolute value
    # abs(x) = x < 0 ? -x : x
    # For x = -5:
    #   slt t, x, zero  -> 1
    #   sub neg, zero, x -> +5
    #   if t==1 result = neg, else result = x
    #   implement with: result = x + t*(neg - x)
    #   since t is 0 or 1: result = x XOR (t * (x XOR neg)) -- complex
    #   simpler self-check: slt(x,0)=1 and slt(0,x)=0 for negative x
    # --------------------------------------------------------
    addi x1, x0, -5
    addi x2, x0,  0
    slt  x3, x1, x2         # -5 < 0  -> 1
    slt  x4, x2, x1         #  0 < -5 -> 0
    add  x5, x3, x4         # 1 (exactly one is true)
    addi x6, x0, 1
    sub  x7, x5, x6         # 0

    addi x1, x0, 5
    slt  x3, x1, x2         #  5 < 0  -> 0
    slt  x4, x2, x1         #  0 < 5  -> 1
    add  x5, x3, x4         # 1
    sub  x7, x5, x6         # 0

    addi x1, x0, 0
    slt  x3, x1, x2         #  0 < 0  -> 0
    slt  x4, x2, x1         #  0 < 0  -> 0
    add  x5, x3, x4         # 0 (neither: they are equal)
    add  x7, x5, x5         # 0

    # --------------------------------------------------------
    # Phase 11: Long mixed dependency chain
    # --------------------------------------------------------
    addi x1, x0, 10
    addi x2, x0, 20
    slt  x3, x1, x2         # 1
    add  x4, x1, x3         # 11
    slti x5, x4, 15         # 1  (11 < 15)
    add  x6, x4, x5         # 12
    sltu x7, x5, x6         # 1  (1 < 12)
    sub  x8, x6, x7         # 11
    sltiu x9, x8, 12        # 1  (11 < 12)
    add  x10, x8, x9        # 12
    slt  x11, x9, x10       # 1  (1 < 12)
    sub  x12, x10, x11      # 11
    addi x13, x0, 11
    sub  x14, x12, x13      # 0

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    
    wfi
