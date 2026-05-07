# ============================================================
# RISC-V Stress Test — LB, LH, LBU, LHU
# (plus SW, LW, ADD, SUB, ADDI, LUI, OR, AND, XOR, ANDI, XORI, ORI)
# ============================================================
# Coverage:
#   LB  — load byte, sign-extended
#   LH  — load halfword, sign-extended
#   LBU — load byte, zero-extended
#   LHU — load halfword, zero-extended
#
#   Per instruction:
#     - Basic roundtrip (store word, load sub-word)
#     - Sign extension vs zero extension contrast
#     - Negative values (bit7/bit15 set) to expose sign bugs
#     - All byte lanes in a word (offsets 0,1,2,3 for byte; 0,2 for half)
#     - Load-use hazard (result consumed by next instruction)
#     - Loaded value fed into ALU, logic, and SW
#     - Back-to-back sub-word loads (RAW on consecutive loads)
#     - LUI-built patterns to fill all 32 bits before sub-word extraction
# ============================================================

.data
scratch: .space 256

.text
.global _start

_start:
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)

    # --------------------------------------------------------
    # Helper: fill word at base+0 with 0xDEADBEEF-ish pattern
    # We build 0x817F_FF80 — has sign bits set in every lane:
    #   byte0 (offset 0) = 0x80  -> signed -128, unsigned 128
    #   byte1 (offset 1) = 0xFF  -> signed  -1,  unsigned 255
    #   byte2 (offset 2) = 0x7F  -> signed +127, unsigned 127
    #   byte3 (offset 3) = 0x81  -> signed -127, unsigned 129
    #   half0 (offset 0) = 0xFF80 -> signed -128, unsigned 65408
    #   half1 (offset 2) = 0x817F -> signed -32385, unsigned 33151
    #
    # Build 0x817FFF80:
    #   lui  x1, 0x817FF   -> 0x817FF000
    #   addi x1, x1, -128  -> 0x817FF000 - 0x80 = 0x817FFF80
    # --------------------------------------------------------
    lui  x1, 0x817FF
    addi x1, x1, -128       # x1 = 0x817FFF80
    sw   x1, 0(x31)         # mem[0..3] = 80 FF 7F 81 (little-endian)

    # --------------------------------------------------------
    # Phase 1: LBU — load byte unsigned (zero-extended)
    # All four byte lanes, verify no sign extension occurs.
    # --------------------------------------------------------
    lbu  x2, 0(x31)         # byte0 = 0x80 -> x2 = 128  (NOT -128)
    addi x3, x0, 128
    sub  x4, x2, x3         # 0

    lbu  x2, 1(x31)         # byte1 = 0xFF -> x2 = 255
    addi x3, x0, 255
    sub  x4, x2, x3         # 0

    lbu  x2, 2(x31)         # byte2 = 0x7F -> x2 = 127
    addi x3, x0, 127
    sub  x4, x2, x3         # 0

    lbu  x2, 3(x31)         # byte3 = 0x81 -> x2 = 129
    addi x3, x0, 129
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 2: LB — load byte signed (sign-extended)
    # Same four lanes; now negative bytes must produce negatives.
    # --------------------------------------------------------
    lb   x2, 0(x31)         # byte0 = 0x80 -> x2 = -128
    addi x3, x0, -128
    sub  x4, x2, x3         # 0

    lb   x2, 1(x31)         # byte1 = 0xFF -> x2 = -1
    addi x3, x0, -1
    sub  x4, x2, x3         # 0

    lb   x2, 2(x31)         # byte2 = 0x7F -> x2 = +127
    addi x3, x0, 127
    sub  x4, x2, x3         # 0

    lb   x2, 3(x31)         # byte3 = 0x81 -> x2 = -127
    addi x3, x0, -127
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 3: LB vs LBU contrast on the same byte
    # The key bug to catch: LB and LBU produce different results
    # for bytes with bit7 set, identical for bit7 clear.
    # --------------------------------------------------------
    # Byte with bit7 SET (0x80): LB=-128, LBU=128; difference=256
    lb   x2, 0(x31)         # -128
    lbu  x3, 0(x31)         # 128
    sub  x4, x3, x2         # 128 - (-128) = 256
    addi x5, x0, 256        # -- 256 > 255, fits in addi? 256 <= 2047 yes
    sub  x6, x4, x5         # 0

    # Byte with bit7 CLEAR (0x7F): LB=LBU=127; difference=0
    lb   x2, 2(x31)         # +127
    lbu  x3, 2(x31)         # +127
    sub  x4, x3, x2         # 0

    # --------------------------------------------------------
    # Phase 4: LHU — load halfword unsigned (zero-extended)
    # --------------------------------------------------------
    # half0 at offset 0 = 0xFF80 = 65408
    lhu  x2, 0(x31)
    lui  x3, 0x00010        # x3 = 65536
    addi x3, x3, -128       # x3 = 65408
    sub  x4, x2, x3         # 0

    # half1 at offset 2 = 0x817F = 33151
    lhu  x2, 2(x31)
    lui  x3, 0x00008        # x3 = 32768
    addi x3, x3, 383        # 32768 + 383 = 33151
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 5: LH — load halfword signed (sign-extended)
    # --------------------------------------------------------
    # half0 = 0xFF80; bit15 set -> signed = -128
    lh   x2, 0(x31)
    addi x3, x0, -128
    sub  x4, x2, x3         # 0

    # half1 = 0x817F; bit15 set -> signed = -32385
    lh   x2, 2(x31)
    lui  x3, 0xFFFF8        # start building -32385
    addi x3, x3, -897       # 0xFFFF8000 + (-897) -- let's compute:
                             # -32385 = 0xFFFF817F
                             # lui 0xFFFF8 = 0xFFFF8000
                             # need addi of 0x17F = 383
                             # but 0xFFFF8000 + 383 = 0xFFFF817F = -32385 YES
    lui  x3, 0xFFFF8
    addi x3, x3, 0x17F      # x3 = 0xFFFF817F = -32385
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 6: LH vs LHU contrast on same halfword
    # --------------------------------------------------------
    # half0 = 0xFF80: LH=-128, LHU=65408; diff=65536
    lh   x2, 0(x31)         # -128
    lhu  x3, 0(x31)         # 65408
    sub  x4, x3, x2         # 65408-(-128) = 65536
    lui  x5, 0x00010        # 65536
    sub  x6, x4, x5         # 0

    # half1 = 0x817F: LH=-32385, LHU=33151; diff=65536
    lh   x2, 2(x31)         # -32385
    lhu  x3, 2(x31)         # 33151
    sub  x4, x3, x2         # 65536
    lui  x5, 0x00010
    sub  x6, x4, x5         # 0

    # --------------------------------------------------------
    # Phase 7: Load-use hazards for all four instructions
    # Result consumed by the immediately following instruction.
    # --------------------------------------------------------
    # LBU load-use
    lbu  x2, 0(x31)         # x2 = 128
    add  x3, x2, x2         # x3 = 256  (load-use)
    addi x4, x0, 256
    sub  x5, x3, x4         # 0

    # LB load-use
    lb   x2, 0(x31)         # x2 = -128
    add  x3, x2, x2         # x3 = -256  (load-use)
    lui  x4, 0xFFFFF
    addi x4, x4, -256       # -- 0xFFFFF000 - 256 = 0xFFFEFF00, wrong approach
    # build -256 directly: addi x4, x0, -256 (fits: -256 >= -2048)
    addi x4, x0, -256
    sub  x5, x3, x4         # 0

    # LHU load-use
    lhu  x2, 0(x31)         # x2 = 65408
    addi x3, x2, 1          # x3 = 65409  (load-use into addi)
    lui  x4, 0x00010
    addi x4, x4, -127       # 65536 - 127 = 65409
    sub  x5, x3, x4         # 0

    # LH load-use
    lh   x2, 0(x31)         # x2 = -128
    sub  x3, x0, x2         # x3 = 128   (load-use: negate)
    addi x4, x0, 128
    sub  x5, x3, x4         # 0

    # --------------------------------------------------------
    # Phase 8: Sub-word load into logic ops
    # --------------------------------------------------------
    # LBU -> ANDI (mask lower nibble)
    lbu  x2, 1(x31)         # x2 = 255
    andi x3, x2, 0x00F      # x3 = 15   (load-use into andi)
    addi x4, x0, 15
    sub  x5, x3, x4         # 0

    # LBU -> ORI
    lbu  x2, 2(x31)         # x2 = 127 = 0x7F
    ori  x3, x2, 0x080      # x3 = 0xFF = 255  (set bit7)
    addi x4, x0, 255
    sub  x5, x3, x4         # 0  -- wait, 0x080 = 128 > 127, addi range ok (128<=2047)

    # LB -> XORI -1 (bitwise NOT)
    lb   x2, 1(x31)         # x2 = -1 = 0xFFFFFFFF
    xori x3, x2, -1         # x3 = 0
    add  x4, x3, x3         # 0

    # LHU -> AND with LUI mask
    lhu  x2, 0(x31)         # x2 = 0x0000FF80
    addi x3, x0, 0x0FF      # mask for lower byte
    and  x4, x2, x3         # x4 = 0x80 = 128
    addi x5, x0, 128
    sub  x6, x4, x5         # 0

    # --------------------------------------------------------
    # Phase 9: Back-to-back sub-word loads (consecutive load RAW)
    # --------------------------------------------------------
    lb   x2, 0(x31)         # -128
    lb   x3, 1(x31)         # -1
    add  x4, x2, x3         # -129  (both are load results)
    addi x5, x0, -129
    sub  x6, x4, x5         # 0

    lbu  x2, 0(x31)         # 128
    lbu  x3, 1(x31)         # 255
    add  x4, x2, x3         # 383
    addi x5, x0, 383
    sub  x6, x4, x5         # 0

    lh   x2, 0(x31)         # -128
    lhu  x3, 0(x31)         # 65408
    add  x4, x2, x3         # -128 + 65408 = 65280
    lui  x5, 0x00010        # 65536
    addi x5, x5, -256       # 65280
    sub  x6, x4, x5         # 0

    # --------------------------------------------------------
    # Phase 10: All byte lanes — store word, extract each byte
    # Build 0x01020304 and verify each byte lane.
    # --------------------------------------------------------
    # 0x01020304: byte0=0x04, byte1=0x03, byte2=0x02, byte3=0x01
    lui  x1, 0x01020        # 0x01020000
    addi x1, x1, 0x304      # 0x01020304  (0x304=772, fits)
    sw   x1, 4(x31)

    lbu  x2, 4(x31)         # byte0 = 0x04
    addi x3, x0, 4
    sub  x4, x2, x3         # 0

    lbu  x2, 5(x31)         # byte1 = 0x03
    addi x3, x0, 3
    sub  x4, x2, x3         # 0

    lbu  x2, 6(x31)         # byte2 = 0x02
    addi x3, x0, 2
    sub  x4, x2, x3         # 0

    lbu  x2, 7(x31)         # byte3 = 0x01
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    # Same with LB (all positive, so LB=LBU here)
    lb   x2, 4(x31)
    addi x3, x0, 4
    sub  x4, x2, x3         # 0
    lb   x2, 7(x31)
    addi x3, x0, 1
    sub  x4, x2, x3         # 0

    # Both halfword lanes
    lhu  x2, 4(x31)         # half0 = 0x0304 = 772
    addi x3, x0, 772
    sub  x4, x2, x3         # 0

    lhu  x2, 6(x31)         # half1 = 0x0102 = 258
    addi x3, x0, 258
    sub  x4, x2, x3         # 0

    lh   x2, 4(x31)         # 0x0304 = 772, bit15 clear -> same as LHU
    addi x3, x0, 772
    sub  x4, x2, x3         # 0

    lh   x2, 6(x31)         # 0x0102 = 258, bit15 clear -> same as LHU
    addi x3, x0, 258
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 11: Negative byte/halfword sign extension deep check
    # Build 0x80FF7F81 — every lane has bit7/15 set except byte2
    # byte0=0x81=-127  byte1=0x7F=127  byte2=0xFF=-1  byte3=0x80=-128
    # half0=0x7F81=32641(+)  half1=0x80FF=-32513(-)
    # --------------------------------------------------------
    lui  x1, 0x80FF7
    addi x1, x1, -127       # 0x80FF7000 - 127 = 0x80FF6F81 -- not right
    # build carefully:
    # 0x80FF7F81:
    # lui 0x80FF8 = 0x80FF8000
    # addi -127 = 0x80FF8000 - 0x7F = 0x80FF7F81  YES
    lui  x1, 0x80FF8
    addi x1, x1, -127       # x1 = 0x80FF7F81
    sw   x1, 8(x31)

    lb   x2, 8(x31)         # byte0 = 0x81 = -127
    addi x3, x0, -127
    sub  x4, x2, x3         # 0

    lb   x2, 9(x31)         # byte1 = 0x7F = +127
    addi x3, x0, 127
    sub  x4, x2, x3         # 0

    lb   x2, 10(x31)        # byte2 = 0xFF = -1
    addi x3, x0, -1
    sub  x4, x2, x3         # 0

    lb   x2, 11(x31)        # byte3 = 0x80 = -128
    addi x3, x0, -128
    sub  x4, x2, x3         # 0

    lbu  x2, 8(x31)         # 0x81 = 129
    addi x3, x0, 129
    sub  x4, x2, x3         # 0

    lbu  x2, 10(x31)        # 0xFF = 255
    addi x3, x0, 255
    sub  x4, x2, x3         # 0

    lh   x2, 8(x31)         # half0 = 0x7F81 = 32641, bit15 clear -> positive
    lui  x3, 0x00008        # 32768
    addi x3, x3, -127       # 32641
    sub  x4, x2, x3         # 0

    lh   x2, 10(x31)        # half1 = 0x80FF, bit15 set -> signed negative
                             # 0x80FF = -32513
    lui  x3, 0xFFFF8
    addi x3, x3, 0x0FF      # 0xFFFF8000 + 255 = 0xFFFF80FF = -32513
    sub  x4, x2, x3         # 0

    lhu  x2, 8(x31)         # 0x7F81 = 32641
    lui  x3, 0x00008
    addi x3, x3, -127
    sub  x4, x2, x3         # 0

    lhu  x2, 10(x31)        # 0x80FF = 33023
    lui  x3, 0x00008        # 32768
    addi x3, x3, 255        # 33023
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 12: Sub-word loads feeding SW (store loaded value back)
    # --------------------------------------------------------
    lbu  x2, 0(x31)         # 128
    sw   x2, 12(x31)
    lw   x3, 12(x31)
    sub  x4, x3, x2         # 0

    lb   x2, 0(x31)         # -128
    sw   x2, 16(x31)
    lw   x3, 16(x31)
    sub  x4, x3, x2         # 0

    lhu  x2, 0(x31)         # 65408
    sw   x2, 20(x31)
    lw   x3, 20(x31)
    sub  x4, x3, x2         # 0

    lh   x2, 0(x31)         # -128
    sw   x2, 24(x31)
    lw   x3, 24(x31)
    sub  x4, x3, x2         # 0

    # --------------------------------------------------------
    # Phase 13: Negative-offset addressing for sub-word loads
    # --------------------------------------------------------
    addi x10, x31, 3        # x10 = base + 3
    lb   x2,  0(x10)        # byte3 of word0 = 0x81 = -127
    addi x3, x0, -127
    sub  x4, x2, x3         # 0

    lbu  x2,  0(x10)        # byte3 = 129
    addi x3, x0, 129
    sub  x4, x2, x3         # 0

    addi x10, x31, 4        # x10 = base + 4
    lb   x2, -1(x10)        # base+3 = 0x81 = -127
    addi x3, x0, -127
    sub  x4, x2, x3         # 0

    lbu  x2, -4(x10)        # base+0 = 0x80 = 128
    addi x3, x0, 128
    sub  x4, x2, x3         # 0

    lh   x2, -2(x10)        # base+2 = half1 of word0 = 0x817F = -32385
    lui  x3, 0xFFFF8
    addi x3, x3, 0x17F      # -32385
    sub  x4, x2, x3         # 0

    lhu  x2, -4(x10)        # base+0 = half0 = 0xFF80 = 65408
    lui  x3, 0x00010
    addi x3, x3, -128
    sub  x4, x2, x3         # 0

    # --------------------------------------------------------
    # Phase 14: Mixed chain — sub-word loads into full pipeline
    # --------------------------------------------------------
    lbu  x1, 0(x31)         # 128
    lbu  x2, 1(x31)         # 255
    add  x3, x1, x2         # 383
    lb   x4, 2(x31)         # +127
    sub  x5, x3, x4         # 256
    lhu  x6, 0(x31)         # 65408
    add  x7, x5, x4         # 383
    lh   x8, 2(x31)         # -32385
    sub  x9, x6, x5         # 65408 - 256 = 65152
    xor  x10, x1, x2        # 128 ^ 255 = 127
    and  x11, x6, x7        # 65408 & 383 = 256 (0xFF80 & 0x017F = 0x0100)
    addi x12, x0, 256
    sub  x13, x11, x12      # 0

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0

    wfi
