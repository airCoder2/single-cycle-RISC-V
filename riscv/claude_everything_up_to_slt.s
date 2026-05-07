# ============================================================
# RISC-V Combined Stress Test
# ADD, SUB, ADDI, LUI, LW, SW, LB, LH, LBU, LHU,
# OR, ORI, AND, ANDI, XOR, XORI,
# SLT, SLTI, SLTU, SLTIU
# ============================================================
# Strategy: every phase chains multiple instruction classes
# together so that a bug in any one propagates into a visible
# wrong answer.  Every phase ends with a sub that should be 0.
# ============================================================

.data
scratch: .space 256

.text
.global _start

_start:
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)

    # --------------------------------------------------------
    # Phase 1: Build constants with LUI+ADDI, mask with AND,
    #          compare with SLT, accumulate with ADD
    # --------------------------------------------------------
    lui  x1, 0x12345        # 0x12345000
    addi x1, x1, 0x67F      # 0x1234567F
    addi x2, x0, 0x0FF
    and  x3, x1, x2         # lower byte = 0x7F = 127
    addi x4, x0, 127
    sub  x5, x3, x4         # 0

    slt  x6, x0, x3         # 0 < 127 -> 1
    sltu x7, x0, x3         # same    -> 1
    add  x8, x6, x7         # 2
    addi x9, x0, 2
    sub  x10, x8, x9        # 0

    # --------------------------------------------------------
    # Phase 2: Store computed values, reload, compare
    # --------------------------------------------------------
    lui  x1, 0xABCDE
    addi x1, x1, 0x123      # 0xABCDE123
    sw   x1, 0(x31)

    lw   x2, 0(x31)
    xor  x3, x1, x2         # 0 if load==store
    add  x4, x3, x3         # 0

    lbu  x5, 0(x31)         # byte0 = 0x23 = 35
    addi x6, x0, 35
    sub  x7, x5, x6         # 0

    lbu  x5, 1(x31)         # byte1 = 0xE1 = 225
    addi x6, x0, 225
    sub  x7, x5, x6         # 0

    lb   x5, 1(x31)         # byte1 signed = -31
    addi x6, x0, -31
    sub  x7, x5, x6         # 0

    lhu  x5, 0(x31)         # half0 = 0xE123 = 57635
    lui  x6, 0x0000E
    addi x6, x6, 0x123      # 0xE123 = 57635
    sub  x7, x5, x6         # 0

    lh   x5, 0(x31)         # half0 signed: 0xE123, bit15=1 -> negative
                             # 0xE123 = -7901
    lui  x6, 0xFFFFE
    addi x6, x6, 0x123      # 0xFFFFE123 = -7901
    sub  x7, x5, x6         # 0

    # --------------------------------------------------------
    # Phase 3: Bitwise ops on loaded bytes, feed into SLT
    # --------------------------------------------------------
    lbu  x1, 0(x31)         # 0x23 = 35
    lbu  x2, 1(x31)         # 0xE1 = 225
    or   x3, x1, x2         # 0xE3 = 227
    and  x4, x1, x2         # 0x21 = 33
    xor  x5, x1, x2         # 0xC2 = 194

    slt  x6, x4, x3         # 33 < 227 signed -> 1
    sltu x7, x4, x3         # 33 < 227 unsigned -> 1
    sub  x8, x6, x7         # 0

    slt  x6, x4, x5         # 33 < 194 -> 1
    addi x7, x0, 1
    sub  x8, x6, x7         # 0

    add  x9, x3, x4         # 260
    slti x10, x9, 261       # 260 < 261 -> 1
    sub  x11, x10, x7       # 0

    # --------------------------------------------------------
    # Phase 4: Signed vs unsigned comparison across sign boundary
    # --------------------------------------------------------
    # Build two values: one positive, one that looks negative
    addi x1, x0, 100        # small positive
    addi x2, x0, -1         # 0xFFFFFFFF

    slt  x3, x2, x1         # signed:   -1 < 100  -> 1
    sltu x4, x2, x1         # unsigned: huge < 100 -> 0
    xor  x5, x3, x4         # 1
    addi x6, x0, 1
    sub  x7, x5, x6         # 0

    # Store both, reload, recompare
    sw   x1, 4(x31)
    sw   x2, 8(x31)
    lw   x8, 4(x31)
    lw   x9, 8(x31)
    slt  x10, x9, x8        # -1 < 100 -> 1
    sub  x11, x10, x6       # 0

    sltu x10, x8, x9        # 100 < 0xFFFFFFFF -> 1
    sub  x11, x10, x6       # 0

    # --------------------------------------------------------
    # Phase 5: Chained load-use through ALU and logic
    # --------------------------------------------------------
    addi x1, x0, 0x055
    addi x2, x0, 0x0AA
    or   x3, x1, x2         # 0xFF
    sw   x3, 12(x31)

    lw   x4, 12(x31)        # load-use
    xori x5, x4, -1         # ~0xFF = 0xFFFFFF00
    andi x6, x5, 0x7FF      # 0x700
    addi x7, x0, 0x700
    sub  x8, x6, x7         # 0

    lbu  x4, 12(x31)        # 0xFF = 255
    slti  x5, x4, 256       # 255 < 256 -> 1
    sltiu x6, x4, 256       # 255 < 256 -> 1
    sub  x7, x5, x6         # 0

    lb   x4, 12(x31)        # 0xFF signed = -1
    slti x5, x4, 0          # -1 < 0 -> 1
    addi x6, x0, 1
    sub  x7, x5, x6         # 0

    # --------------------------------------------------------
    # Phase 6: LUI mask operations + SLT on wide values
    # --------------------------------------------------------
    lui  x1, 0x80000        # INT32_MIN = 0x80000000
    lui  x2, 0x7FFFF
    addi x2, x2, 0x7FF      # near INT32_MAX region

    slt  x3, x1, x2         # INT32_MIN < big positive -> 1
    sltu x4, x2, x1         # big positive < INT32_MIN unsigned -> 1
    add  x5, x3, x4         # 2
    addi x6, x0, 2
    sub  x7, x5, x6         # 0

    # upper-half mask
    lui  x8, 0xFFFF0        # 0xFFFF0000
    and  x9, x1, x8         # 0x80000000 & 0xFFFF0000 = 0x80000000
    sub  x10, x9, x1        # 0

    xor  x11, x1, x2        # INT32_MIN ^ near-INT32_MAX
    sltu x12, x0, x11       # nonzero? -> 1
    addi x13, x0, 1
    sub  x14, x12, x13      # 0

    # --------------------------------------------------------
    # Phase 7: Halfword lanes -> arithmetic -> store -> reload
    # --------------------------------------------------------
    lui  x1, 0x817FF
    addi x1, x1, -128       # 0x817FFF80
    sw   x1, 16(x31)

    lh   x2, 16(x31)        # 0xFF80 sign-extended = -128
    lhu  x3, 16(x31)        # 0xFF80 zero-extended = 65408
    add  x4, x2, x3         # -128 + 65408 = 65280
    lui  x5, 0x00010
    addi x5, x5, -256       # 65280
    sub  x6, x4, x5         # 0

    lh   x2, 18(x31)        # 0x817F sign-extended = -32385
    lhu  x3, 18(x31)        # 0x817F zero-extended = 33151
    sub  x4, x3, x2         # 33151 - (-32385) = 65536
    lui  x5, 0x00010        # 65536
    sub  x6, x4, x5         # 0

    slt  x7, x2, x0         # -32385 < 0 -> 1
    sltu x8, x3, x0         # 33151 < 0 unsigned -> 0
    xor  x9, x7, x8         # 1
    addi x10, x0, 1
    sub  x11, x9, x10       # 0

    # --------------------------------------------------------
    # Phase 8: XOR swap + SLT before and after
    # --------------------------------------------------------
    addi x1, x0, 300
    addi x2, x0, 700
    slt  x3, x1, x2         # 300 < 700 -> 1 (before swap)

    xor  x1, x1, x2
    xor  x2, x2, x1
    xor  x1, x1, x2         # now x1=700, x2=300

    slt  x4, x1, x2         # 700 < 300 -> 0 (after swap)
    add  x5, x3, x4         # 1
    addi x6, x0, 1
    sub  x7, x5, x6         # 0

    # verify swap correctness
    addi x8, x0, 700
    sub  x9, x1, x8         # 0
    addi x8, x0, 300
    sub  x9, x2, x8         # 0

    # --------------------------------------------------------
    # Phase 9: ALL four SLT variants in one chain
    # --------------------------------------------------------
    addi x1, x0, 42
    addi x2, x0, 100

    slt   x3, x1, x2        # 42 < 100 signed   -> 1
    sltu  x4, x1, x2        # 42 < 100 unsigned  -> 1
    slti  x5, x1, 100       # 42 < 100 imm       -> 1
    sltiu x6, x1, 100       # 42 < 100 uimm      -> 1

    add  x7, x3, x4
    add  x7, x7, x5
    add  x7, x7, x6         # x7 = 4
    addi x8, x0, 4
    sub  x9, x7, x8         # 0

    # same for false cases
    slt   x3, x2, x1        # 0
    sltu  x4, x2, x1        # 0
    slti  x5, x2, 42        # 0
    sltiu x6, x2, 42        # 0
    or    x7, x3, x4
    or    x7, x7, x5
    or    x7, x7, x6        # 0
    add   x8, x7, x7        # 0

    # --------------------------------------------------------
    # Phase 10: Memory checksum using every load width
    # Store 4 bytes with known values, reload as b/bu/h/hu/w,
    # combine with XOR and check against expected.
    # byte0=0x01 byte1=0x02 byte2=0x7F byte3=0x80
    # word = 0x807F0201
    # --------------------------------------------------------
    lui  x1, 0x807F0
    addi x1, x1, 0x201      # 0x807F0201
    sw   x1, 20(x31)

    lbu  x2, 20(x31)        # 0x01 = 1
    lbu  x3, 21(x31)        # 0x02 = 2
    lbu  x4, 22(x31)        # 0x7F = 127
    lbu  x5, 23(x31)        # 0x80 = 128
    add  x6, x2, x3
    add  x6, x6, x4
    add  x6, x6, x5         # 1+2+127+128 = 258
    addi x7, x0, 258
    sub  x8, x6, x7         # 0

    lb   x2, 20(x31)        # +1
    lb   x3, 21(x31)        # +2
    lb   x4, 22(x31)        # +127
    lb   x5, 23(x31)        # -128
    add  x6, x2, x3
    add  x6, x6, x4
    add  x6, x6, x5         # 1+2+127-128 = 2
    addi x7, x0, 2
    sub  x8, x6, x7         # 0

    lhu  x2, 20(x31)        # 0x0201 = 513
    lhu  x3, 22(x31)        # 0x807F = 32895
    add  x4, x2, x3         # 33408
    addi x5, x0, 513
    lui  x6, 0x00008
    addi x6, x6, 127        # 32895
    add  x7, x5, x6         # 33408
    sub  x8, x4, x7         # 0

    lh   x2, 20(x31)        # 0x0201 = 513 (positive)
    lh   x3, 22(x31)        # 0x807F signed = -32641
    add  x4, x2, x3         # 513 + (-32641) = -32128
    # build -32128: lui 0xFFFF8, addi 256 -> 0xFFFF8100
    # -32128 = 0xFFFF8100
    lui  x5, 0xFFFF8
    addi x5, x5, 256        # 0xFFFF8100 = -32128
    sub  x6, x4, x5         # 0

    # --------------------------------------------------------
    # Phase 11: SLTIU as zero-test, drive control-flow-free branch
    # --------------------------------------------------------
    # Compute: if (x == 0) result=99 else result=42
    # Using: sltiu t, x, 1  (t=1 iff x==0)
    # result = 42 + t*57  (since 99-42=57)
    # t*57 = t * 57; since t is 0 or 1, use: sub then and? 
    # Simpler: result = 42 + (57 AND (0 - t))  [0-1=0xFFFFFFFF mask]
    addi x1, x0, 0          # x == 0 case
    sltiu x2, x1, 1         # x2 = 1
    sub  x3, x0, x2         # x3 = -1 = 0xFFFFFFFF (mask)
    addi x4, x0, 57
    and  x5, x3, x4         # x5 = 57
    addi x6, x0, 42
    add  x7, x6, x5         # x7 = 99
    addi x8, x0, 99
    sub  x9, x7, x8         # 0

    addi x1, x0, 5          # x != 0 case
    sltiu x2, x1, 1         # x2 = 0
    sub  x3, x0, x2         # x3 = 0 (mask)
    and  x5, x3, x4         # x5 = 0
    add  x7, x6, x5         # x7 = 42
    addi x8, x0, 42
    sub  x9, x7, x8         # 0

    # --------------------------------------------------------
    # Phase 12: Long mixed RAW chain — every instruction class
    # --------------------------------------------------------
    lui  x1, 0x00001        # 4096
    addi x2, x0, 255
    or   x3, x1, x2         # 4351
    and  x4, x3, x2         # 255
    xor  x5, x3, x4         # 4096
    slt  x6, x4, x3         # 255 < 4351 -> 1
    add  x7, x5, x6         # 4097
    sw   x7, 24(x31)
    lw   x8, 24(x31)        # load-use
    sub  x9, x8, x7         # 0
    addi x10, x8, 1         # x10 = 4098 (used as comparand)
    slt  x10, x8, x10       # 4097 < 4098 -> 1  (avoids out-of-range imm)
    add  x11, x8, x10       # 4098
    andi x12, x11, 0x7FF    # 4098 & 2047 = 2 (4098 = 0x1002, &0x7FF=0x002)
    addi x13, x0, 2
    sub  x14, x12, x13      # 0
    sltu x15, x13, x11      # 2 < 4098 -> 1
    xori x16, x15, 0        # 1
    sub  x17, x16, x15      # 0
    ori  x18, x12, 0x010    # 2 | 16 = 18
    addi x19, x0, 18
    sub  x20, x18, x19      # 0
    lbu  x21, 24(x31)       # low byte of 4097 = 0x01 = 1
    addi x22, x0, 1
    sub  x23, x21, x22      # 0
    sltiu x24, x21, 2       # 1 < 2 -> 1
    sub  x25, x24, x22      # 0

    # --------------------------------------------------------
    # Phase 13: Stress register file — write every reg, read back
    # --------------------------------------------------------
    # Write using mix of instructions
    addi x1,  x0, 1
    lui  x2,  0x00002
    add  x3,  x1, x2
    ori  x4,  x0, 4
    andi x5,  x3, 0x7FF
    xori x6,  x1, 5
    slt  x7,  x1, x2
    sltu x8,  x1, x2
    slti x9,  x1, 10
    sltiu x10, x1, 10
    or   x11, x1, x2
    and  x12, x2, x3
    xor  x13, x1, x4
    sub  x14, x3, x1
    add  x15, x14, x1
    lui  x16, 0x00010
    addi x17, x16, -1
    or   x18, x16, x17
    and  x19, x16, x17
    xor  x20, x16, x17
    slt  x21, x17, x16
    sltu x22, x17, x16
    add  x23, x19, x20
    sub  x24, x18, x23
    ori  x25, x0, 25
    andi x26, x25, 0x1F
    xori x27, x26, 2
    sltiu x28, x27, 100
    add  x29, x27, x28
    slti x30, x29, 100

    # spot-check a few
    addi x1, x0, 1
    sub  x2, x7, x1         # x7 should be 1 (slt result)
    add  x3, x2, x2         # 0

    addi x1, x0, 25
    sub  x2, x25, x1        # x25 should be 25
    add  x3, x2, x2         # 0

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0

    wfi
