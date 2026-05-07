# ============================================================
# RISC-V Stress Test — ADD, SUB, ADDI, LUI
# ============================================================
# New coverage added with LUI:
#   - Upper-immediate decode and writeback
#   - LUI + ADDI two-instruction constant construction
#   - LUI result as ALU operand (forwarding from non-ALU path)
#   - Full 32-bit constant range stress
#   - Back-to-back LUI→ADD/SUB RAW hazards
#   - LUI writing x0 (discarded — should be silent)
# ============================================================

    # --------------------------------------------------------
    # Phase 1: Initialise registers (same as before)
    # --------------------------------------------------------
    addi x1,  x0, 1
    addi x2,  x0, 2
    addi x3,  x0, 3
    addi x4,  x0, 4
    addi x5,  x0, 5
    addi x6,  x0, 6
    addi x7,  x0, 7
    addi x8,  x0, 8
    addi x9,  x0, 9
    addi x10, x0, 10
    addi x11, x0, 11
    addi x12, x0, 12
    addi x13, x0, 13
    addi x14, x0, 14
    addi x15, x0, 15
    addi x16, x0, 16
    addi x17, x0, 17
    addi x18, x0, 18
    addi x19, x0, 19
    addi x20, x0, 20
    addi x21, x0, 21
    addi x22, x0, 22
    addi x23, x0, 23
    addi x24, x0, 24
    addi x25, x0, 25
    addi x26, x0, 26
    addi x27, x0, 27
    addi x28, x0, 28
    addi x29, x0, 29
    addi x30, x0, 30
    addi x31, x0, 31

    # --------------------------------------------------------
    # Phase 2: Back-to-back RAW hazard chain (addi only)
    # --------------------------------------------------------
    addi x1, x0,  1
    addi x1, x1,  1        # EX->EX forward
    addi x1, x1,  1
    addi x1, x1,  1
    addi x1, x1,  1
    add  x1, x1, x1
    sub  x1, x1, x2
    add  x1, x1, x1
    sub  x1, x1, x3
    add  x1, x1, x1

    # --------------------------------------------------------
    # Phase 3: Two-cycle RAW chain (MEM->EX forward path)
    # --------------------------------------------------------
    addi x2, x0, 7
    addi x3, x0, 3
    add  x4, x2, x3
    addi x5, x0, 5
    add  x6, x4, x5
    sub  x7, x6, x3
    add  x8, x7, x7
    sub  x9, x8, x6

    # --------------------------------------------------------
    # Phase 4: LUI basics -- decode and writeback
    # LUI places a 20-bit immediate in bits[31:12], zeroes [11:0]
    # --------------------------------------------------------
    lui  x1, 1              # x1 = 0x00001000
    lui  x2, 2              # x2 = 0x00002000
    lui  x3, 0xFFFFF        # x3 = 0xFFFFF000 (all upper bits set)
    lui  x4, 0x80000        # x4 = 0x80000000 (INT32_MIN directly)
    lui  x5, 0x7FFFF        # x5 = 0x7FFFF000
    addi x5, x5, 0x7FF      # x5 = 0x7FFFF7FF

    # --------------------------------------------------------
    # Phase 5: LUI + ADDI -- standard 32-bit constant construction
    # lui/addi pairs are the canonical way to build any 32-bit value.
    # The addi immediate is sign-extended, so compensate when bit11=1.
    # --------------------------------------------------------

    # Build 0x12345678
    lui  x6,  0x12345       # x6  = 0x12345000
    addi x6,  x6,  0x678   # x6  = 0x12345678

    # Build 0xDEADBEEF
    # addi imm = 0xEEF, bit11=1 -> sign-extends to -0x111 -> compensate upper
    lui  x7,  0xDEADC       # x7  = 0xDEADC000
    addi x7,  x7, -0x111   # x7  = 0xDEADBEEF

    # Build 0x00000FFF
    lui  x8,  1             # x8  = 0x00001000
    addi x8,  x8, -1       # x8  = 0x00000FFF

    # Build 0xFFFFFFFF (-1)
    addi x9,  x0, -1       # x9  = 0xFFFFFFFF

    # Build 0x80000001 (INT32_MIN + 1)
    lui  x10, 0x80000       # x10 = 0x80000000
    addi x10, x10, 1       # x10 = 0x80000001

    # --------------------------------------------------------
    # Phase 6: LUI->ALU RAW hazards
    # LUI result consumed immediately by the next instruction.
    # Tests forwarding from LUI writeback into EX operand mux.
    # --------------------------------------------------------
    lui  x11, 0x00001       # x11 = 0x00001000
    add  x12, x11, x11     # x12 = 0x00002000  (LUI->ADD 1-cycle RAW)
    lui  x13, 0x00002       # x13 = 0x00002000
    sub  x14, x13, x11     # x14 = 0x00001000  (LUI->SUB 1-cycle RAW)
    lui  x15, 0x00010       # x15 = 0x00010000
    add  x16, x15, x14     # x16 = 0x00011000  (2-cycle RAW from x14)
    lui  x17, 0xABCDE       # x17 = 0xABCDE000
    addi x17, x17, 0x123   # x17 = 0xABCDE123  (back-to-back LUI->ADDI)
    add  x18, x17, x16     # x18 = 0xABCEF123  (chain continues)

    # --------------------------------------------------------
    # Phase 7: Back-to-back LUI writes (register file write-port stress)
    # --------------------------------------------------------
    lui  x1,  0x11111
    lui  x2,  0x22222
    lui  x3,  0x33333
    lui  x4,  0x44444
    lui  x5,  0x55555
    lui  x6,  0x66666
    lui  x7,  0x77777
    lui  x8,  0x88888
    lui  x9,  0x99999
    lui  x10, 0xAAAAA
    lui  x11, 0xBBBBB
    lui  x12, 0xCCCCC
    lui  x13, 0xDDDDD
    lui  x14, 0xEEEEE
    lui  x15, 0xFFFFF       # x15 = 0xFFFFF000

    # Read them all back into an accumulator
    add  x16, x1,  x2
    add  x16, x16, x3
    add  x16, x16, x4
    add  x16, x16, x5
    add  x16, x16, x6
    add  x16, x16, x7
    add  x16, x16, x8
    add  x16, x16, x9
    add  x16, x16, x10
    add  x16, x16, x11
    add  x16, x16, x12
    add  x16, x16, x13
    add  x16, x16, x14
    add  x16, x16, x15

    # --------------------------------------------------------
    # Phase 8: Full 32-bit constant range sweep
    # Builds constants near key boundaries and operates on them.
    # --------------------------------------------------------

    # 0x00000000
    lui  x1, 0
    addi x1, x1, 0         # x1 = 0

    # 0x00000001
    addi x2, x0, 1         # x2 = 1

    # 0x00000800 (bit11 -- sign boundary for addi)
    lui  x3, 1
    addi x3, x3, -0x800    # x3 = 0x00001000 - 0x800 = 0x00000800

    # 0x7FFFFFFF (INT32_MAX)
    lui  x4, 0x80000        # x4 = 0x80000000
    addi x4, x4, -1        # x4 = 0x7FFFFFFF

    # 0x80000000 (INT32_MIN)
    lui  x5, 0x80000        # x5 = 0x80000000

    # 0xFFFFFFFF (-1)
    addi x6, x0, -1        # x6 = 0xFFFFFFFF

    # 0xFFFFF000 (upper bits set, lower zero)
    lui  x7, 0xFFFFF        # x7 = 0xFFFFF000

    # Arithmetic across boundaries
    add  x8,  x4, x2       # INT32_MAX + 1 = INT32_MIN (overflow)
    sub  x9,  x5, x2       # INT32_MIN - 1 = INT32_MAX (underflow)
    add  x10, x6, x2       # -1 + 1 = 0
    sub  x11, x1, x2       # 0 - 1 = -1
    add  x12, x7, x3       # 0xFFFFF000 + 0x800 = 0xFFFFF800
    sub  x13, x4, x5       # INT32_MAX - INT32_MIN = -1 (wraps)
    add  x14, x5, x5       # INT32_MIN + INT32_MIN = 0 (wraps)

    # --------------------------------------------------------
    # Phase 9: LUI x0 -- write to hardwired-zero register
    # Result must be discarded silently; x0 stays 0.
    # --------------------------------------------------------
    lui  x0, 0xFFFFF        # must NOT change x0
    add  x1, x0, x0         # x1 must be 0
    addi x2, x0, 42         # x2 must be 42, not 42+garbage
    sub  x3, x2, x0         # x3 must be 42

    # --------------------------------------------------------
    # Phase 10: Interleaved LUI and arithmetic -- mixed pipeline
    # --------------------------------------------------------
    lui  x1,  0x10000       # x1  = 0x10000000
    addi x2,  x0,  100     # x2  = 100
    add  x3,  x1,  x2      # x3  = 0x10000064
    lui  x4,  0x20000       # x4  = 0x20000000
    sub  x5,  x4,  x1      # x5  = 0x10000000
    addi x6,  x5, -1       # x6  = 0x0FFFFFFF
    lui  x7,  0x00001       # x7  = 0x00001000
    add  x8,  x6,  x7      # x8  = 0x10000FFF
    sub  x9,  x8,  x3      # x9  = 0x00000F9B
    lui  x10, 0xFFFFF       # x10 = 0xFFFFF000
    add  x11, x10, x9      # x11 = 0xFFFFF9BB (negative region)
    addi x12, x11, 1       # x12 = 0xFFFFF9BC
    sub  x13, x0,  x12     # x13 = -x12 (negate via sub from zero)
    lui  x14, 0x80000       # x14 = INT32_MIN
    add  x15, x14, x13     # INT32_MIN + positive
    sub  x16, x15, x10     # subtract large negative = add large positive

    # --------------------------------------------------------
    # Phase 11: Long serial chain seeded by LUI
    # --------------------------------------------------------
    lui  x1, 0x00001        # x1 = 4096
    add  x1, x1, x1        # 8192
    add  x1, x1, x1        # 16384
    add  x1, x1, x1        # 32768
    add  x1, x1, x1        # 65536
    add  x1, x1, x1        # 131072
    add  x1, x1, x1        # 262144
    add  x1, x1, x1        # 524288
    add  x1, x1, x1        # 1048576
    add  x1, x1, x1        # 2097152
    add  x1, x1, x1        # 4194304
    addi x1, x1, -1        # 4194303
    lui  x2, 0x00400        # x2 = 4194304
    sub  x3, x2, x1        # x3 = 1
    add  x4, x1, x3        # x4 = 4194304

    # --------------------------------------------------------
    # Phase 12: Register file port hammer with LUI-seeded values
    # --------------------------------------------------------
    lui  x1,  0x11111
    lui  x2,  0x22222
    add  x3,  x1,  x2
    sub  x4,  x3,  x1
    add  x5,  x4,  x2
    sub  x6,  x5,  x3
    add  x7,  x6,  x4
    sub  x8,  x7,  x5
    add  x9,  x8,  x6
    sub  x10, x9,  x7
    add  x11, x10, x8
    sub  x12, x11, x9
    add  x13, x12, x10
    sub  x14, x13, x11
    add  x15, x14, x12
    sub  x16, x15, x13
    add  x17, x16, x14
    sub  x18, x17, x15
    add  x19, x18, x16
    sub  x20, x19, x17
    add  x21, x20, x18
    sub  x22, x21, x19
    add  x23, x22, x20
    sub  x24, x23, x21
    add  x25, x24, x22
    sub  x26, x25, x23
    add  x27, x26, x24
    sub  x28, x27, x25
    add  x29, x28, x26
    sub  x30, x29, x27
    add  x31, x30, x28

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0

    wfi #stop
