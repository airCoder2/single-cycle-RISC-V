# ============================================================
# RISC-V Stress Test — Everything + AUIPC
# ADD SUB ADDI LUI AUIPC LW SW LB LH LBU LHU
# OR ORI AND ANDI XOR XORI SLT SLTI SLTU SLTIU
# ============================================================
# AUIPC rd, imm  ->  rd = PC + (imm << 12)
#
# AUIPC-specific axes:
#   - Result encodes the current PC, so it changes with code position
#   - Two consecutive AUIPCs must differ by exactly 4 (one instruction)
#   - AUIPC imm=0 -> rd = PC exactly
#   - AUIPC result used as memory base (the canonical PIC address mode)
#   - AUIPC + ADDI = PC-relative address (la pseudo-instruction)
#   - AUIPC result fed into ALU, logic, SLT, SW/LW
#   - RAW hazard: AUIPC result consumed next cycle
# ============================================================

.data
scratch: .space 256

.text
.global _start

_start:
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)

    # --------------------------------------------------------
    # Phase 1: AUIPC imm=0 gives current PC
    # Two back-to-back AUIPC imm=0 must differ by exactly 4.
    # --------------------------------------------------------
auipc_pair:
    auipc x1, 0             # x1 = PC of this instruction
    auipc x2, 0             # x2 = PC + 4
    sub   x3, x2, x1        # x3 must be exactly 4
    addi  x4, x0, 4
    sub   x5, x3, x4        # 0

    # Three in a row: differences must all be 4
    auipc x6, 0
    auipc x7, 0
    auipc x8, 0
    sub   x9,  x7, x6       # 4
    sub   x10, x8, x7       # 4
    sub   x11, x9, x10      # 0

    # --------------------------------------------------------
    # Phase 2: AUIPC imm != 0
    # auipc rd, N  ->  rd = PC + N*4096
    # Two consecutive: (PC+N*4096) and (PC+4+N*4096) differ by 4.
    # --------------------------------------------------------
    auipc x1, 1             # x1 = PC + 0x1000
    auipc x2, 1             # x2 = PC + 4 + 0x1000
    sub   x3, x2, x1        # must be 4
    addi  x4, x0, 4
    sub   x5, x3, x4        # 0

    auipc x1, 0x7FFFF       # large immediate
    auipc x2, 0x7FFFF
    sub   x3, x2, x1        # still just 4
    sub   x5, x3, x4        # 0  (x4 still 4)

    # --------------------------------------------------------
    # Phase 3: AUIPC RAW hazard — result consumed next cycle
    # --------------------------------------------------------
    auipc x1, 0             # x1 = PC
    add   x2, x1, x1        # RAW: uses x1 immediately
    # x2 = 2*PC; at minimum nonzero (PC is never 0 in RARS .text)
    sltu  x3, x0, x2        # 0 < 2*PC -> 1
    addi  x4, x0, 1
    sub   x5, x3, x4        # 0

    auipc x1, 0
    addi  x2, x1, 4         # RAW: x2 = PC + 4 = address of next instruction
    auipc x3, 0             # x3 = PC of THIS instruction = original PC + 8
    sub   x4, x3, x1        # x4 = 8
    addi  x5, x0, 8
    sub   x6, x4, x5        # 0

    # --------------------------------------------------------
    # Phase 4: AUIPC encodes PC; verify against LUI-built address
    # SW and LW through the lui-built base to confirm memory works
    # alongside AUIPC in the same phase.
    # --------------------------------------------------------
    addi  x1, x0, 0x5A
    sw    x1,  0(x31)
    lw    x2,  0(x31)
    sub   x3, x2, x1        # 0

    # AUIPC imm=0 gives PC; LUI imm=0 gives 0; difference = PC
    auipc x10, 0            # x10 = PC
    lui   x11, 0            # x11 = 0
    sub   x12, x10, x11     # x12 = PC, must be nonzero
    sltu  x13, x0, x12      # 1
    addi  x14, x0, 1
    sub   x15, x13, x14     # 0

    # --------------------------------------------------------
    # Phase 5: AUIPC fed into logic ops
    # --------------------------------------------------------
    auipc x1, 0             # x1 = current PC
    addi  x2, x0, -1        # 0xFFFFFFFF
    and   x3, x1, x2        # x3 = x1 (identity)
    sub   x4, x3, x1        # 0

    or    x3, x1, x0        # x3 = x1 (identity)
    sub   x4, x3, x1        # 0

    xor   x3, x1, x1        # 0
    add   x4, x3, x3        # 0

    auipc x1, 0
    andi  x2, x1, 0x7FF     # lower 11 bits of PC
    # PC is always 4-aligned so bits[1:0] = 0; bit2 may vary
    andi  x3, x2, 3         # bits[1:0] must be 00
    add   x4, x3, x3        # 0  (alignment check)

    # --------------------------------------------------------
    # Phase 6: AUIPC fed into SLT/SLTU
    # PC is always a large positive number in RARS (.text starts
    # at 0x00400000), so:
    #   PC > 0         (signed and unsigned)
    #   PC < 0x7FFFFFFF... probably
    # --------------------------------------------------------
    auipc x1, 0             # PC
    slt   x2, x0, x1        # 0 < PC signed -> 1
    addi  x3, x0, 1
    sub   x4, x2, x3        # 0

    sltu  x2, x0, x1        # 0 < PC unsigned -> 1
    sub   x4, x2, x3        # 0

    slt   x2, x1, x0        # PC < 0 -> 0
    add   x4, x2, x2        # 0

    lui   x5, 0x80000       # INT32_MIN
    slt   x2, x5, x1        # INT32_MIN < PC signed -> 1
    sub   x4, x2, x3        # 0

    sltu  x2, x1, x5        # PC < INT32_MIN unsigned?
                             # RARS .text = 0x00400000 < 0x80000000 -> 1
    sub   x4, x2, x3        # 0

    # --------------------------------------------------------
    # Phase 7: Difference between successive AUIPCs is always 4
    # Run a longer sequence and verify every gap.
    # --------------------------------------------------------
    auipc x1, 0
    auipc x2, 0
    auipc x3, 0
    auipc x4, 0
    auipc x5, 0

    sub   x6, x2, x1        # 4
    sub   x7, x3, x2        # 4
    sub   x8, x4, x3        # 4
    sub   x9, x5, x4        # 4
    sub   x10, x6, x7       # 0
    sub   x11, x7, x8       # 0
    sub   x12, x8, x9       # 0
    add   x13, x10, x11
    add   x13, x13, x12     # 0

    # --------------------------------------------------------
    # Phase 8: AUIPC result stored and reloaded, then used
    # --------------------------------------------------------
    auipc x1, 0
    sw    x1, 4(x31)
    lw    x2, 4(x31)
    sub   x3, x2, x1        # 0 — PC survived memory roundtrip

    auipc x4, 0             # new PC (8 bytes after x1's auipc)
    sub   x5, x4, x1        # should be 4*N for some small N
    # just verify it's positive and a multiple of 4
    sltu  x6, x0, x5        # nonzero -> 1
    addi  x7, x0, 1
    sub   x8, x6, x7        # 0
    andi  x9, x5, 3         # low 2 bits = 0 (4-byte aligned distance)
    add   x10, x9, x9       # 0

    # --------------------------------------------------------
    # Phase 9: Mix AUIPC with full instruction set
    # Build a value from AUIPC, mask it, compare it, store it,
    # reload sub-word, feed back into arithmetic.
    # --------------------------------------------------------
    auipc x1, 0             # PC
    addi  x2, x0, 0x0FF
    and   x3, x1, x2        # lower byte of PC (always 0 for 256-aligned PC,
                             # or small for other alignments)
    ori   x4, x3, 0x040     # set bit 6
    xori  x5, x4, 0x040     # clear it back -> x5 = x3
    sub   x6, x5, x3        # 0

    auipc x1, 0
    addi  x2, x1, 100       # PC + 100
    sub   x3, x2, x1        # 100
    addi  x4, x0, 100
    sub   x5, x3, x4        # 0

    slt   x6, x1, x2        # PC < PC+100 -> 1
    sltu  x7, x1, x2        # same -> 1
    add   x8, x6, x7        # 2
    addi  x9, x0, 2
    sub   x10, x8, x9       # 0

    sw    x2, 8(x31)        # store PC+100
    lw    x11, 8(x31)
    sub   x12, x11, x2      # 0
    lbu   x13, 8(x31)       # low byte of (PC+100)
    lhu   x14, 8(x31)       # low half of (PC+100)
    # low byte of lhu must match low byte of lbu
    andi  x15, x14, 0x0FF
    sub   x16, x15, x13     # 0

    # --------------------------------------------------------
    # Phase 10: AUIPC alignment guarantee
    # Every AUIPC captures a 4-byte-aligned PC.
    # Lower 2 bits must always be 00.
    # --------------------------------------------------------
    auipc x1, 0
    andi  x2, x1, 3         # bits[1:0]
    add   x3, x2, x2        # 0

    auipc x1, 1
    andi  x2, x1, 3
    add   x3, x2, x2        # 0

    auipc x1, 0x7FFFF
    andi  x2, x1, 3
    add   x3, x2, x2        # 0

    # --------------------------------------------------------
    # Phase 11: AUIPC vs LUI — only one encodes PC
    # auipc x1, N  ->  x1 = PC + N<<12   (PC-relative)
    # lui   x2, N  ->  x2 = N<<12        (absolute)
    # difference = PC, which must be positive
    # --------------------------------------------------------
    auipc x1, 1             # PC + 0x1000
    lui   x2, 1             # 0x1000
    sub   x3, x1, x2        # = PC, must be positive and nonzero
    sltu  x4, x0, x3        # 1
    addi  x5, x0, 1
    sub   x6, x4, x5        # 0

    slt   x4, x0, x3        # signed: PC > 0 -> 1
    sub   x6, x4, x5        # 0

    # --------------------------------------------------------
    # Phase 12: Long mixed RAW chain through AUIPC
    # --------------------------------------------------------
    auipc x1, 0             # PC
    addi  x2, x0, 0x7FF     # 2047
    and   x3, x1, x2        # low 11 bits of PC
    auipc x4, 0             # PC+4 (RAW: x3 just written)
    sub   x5, x4, x1        # 4
    add   x6, x3, x5        # (PC & 0x7FF) + 4
    ori   x7, x6, 0x001     # set lsb
    andi  x8, x7, 0x7FF     # keep lower 11
    xori  x9, x8, 0x001     # clear lsb -> back to x6 & 0x7FF
    andi  x10, x6, 0x7FF
    sub   x11, x9, x10      # 0
    slt   x12, x0, x8       # x8 > 0 (has at least bit0 or bit2 set) -> 1
    addi  x13, x0, 1
    sub   x14, x12, x13     # 0
    sw    x8, 12(x31)
    lw    x15, 12(x31)
    sub   x16, x15, x8      # 0
    lbu   x17, 12(x31)
    andi  x18, x8, 0x0FF
    sub   x19, x17, x18     # 0

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0

    wfi
