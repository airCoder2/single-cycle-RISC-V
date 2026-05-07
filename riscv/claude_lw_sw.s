# ============================================================
# RISC-V Stress Test — ADD, SUB, ADDI, LUI, LW, SW
# Tested with RARS simulator
# ============================================================

.data
scratch: .space 256

.text
.global _start

_start:
    # Set up base pointer in x31
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)

    # --------------------------------------------------------
    # Phase 1: Basic SW then LW roundtrip
    # --------------------------------------------------------
    addi x1, x0, 0x7F       # x1 = 127  (safe positive addi value)
    sw   x1,  0(x31)
    lw   x2,  0(x31)
    sub  x3, x2, x1          # x3 = 0

    addi x1, x0, -1          # x1 = 0xFFFFFFFF
    sw   x1,  4(x31)
    lw   x2,  4(x31)
    sub  x3, x2, x1          # x3 = 0

    lui  x1, 0x80000          # x1 = 0x80000000
    sw   x1,  8(x31)
    lw   x2,  8(x31)
    sub  x3, x2, x1          # x3 = 0

    # --------------------------------------------------------
    # Phase 2: Load-use hazard
    # LW result consumed by the very next instruction.
    # A pipeline without a load-use stall WILL produce wrong values.
    # --------------------------------------------------------
    addi x1, x0, 42
    sw   x1, 12(x31)
    lw   x2, 12(x31)
    add  x3, x2, x2          # x3 = 84  (load-use: x2 must be 42)
    addi x4, x2,  1          # x4 = 43  (another immediate load-use)
    sub  x5, x3, x4          # x5 = 41

    addi x1, x0, 100
    sw   x1, 16(x31)
    lw   x2, 16(x31)
    lw   x3, 12(x31)         # two back-to-back loads
    add  x4, x2, x3          # x4 = 142  (load-use on both)
    sub  x5, x4, x1          # x5 = 42

    # --------------------------------------------------------
    # Phase 3: Address generation — positive and negative offsets
    # --------------------------------------------------------
    addi x1, x0, 0x11
    addi x2, x0, 0x22
    addi x3, x0, 0x33
    addi x4, x0, 0x44

    sw   x1,  0(x31)
    sw   x2,  4(x31)
    sw   x3,  8(x31)
    sw   x4, 12(x31)

    addi x10, x31, 12        # x10 = base + 12
    lw   x5,   0(x10)        # offset  0  -> 0x44
    lw   x6,  -4(x10)        # offset -4  -> 0x33
    lw   x7,  -8(x10)        # offset -8  -> 0x22
    lw   x8, -12(x10)        # offset -12 -> 0x11

    sub  x9, x5, x4          # 0
    sub  x9, x6, x3          # 0
    sub  x9, x7, x2          # 0
    sub  x9, x8, x1          # 0

    # --------------------------------------------------------
    # Phase 4: SW with ALU-computed base address
    # --------------------------------------------------------
    addi x1, x0, 50
    addi x2, x0, 4
    add  x10, x31, x2        # x10 = base + 4
    sw   x1,  0(x10)         # mem[base+4]  = 50
    sw   x1, 16(x10)         # mem[base+20] = 50
    sub  x11, x10, x2        # x11 = base
    lw   x3,  4(x11)         # mem[base+4]  = 50
    lw   x4, 20(x11)         # mem[base+20] = 50
    sub  x5, x3, x1          # 0
    sub  x6, x4, x1          # 0

    # --------------------------------------------------------
    # Phase 5: LW result forwarded into ALU src1 AND src2
    # --------------------------------------------------------
    addi x1, x0, 7
    addi x2, x0, 3
    sw   x1, 24(x31)
    sw   x2, 28(x31)

    lw   x3, 24(x31)
    add  x4, x3, x3          # src1 and src2 both from load
    lw   x5, 24(x31)
    lw   x6, 28(x31)
    add  x7, x5, x6          # x7 = 10
    sub  x8, x5, x6          # x8 = 4
    add  x9, x7, x8          # x9 = 14

    # --------------------------------------------------------
    # Phase 6: Store ordering — last write wins
    # --------------------------------------------------------
    addi x1, x0, 0x0AA
    addi x2, x0, 0x0BB
    sw   x1, 32(x31)
    sw   x2, 32(x31)         # overwrite
    lw   x3, 32(x31)         # must see 0xBB
    sub  x4, x3, x2          # 0

    addi x1, x0, 1
    addi x2, x0, 2
    addi x3, x0, 3
    sw   x1, 36(x31)
    sw   x2, 36(x31)
    sw   x3, 36(x31)         # final = 3
    lw   x4, 36(x31)
    sub  x5, x4, x3          # 0

    # --------------------------------------------------------
    # Phase 7: Strided write then strided read — checksum = 136
    # --------------------------------------------------------
    addi x1, x0, 1
    sw   x1,  0(x31)
    addi x1, x0, 2
    sw   x1,  4(x31)
    addi x1, x0, 3
    sw   x1,  8(x31)
    addi x1, x0, 4
    sw   x1, 12(x31)
    addi x1, x0, 5
    sw   x1, 16(x31)
    addi x1, x0, 6
    sw   x1, 20(x31)
    addi x1, x0, 7
    sw   x1, 24(x31)
    addi x1, x0, 8
    sw   x1, 28(x31)
    addi x1, x0, 9
    sw   x1, 32(x31)
    addi x1, x0, 10
    sw   x1, 36(x31)
    addi x1, x0, 11
    sw   x1, 40(x31)
    addi x1, x0, 12
    sw   x1, 44(x31)
    addi x1, x0, 13
    sw   x1, 48(x31)
    addi x1, x0, 14
    sw   x1, 52(x31)
    addi x1, x0, 15
    sw   x1, 56(x31)
    addi x1, x0, 16
    sw   x1, 60(x31)

    addi x20, x0, 0
    lw   x1,  0(x31)
    add  x20, x20, x1
    lw   x1,  4(x31)
    add  x20, x20, x1
    lw   x1,  8(x31)
    add  x20, x20, x1
    lw   x1, 12(x31)
    add  x20, x20, x1
    lw   x1, 16(x31)
    add  x20, x20, x1
    lw   x1, 20(x31)
    add  x20, x20, x1
    lw   x1, 24(x31)
    add  x20, x20, x1
    lw   x1, 28(x31)
    add  x20, x20, x1
    lw   x1, 32(x31)
    add  x20, x20, x1
    lw   x1, 36(x31)
    add  x20, x20, x1
    lw   x1, 40(x31)
    add  x20, x20, x1
    lw   x1, 44(x31)
    add  x20, x20, x1
    lw   x1, 48(x31)
    add  x20, x20, x1
    lw   x1, 52(x31)
    add  x20, x20, x1
    lw   x1, 56(x31)
    add  x20, x20, x1
    lw   x1, 60(x31)
    add  x20, x20, x1        # x20 = 136

    addi x21, x0, 136
    sub  x22, x20, x21       # x22 = 0 if memory is correct

    # --------------------------------------------------------
    # Phase 8: ALU chain -> SW -> LW -> ALU chain
    # --------------------------------------------------------
    addi x1, x0, 1
    add  x1, x1, x1          # 2
    add  x1, x1, x1          # 4
    add  x1, x1, x1          # 8
    add  x1, x1, x1          # 16
    add  x1, x1, x1          # 32
    sw   x1, 64(x31)
    add  x1, x1, x1          # 64  (ALU continues while store drains)
    lw   x2, 64(x31)         # x2 = 32
    add  x3, x2, x2          # x3 = 64  (load-use on x2)
    sub  x4, x3, x1          # x4 = 0

    # --------------------------------------------------------
    # Phase 9: LW sign extension check
    # --------------------------------------------------------
    addi x1, x0, -1          # 0xFFFFFFFF
    sw   x1, 68(x31)
    lw   x2, 68(x31)
    sub  x3, x2, x1          # 0

    lui  x1, 0x80000          # 0x80000000
    sw   x1, 72(x31)
    lw   x2, 72(x31)
    sub  x3, x2, x1          # 0

    # --------------------------------------------------------
    # Phase 10: Pointer chasing (load address from memory, use as base)
    # --------------------------------------------------------
    addi x1, x31, 88         # x1 = base + 88
    sw   x1, 80(x31)         # mem[base+80] = base+88  (pointer)

    # Build value 0xBEF using lui+addi safely
    lui  x2, 1               # x2 = 0x1000
    addi x2, x2, -17         # x2 = 0xFF0... no, build 0xBEF differently:
    addi x2, x0, 0x7FF       # x2 = 2047
    addi x3, x0, -1808       # x3 = -1808; 2047-1808 = 239... use simpler value
    # Use a clean value instead: 0x5A5
    addi x2, x0, 0x5A5       # -- too large (>2047? 0x5A5=1445, fine)
    # 0x5A5 = 1445, within addi range
    sw   x2, 88(x31)         # mem[base+88] = 1445

    lw   x4, 80(x31)         # x4 = base+88  (load pointer)
    lw   x5,  0(x4)          # x5 = mem[base+88] = 1445
    sub  x6, x5, x2          # x6 = 0

    # --------------------------------------------------------
    # Phase 11: Mixed interleaved ALU and memory ops
    # --------------------------------------------------------
    lui  x1, 0x11111
    lui  x2, 0x22222
    add  x3, x1, x2
    sw   x3,  92(x31)
    sub  x4, x2, x1
    sw   x4,  96(x31)
    lw   x5,  92(x31)        # load-use
    add  x6, x5, x4
    lw   x7,  96(x31)
    sub  x8, x6, x7
    sw   x8, 100(x31)
    lw   x9, 100(x31)
    sub  x10, x9, x3         # x10 = 0
    add  x11, x9, x8
    sw   x11, 104(x31)
    lw   x12, 104(x31)
    sub  x13, x12, x11       # x13 = 0

    # --------------------------------------------------------
    # Phase 12: Offset extremes within 256-byte scratch
    # --------------------------------------------------------
    addi x1, x0, 0x5A
    sw   x1, 252(x31)        # highest word in scratch
    lw   x2, 252(x31)
    sub  x3, x2, x1          # 0

    addi x10, x31, 252
    sw   x1,    0(x10)       # same cell, different base+offset
    lw   x2,    0(x10)
    sub  x3, x2, x1          # 0

    sw   x1,   -4(x10)       # mem[base+248]
    lw   x2,   -4(x10)
    sub  x3, x2, x1          # 0

    # --------------------------------------------------------
    # Phase 13: SW x0 — store hardwired zero
    # --------------------------------------------------------
    addi x1, x0, 99
    sw   x1, 108(x31)        # poison with 99
    sw   x0, 108(x31)        # overwrite with 0
    lw   x2, 108(x31)        # x2 must be 0
    add  x3, x2, x2          # x3 = 0

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    
    wfi
