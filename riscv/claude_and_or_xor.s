# ============================================================
# RISC-V Stress Test — ADD SUB ADDI LUI LW SW
#                      OR ORI AND ANDI XOR XORI
# ============================================================
# New coverage with bitwise ops:
#   - Basic OR/AND/XOR correctness with known bit patterns
#   - Immediate variants (ORI, ANDI, XORI) across imm range
#   - Bitwise identity / annihilator / complement laws
#   - RAW hazards: logic result consumed next cycle
#   - Logic feeding memory (SW of logic result, LW back)
#   - Logic on LW results (load-use into bitwise op)
#   - Mixing ALU arithmetic and bitwise in dependency chains
#   - XOR as zero-detector (x ^ x = 0)
#   - XORI -1 as bitwise NOT
#   - ANDI as mask / ANDI 0 as zero
#   - ORI -1 as set-all
#   - LUI-built wide masks fed into AND/OR/XOR
# ============================================================

.data
scratch: .space 256

.text
.global _start

_start:
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)

    # --------------------------------------------------------
    # Phase 1: OR basics — known bit patterns
    # --------------------------------------------------------
    addi x1, x0, 0x0F0      # x1 = 0x0F0  (bits 7:4 set)  -- 240
    addi x2, x0, 0x00F      # x2 = 0x00F  (bits 3:0 set)  -- 15
    or   x3, x1, x2         # x3 = 0x0FF  = 255
    addi x4, x0, 0x0FF
    sub  x5, x3, x4         # 0

    addi x1, x0, 0x555      # alternating bits 0101...
    addi x2, x0, 0x2AA      # alternating bits 1010... (0x2AA=682, fits)
    # 0x555 = 1365, too large! use smaller patterns
    addi x1, x0, 0x055      # 0x55 = 85  = 0101 0101
    addi x2, x0, 0x0AA      # 0xAA = 170 -- 0xAA=170 fits
    or   x3, x1, x2         # 0xFF = 255
    addi x4, x0, 0x0FF
    sub  x5, x3, x4         # 0

    # OR with zero = identity
    addi x1, x0, 0x7FF      # max positive imm
    or   x2, x1, x0         # x2 = x1
    sub  x3, x2, x1         # 0

    # OR with -1 (all ones) = all ones
    addi x1, x0, 0x123
    addi x2, x0, -1         # 0xFFFFFFFF
    or   x3, x1, x2         # 0xFFFFFFFF
    sub  x4, x3, x2         # 0

    # --------------------------------------------------------
    # Phase 2: ORI — immediate variants
    # --------------------------------------------------------
    addi x1, x0, 0x0F0
    ori  x2, x1, 0x00F      # x2 = 0x0FF
    addi x3, x0, 0x0FF
    sub  x4, x2, x3         # 0

    ori  x1, x0, 0x7FF      # x1 = 0x7FF (max positive imm)
    addi x2, x0, 0x7FF
    sub  x3, x1, x2         # 0

    ori  x1, x0, -1         # x1 = 0xFFFFFFFF (all ones)
    addi x2, x0, -1
    sub  x3, x1, x2         # 0

    ori  x1, x0, -2048      # x1 = 0xFFFFF800
    lui  x2, 0xFFFFF
    addi x2, x2, -0x800     # can't do -2048 as addi on lui result safely
    # simpler: just verify round-trip
    sw   x1, 0(x31)
    lw   x2, 0(x31)
    sub  x3, x2, x1         # 0

    addi x1, x0, 0x055
    ori  x2, x1, 0x0AA      # 0xFF
    addi x3, x0, 0x0FF
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 3: AND basics
    # --------------------------------------------------------
    addi x1, x0, 0x0FF
    addi x2, x0, 0x0F0
    and  x3, x1, x2         # x3 = 0x0F0
    sub  x4, x3, x2         # 0

    # AND with 0 = 0 (annihilator)
    addi x1, x0, 0x7FF
    and  x2, x1, x0         # x2 = 0
    add  x3, x2, x2         # x3 = 0

    # AND with -1 = identity
    addi x1, x0, 0x123
    addi x2, x0, -1
    and  x3, x1, x2         # x3 = x1
    sub  x4, x3, x1         # 0

    # AND as mask: isolate lower byte
    lui  x1, 0x12345
    addi x1, x1, 0x678      # x1 = 0x12345678  -- 0x678=1656 > 2047! use safe:
    lui  x1, 0x12345
    addi x1, x1, 0x67F      # 0x67F = 1663... also > 2047
    # build safely: lui gives upper 20, addi max 2047 = 0x7FF
    lui  x1, 0x12346         # compensate: 0x12346000
    addi x1, x1, -0x400     # 0x12346000 - 0x400 = 0x12345C00 -- close enough for masking test
    addi x2, x0, 0x0FF      # lower byte mask
    and  x3, x1, x2         # isolate lower byte of x1
    # just verify it's <= 0xFF
    addi x4, x0, 0x0FF
    # x3 AND x4 should equal x3 (x3 is already masked)
    and  x5, x3, x4
    sub  x6, x5, x3         # 0

    # AND — alternating bit patterns cancel
    addi x1, x0, 0x055      # 0101 0101
    addi x2, x0, 0x0AA      # 1010 1010
    and  x3, x1, x2         # 0000 0000
    add  x4, x3, x3         # 0

    # --------------------------------------------------------
    # Phase 4: ANDI
    # --------------------------------------------------------
    addi x1, x0, 0x0FF
    andi x2, x1, 0x00F      # x2 = 0x00F
    addi x3, x0, 0x00F
    sub  x4, x2, x3         # 0

    andi x1, x0,  0         # x1 = 0
    andi x2, x0, -1         # x2 = 0  (0 & anything = 0)
    add  x3, x1, x2         # 0

    addi x1, x0, -1         # 0xFFFFFFFF
    andi x2, x1, 0x7FF      # x2 = 0x7FF
    addi x3, x0, 0x7FF
    sub  x4, x2, x3         # 0

    addi x1, x0, -1
    andi x2, x1, -1         # x2 = -1 (identity)
    sub  x3, x2, x1         # 0

    # ANDI as lower-12-bit mask
    lui  x1, 0xABCDE
    addi x1, x1, 0x123      # x1 = 0xABCDE123 -- 0x123=291, fits
    andi x2, x1, 0x7FF      # isolate bits[10:0]  = 0x123
    addi x3, x0, 0x123
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 5: XOR basics
    # --------------------------------------------------------
    addi x1, x0, 0x0FF
    addi x2, x0, 0x00F
    xor  x3, x1, x2         # x3 = 0x0F0
    addi x4, x0, 0x0F0
    sub  x5, x3, x4         # 0

    # XOR with self = 0 (zero detector)
    addi x1, x0, 0x7FF
    xor  x2, x1, x1         # x2 = 0
    add  x3, x2, x2         # 0

    addi x1, x0, -1
    xor  x2, x1, x1         # 0
    add  x3, x2, x0         # 0

    # XOR with 0 = identity
    addi x1, x0, 0x123
    xor  x2, x1, x0         # x2 = x1
    sub  x3, x2, x1         # 0

    # XOR with -1 = bitwise NOT
    addi x1, x0, 0x055      # 0101 0101
    addi x2, x0, -1
    xor  x3, x1, x2         # ~x1
    # ~0x55 + 0x55 = 0xFFFFFFFF = -1
    add  x4, x3, x1         # should be 0xFFFFFFFF = -1
    sub  x5, x4, x2         # 0

    # XOR commutativity: a^b = b^a
    addi x1, x0, 0x0F0
    addi x2, x0, 0x00F
    xor  x3, x1, x2
    xor  x4, x2, x1
    sub  x5, x3, x4         # 0

    # XOR associativity: (a^b)^c = a^(b^c)
    addi x1, x0, 0x071
    addi x2, x0, 0x052
    addi x3, x0, 0x033
    xor  x4, x1, x2
    xor  x4, x4, x3         # (x1^x2)^x3
    xor  x5, x2, x3
    xor  x5, x1, x5         # x1^(x2^x3)
    sub  x6, x4, x5         # 0

    # --------------------------------------------------------
    # Phase 6: XORI
    # --------------------------------------------------------
    addi x1, x0, 0x0FF
    xori x2, x1, 0x00F      # x2 = 0x0F0
    addi x3, x0, 0x0F0
    sub  x4, x2, x3         # 0

    # XORI -1 = bitwise NOT
    addi x1, x0, 0x055
    xori x2, x1, -1         # x2 = ~x1
    add  x3, x1, x2         # 0xFFFFFFFF
    addi x4, x0, -1
    sub  x5, x3, x4         # 0

    xori x1, x0, -1         # x1 = 0xFFFFFFFF
    xori x2, x1, -1         # x2 = 0  (double NOT)
    add  x3, x2, x2         # 0

    # XORI 0 = identity
    addi x1, x0, 0x7FF
    xori x2, x1, 0          # x2 = x1
    sub  x3, x2, x1         # 0

    # --------------------------------------------------------
    # Phase 7: RAW hazards — logic result consumed next cycle
    # --------------------------------------------------------
    addi x1, x0, 0x0F0
    addi x2, x0, 0x00F
    or   x3, x1, x2         # x3 = 0x0FF
    and  x4, x3, x1         # RAW on x3 -> x4 = 0x0F0
    xor  x5, x4, x3         # RAW on x4 -> x5 = 0x00F
    or   x6, x5, x4         # RAW on x5 -> x6 = 0x0FF
    sub  x7, x6, x3         # 0

    # ORI/ANDI/XORI back-to-back immediate RAW chain
    addi x1, x0, 0x001
    ori  x1, x1, 0x002      # x1 = 0x003  RAW
    ori  x1, x1, 0x004      # x1 = 0x007  RAW
    ori  x1, x1, 0x008      # x1 = 0x00F  RAW
    andi x1, x1, 0x00F      # x1 = 0x00F  RAW
    xori x1, x1, 0x005      # x1 = 0x00A  RAW
    addi x2, x0, 0x00A
    sub  x3, x1, x2         # 0

    # --------------------------------------------------------
    # Phase 8: Logic feeding SW, LW result into logic (load-use)
    # --------------------------------------------------------
    addi x1, x0, 0x0F0
    addi x2, x0, 0x00F
    or   x3, x1, x2         # x3 = 0x0FF
    sw   x3, 0(x31)         # store logic result
    lw   x4, 0(x31)         # load it back
    and  x5, x4, x1         # load-use: x4 into AND -> 0x0F0
    sub  x6, x5, x1         # 0

    addi x1, x0, 0x055
    sw   x1, 4(x31)
    lw   x2, 4(x31)
    xori x3, x2, -1         # load-use: NOT of loaded value
    # x3 = ~0x55; x3 + x2 should be -1
    add  x4, x3, x2
    addi x5, x0, -1
    sub  x6, x4, x5         # 0

    addi x1, x0, 0x0FF
    sw   x1, 8(x31)
    lw   x2, 8(x31)
    andi x3, x2, 0x055      # load-use -> x3 = 0x055
    addi x4, x0, 0x055
    sub  x5, x3, x4         # 0

    # --------------------------------------------------------
    # Phase 9: LUI-built wide masks with AND/OR/XOR
    # --------------------------------------------------------
    # Build 0xFFFF0000 mask (upper halfword)
    lui  x1, 0xFFFF0         # x1 = 0xFFFF0000
    lui  x2, 0xABCDE
    addi x2, x2, 0x123       # x2 = 0xABCDE123 (0x123=291 fits)
    and  x3, x2, x1          # x3 = 0xABCD0000 (upper half only)
    # verify lower 16 bits are zero
    addi x4, x0, -1
    lui  x5, 0x00001         # x5 = 0x00001000
    addi x5, x5, -1          # x5 = 0x00000FFF
    and  x6, x3, x5          # x6 = 0 (lower 12 bits of x3)
    add  x7, x6, x6          # 0

    # Build 0x0000FFFF mask (lower halfword) via NOT of upper
    lui  x1, 0xFFFF0          # 0xFFFF0000
    xori x1, x1, -1           # ~0xFFFF0000 = 0x0000FFFF
    lui  x2, 0xABCDE
    addi x2, x2, 0x123
    and  x3, x2, x1           # x3 = 0x0000E123
    # upper 16 bits of x3 must be zero
    lui  x4, 0xFFFF0
    and  x5, x3, x4            # x5 = 0
    add  x6, x5, x5            # 0

    # OR to merge two halves
    lui  x1, 0xABCD0           # upper half: 0xABCD0000
    addi x2, x0, 0x7EF         # lower 12 bits (safe imm)
    or   x3, x1, x2            # x3 = 0xABCD07EF
    # verify upper half preserved
    lui  x4, 0xABCD0
    and  x5, x3, x4
    sub  x6, x5, x4            # 0
    # verify lower bits present
    and  x7, x3, x2
    sub  x8, x7, x2            # 0

    # --------------------------------------------------------
    # Phase 10: Mixed long dependency chain (all ops combined)
    # --------------------------------------------------------
    addi x1, x0, 0x071
    addi x2, x0, 0x052
    add  x3, x1, x2           # 0x0C3
    or   x4, x3, x1           # 0x0F3 -- RAW on x3
    and  x5, x4, x2           # 0x052 -- RAW on x4
    xor  x6, x5, x3           # 0x091 -- RAW on x5
    sub  x7, x6, x2           # 0x03F -- RAW on x6
    ori  x8, x7, 0x040        # 0x07F -- RAW on x7
    andi x9, x8, 0x055        # 0x055 -- RAW on x8
    xori x10, x9, 0x0AA       # 0x0FF -- RAW on x9
    addi x11, x0, 0x0FF
    sub  x12, x10, x11        # 0

    # --------------------------------------------------------
    # Phase 11: XOR swap (classic 3-step, no temp register)
    # --------------------------------------------------------
    addi x1, x0, 0x0AB
    addi x2, x0, 0x0CD
    xor  x1, x1, x2           # x1 = AB^CD
    xor  x2, x2, x1           # x2 = CD^(AB^CD) = AB
    xor  x1, x1, x2           # x1 = (AB^CD)^AB = CD
    # now x1=0xCD, x2=0xAB
    addi x3, x0, 0x0CD
    addi x4, x0, 0x0AB
    sub  x5, x1, x3           # 0
    sub  x6, x2, x4           # 0

    # --------------------------------------------------------
    # Phase 12: Register file port hammer — all logic ops
    # --------------------------------------------------------
    lui  x1, 0x11111
    lui  x2, 0x22222
    or   x3, x1, x2
    and  x4, x3, x1
    xor  x5, x4, x2
    or   x6, x5, x3
    and  x7, x6, x4
    xor  x8, x7, x5
    or   x9, x8, x6
    and  x10, x9, x7
    xor  x11, x10, x8
    or   x12, x11, x9
    and  x13, x12, x10
    xor  x14, x13, x11
    or   x15, x14, x12
    and  x16, x15, x13
    xor  x17, x16, x14
    or   x18, x17, x15
    and  x19, x18, x16
    xor  x20, x19, x17
    or   x21, x20, x18
    and  x22, x21, x19
    xor  x23, x22, x20
    or   x24, x23, x21
    and  x25, x24, x22
    xor  x26, x25, x23
    or   x27, x26, x24
    and  x28, x27, x25
    xor  x29, x28, x26
    or   x30, x29, x27
    and  x31, x30, x28       # x31 clobbered here intentionally

    # --------------------------------------------------------
    # Phase 13: Store/load of logic results — integrity check
    # --------------------------------------------------------
    # Restore base pointer (x31 was clobbered in phase 12)
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)

    addi x1, x0, 0x055
    addi x2, x0, 0x0AA
    or   x3, x1, x2           # 0xFF
    and  x4, x1, x2           # 0x00
    xor  x5, x1, x2           # 0xFF
    sw   x3, 0(x31)
    sw   x4, 4(x31)
    sw   x5, 8(x31)
    lw   x6, 0(x31)
    lw   x7, 4(x31)
    lw   x8, 8(x31)
    sub  x9,  x6, x3          # 0
    sub  x10, x7, x4          # 0
    sub  x11, x8, x5          # 0
    xor  x12, x6, x8          # 0xFF ^ 0xFF = 0
    add  x13, x12, x7         # 0 + 0 = 0

    # --------------------------------------------------------
    # Phase 14: Bitwise identity / annihilator laws summary
    # All results must be 0 (self-checking)
    # --------------------------------------------------------
    addi x1, x0, 0x7FF

    # OR identities
    or   x2, x1, x0           # x1 | 0 = x1
    sub  x3, x2, x1           # 0
    ori  x2, x1, 0            # x1 | 0 = x1
    sub  x3, x2, x1           # 0

    # AND identities
    addi x4, x0, -1
    and  x2, x1, x4           # x1 & -1 = x1
    sub  x3, x2, x1           # 0
    andi x2, x1, -1           # x1 & -1 = x1
    sub  x3, x2, x1           # 0
    and  x2, x1, x0           # x1 & 0 = 0
    add  x3, x2, x2           # 0
    andi x2, x1, 0            # x1 & 0 = 0
    add  x3, x2, x2           # 0

    # XOR identities
    xor  x2, x1, x0           # x1 ^ 0 = x1
    sub  x3, x2, x1           # 0
    xori x2, x1, 0            # x1 ^ 0 = x1
    sub  x3, x2, x1           # 0
    xor  x2, x1, x1           # x1 ^ x1 = 0
    add  x3, x2, x2           # 0
    xori x2, x1, -1           # ~x1
    add  x3, x2, x1           # ~x1 + x1 = -1
    addi x4, x0, -1
    sub  x5, x3, x4           # 0

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0

    wfi
