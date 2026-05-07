# ============================================================
# Minimal branch offset diagnostic
# Exposes wrong SB immediate as early as possible (cycle ~5)
# ============================================================

.text
.global _start

_start:
    addi x1, x0, 0         # x1 = 0  (checksum)

    # Test 1: forward branch, short offset (2 instructions = +8 bytes)
    # If offset bits are scrambled this lands wrong immediately
    beq  x0, x0, target_1
    addi x1, x1, -100      # poison — must be skipped
    addi x1, x1, -100      # poison
target_1:
    addi x1, x1, 1         # x1 = 1

    # Test 2: forward branch, longer offset (4 instructions = +16 bytes)
    # Exercises more offset bits
    beq  x0, x0, target_2
    addi x1, x1, -100 ##here is the issue
    addi x1, x1, -100
    addi x1, x1, -100
    addi x1, x1, -100
target_2:
    addi x1, x1, 1         # x1 = 2

    # Test 3: BNE not taken (x0 == x0, so falls through)
    bne  x0, x0, poison_3
    addi x1, x1, 1         # x1 = 3  (must execute)
    beq  x0, x0, target_3
poison_3:
    addi x1, x1, -100
target_3:

    # Test 4: BEQ taken, offset just large enough to use imm[4]
    # offset = 12 bytes (3 instructions forward)
    beq  x0, x0, target_4
    addi x1, x1, -100
    addi x1, x1, -100
    addi x1, x1, -100
target_4:
    addi x1, x1, 1         # x1 = 4

    # Test 5: backward branch — loop exactly 3 times
    addi x2, x0, 3         # counter
loop5:
    addi x2, x2, -1
    bne  x2, x0, loop5     # backward branch: offset is negative
    addi x1, x1, 1         # x1 = 5  (only after loop exits)

    # Test 6: BLT signed — -1 < 1
    addi x3, x0, -1
    addi x4, x0,  1
    blt  x3, x4, target_6
    addi x1, x1, -100
target_6:
    addi x1, x1, 1         # x1 = 6

    # Test 7: BLTU unsigned — 0xFFFFFFFF NOT < 1
    bltu x3, x4, poison_7  # x3 = -1 = 0xFFFFFFFF, should NOT be taken
    addi x1, x1, 1         # x1 = 7  (falls through)
    beq  x0, x0, target_7
poison_7:
    addi x1, x1, -100
target_7:

    # Final: x1 must equal 7
    addi x5, x0, 7
    beq  x1, x5, done
    addi x1, x1, -1000     # loud poison if checksum wrong

done:
    add x0, x0, x0
    add x0, x0, x0
    wfi
