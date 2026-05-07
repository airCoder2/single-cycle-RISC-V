# ============================================================
# RISC-V Branch Stress Test
# BEQ, BNE, BLT, BGE, BLTU, BGEU
# + all previously verified instructions (no AUIPC)
# ============================================================
# Strategy:
#   Every branch is tested BOTH ways:
#     - branch TAKEN:     must jump, skip the "fail" trap
#     - branch NOT TAKEN: must fall through, skip the "pass" trap
#   A "fail trap" is an infinite loop: if we land there, the
#   processor never finishes — visible as a hang or wrong trace.
#   Every phase ends with a running checksum in x30 so a wrong
#   branch that falls through silently still corrupts the total.
# ============================================================

.data
scratch: .space 64

.text
.global _start

_start:
    lui  x31, %hi(scratch)
    addi x31, x31, %lo(scratch)
    addi x30, x0, 0         # x30 = checksum accumulator

    # --------------------------------------------------------
    # Phase 1: BEQ
    # --------------------------------------------------------

    # TAKEN: equal values
    addi x1, x0, 42
    addi x2, x0, 42
    beq  x1, x2, beq_taken_1
    addi x30, x30, -1       # should NOT execute
beq_taken_1:
    addi x30, x30, 1        # checksum += 1  (x30 = 1)

    # NOT TAKEN: unequal values
    addi x1, x0, 1
    addi x2, x0, 2
    beq  x1, x2, beq_fail_1
    addi x30, x30, 1        # checksum += 1  (x30 = 2)
    beq x0, x0, beq_nt_done_1
beq_fail_1:
    addi x30, x30, -100     # poison — should never execute
beq_nt_done_1:

    # TAKEN: both zero
    beq  x0, x0, beq_taken_2
    addi x30, x30, -1
beq_taken_2:
    addi x30, x30, 1        # x30 = 3

    # TAKEN: both negative
    addi x1, x0, -5
    addi x2, x0, -5
    beq  x1, x2, beq_taken_3
    addi x30, x30, -1
beq_taken_3:
    addi x30, x30, 1        # x30 = 4

    # NOT TAKEN: -1 vs 1
    addi x1, x0, -1
    addi x2, x0,  1
    beq  x1, x2, beq_fail_2
    addi x30, x30, 1        # x30 = 5
    beq x0, x0, beq_nt_done_2
beq_fail_2:
    addi x30, x30, -100
beq_nt_done_2:

    # NOT TAKEN: INT32_MIN vs INT32_MAX
    lui  x1, 0x80000
    lui  x2, 0x80000
    addi x2, x2, -1         # INT32_MAX
    beq  x1, x2, beq_fail_3
    addi x30, x30, 1        # x30 = 6
    beq x0, x0, beq_nt_done_3
beq_fail_3:
    addi x30, x30, -100
beq_nt_done_3:

    # --------------------------------------------------------
    # Phase 2: BNE
    # --------------------------------------------------------

    # TAKEN: unequal
    addi x1, x0, 1
    addi x2, x0, 2
    bne  x1, x2, bne_taken_1
    addi x30, x30, -1
bne_taken_1:
    addi x30, x30, 1        # x30 = 7

    # NOT TAKEN: equal
    addi x1, x0, 99
    addi x2, x0, 99
    bne  x1, x2, bne_fail_1
    addi x30, x30, 1        # x30 = 8
    beq x0, x0, bne_nt_done_1
bne_fail_1:
    addi x30, x30, -100
bne_nt_done_1:

    # TAKEN: 0 vs nonzero
    addi x1, x0, 0
    addi x2, x0, 1
    bne  x1, x2, bne_taken_2
    addi x30, x30, -1
bne_taken_2:
    addi x30, x30, 1        # x30 = 9

    # TAKEN: -1 vs 0
    addi x1, x0, -1
    bne  x1, x0, bne_taken_3
    addi x30, x30, -1
bne_taken_3:
    addi x30, x30, 1        # x30 = 10

    # NOT TAKEN: x0 vs x0
    bne  x0, x0, bne_fail_2
    addi x30, x30, 1        # x30 = 11
    beq x0, x0, bne_nt_done_2
bne_fail_2:
    addi x30, x30, -100
bne_nt_done_2:

    # TAKEN: INT32_MIN vs INT32_MAX
    lui  x1, 0x80000
    lui  x2, 0x80000
    addi x2, x2, -1
    bne  x1, x2, bne_taken_4
    addi x30, x30, -1
bne_taken_4:
    addi x30, x30, 1        # x30 = 12

    # --------------------------------------------------------
    # Phase 3: BLT (signed)
    # --------------------------------------------------------

    # TAKEN: 1 < 2
    addi x1, x0, 1
    addi x2, x0, 2
    blt  x1, x2, blt_taken_1
    addi x30, x30, -1
blt_taken_1:
    addi x30, x30, 1        # x30 = 13

    # NOT TAKEN: 2 < 1 false
    blt  x2, x1, blt_fail_1
    addi x30, x30, 1        # x30 = 14
    beq x0, x0, blt_nt_done_1
blt_fail_1:
    addi x30, x30, -100
blt_nt_done_1:

    # NOT TAKEN: equal
    addi x1, x0, 5
    blt  x1, x1, blt_fail_2
    addi x30, x30, 1        # x30 = 15
    beq x0, x0, blt_nt_done_2
blt_fail_2:
    addi x30, x30, -100
blt_nt_done_2:

    # TAKEN: -1 < 0 signed
    addi x1, x0, -1
    addi x2, x0,  0
    blt  x1, x2, blt_taken_2
    addi x30, x30, -1
blt_taken_2:
    addi x30, x30, 1        # x30 = 16

    # NOT TAKEN: 0 < -1 false (signed)
    blt  x2, x1, blt_fail_3
    addi x30, x30, 1        # x30 = 17
    beq x0, x0, blt_nt_done_3
blt_fail_3:
    addi x30, x30, -100
blt_nt_done_3:

    # TAKEN: INT32_MIN < 0
    lui  x1, 0x80000        # INT32_MIN
    addi x2, x0, 0
    blt  x1, x2, blt_taken_3
    addi x30, x30, -1
blt_taken_3:
    addi x30, x30, 1        # x30 = 18

    # NOT TAKEN: 0 < INT32_MIN false (signed)
    blt  x2, x1, blt_fail_4
    addi x30, x30, 1        # x30 = 19
    beq x0, x0, blt_nt_done_4
blt_fail_4:
    addi x30, x30, -100
blt_nt_done_4:

    # TAKEN: INT32_MIN < INT32_MAX
    lui  x1, 0x80000
    lui  x2, 0x80000
    addi x2, x2, -1         # INT32_MAX
    blt  x1, x2, blt_taken_4
    addi x30, x30, -1
blt_taken_4:
    addi x30, x30, 1        # x30 = 20

    # --------------------------------------------------------
    # Phase 4: BGE (signed)
    # --------------------------------------------------------

    # TAKEN: 2 >= 1
    addi x1, x0, 2
    addi x2, x0, 1
    bge  x1, x2, bge_taken_1
    addi x30, x30, -1
bge_taken_1:
    addi x30, x30, 1        # x30 = 21

    # TAKEN: equal (>=)
    addi x1, x0, 5
    addi x2, x0, 5
    bge  x1, x2, bge_taken_2
    addi x30, x30, -1
bge_taken_2:
    addi x30, x30, 1        # x30 = 22

    # NOT TAKEN: 1 >= 2 false
    addi x1, x0, 1
    addi x2, x0, 2
    bge  x1, x2, bge_fail_1
    addi x30, x30, 1        # x30 = 23
    beq x0, x0, bge_nt_done_1
bge_fail_1:
    addi x30, x30, -100
bge_nt_done_1:

    # TAKEN: 0 >= -1 signed
    addi x1, x0,  0
    addi x2, x0, -1
    bge  x1, x2, bge_taken_3
    addi x30, x30, -1
bge_taken_3:
    addi x30, x30, 1        # x30 = 24

    # NOT TAKEN: -1 >= 0 false
    bge  x2, x1, bge_fail_2
    addi x30, x30, 1        # x30 = 25
    beq x0, x0, bge_nt_done_2
bge_fail_2:
    addi x30, x30, -100
bge_nt_done_2:

    # TAKEN: INT32_MAX >= INT32_MIN
    lui  x1, 0x80000
    addi x1, x1, -1         # INT32_MAX
    lui  x2, 0x80000        # INT32_MIN
    bge  x1, x2, bge_taken_4
    addi x30, x30, -1
bge_taken_4:
    addi x30, x30, 1        # x30 = 26

    # TAKEN: INT32_MIN >= INT32_MIN (equal)
    lui  x1, 0x80000
    lui  x2, 0x80000
    bge  x1, x2, bge_taken_5
    addi x30, x30, -1
bge_taken_5:
    addi x30, x30, 1        # x30 = 27

    # --------------------------------------------------------
    # Phase 5: BLTU (unsigned)
    # --------------------------------------------------------

    # TAKEN: 1 < 2 unsigned
    addi x1, x0, 1
    addi x2, x0, 2
    bltu x1, x2, bltu_taken_1
    addi x30, x30, -1
bltu_taken_1:
    addi x30, x30, 1        # x30 = 28

    # NOT TAKEN: 2 < 1 false
    bltu x2, x1, bltu_fail_1
    addi x30, x30, 1        # x30 = 29
    beq x0, x0, bltu_nt_done_1
bltu_fail_1:
    addi x30, x30, -100
bltu_nt_done_1:

    # NOT TAKEN: equal
    addi x1, x0, 7
    bltu x1, x1, bltu_fail_2
    addi x30, x30, 1        # x30 = 30
    beq x0, x0, bltu_nt_done_2
bltu_fail_2:
    addi x30, x30, -100
bltu_nt_done_2:

    # TAKEN: 0 < 0xFFFFFFFF unsigned
    addi x1, x0, 0
    addi x2, x0, -1         # 0xFFFFFFFF
    bltu x1, x2, bltu_taken_2
    addi x30, x30, -1
bltu_taken_2:
    addi x30, x30, 1        # x30 = 31

    # NOT TAKEN: 0xFFFFFFFF < 0 false unsigned
    bltu x2, x1, bltu_fail_3
    addi x30, x30, 1        # x30 = 32
    beq x0, x0, bltu_nt_done_3
bltu_fail_3:
    addi x30, x30, -100
bltu_nt_done_3:

    # KEY: -1 (0xFFFFFFFF) > 0 unsigned, opposite of signed
    # BLTU: 0xFFFFFFFF < 0? NO -> not taken
    addi x1, x0, -1
    bltu x1, x0, bltu_fail_4
    addi x30, x30, 1        # x30 = 33
    beq x0, x0, bltu_nt_done_4
bltu_fail_4:
    addi x30, x30, -100
bltu_nt_done_4:

    # TAKEN: INT32_MAX < INT32_MIN unsigned (0x7FFFFFFF < 0x80000000)
    lui  x1, 0x80000
    addi x2, x1, -1         # INT32_MAX
    bltu x2, x1, bltu_taken_3
    addi x30, x30, -1
bltu_taken_3:
    addi x30, x30, 1        # x30 = 34

    # --------------------------------------------------------
    # Phase 6: BGEU (unsigned)
    # --------------------------------------------------------

    # TAKEN: 2 >= 1 unsigned
    addi x1, x0, 2
    addi x2, x0, 1
    bgeu x1, x2, bgeu_taken_1
    addi x30, x30, -1
bgeu_taken_1:
    addi x30, x30, 1        # x30 = 35

    # TAKEN: equal
    addi x1, x0, 5
    bgeu x1, x1, bgeu_taken_2
    addi x30, x30, -1
bgeu_taken_2:
    addi x30, x30, 1        # x30 = 36

    # NOT TAKEN: 1 >= 2 false
    addi x1, x0, 1
    addi x2, x0, 2
    bgeu x1, x2, bgeu_fail_1
    addi x30, x30, 1        # x30 = 37
    beq x0, x0, bgeu_nt_done_1
bgeu_fail_1:
    addi x30, x30, -100
bgeu_nt_done_1:

    # TAKEN: 0xFFFFFFFF >= 0 unsigned
    addi x1, x0, -1         # 0xFFFFFFFF
    bgeu x1, x0, bgeu_taken_3
    addi x30, x30, -1
bgeu_taken_3:
    addi x30, x30, 1        # x30 = 38

    # NOT TAKEN: 0 >= 0xFFFFFFFF false unsigned
    bgeu x0, x1, bgeu_fail_2
    addi x30, x30, 1        # x30 = 39
    beq x0, x0, bgeu_nt_done_2
bgeu_fail_2:
    addi x30, x30, -100
bgeu_nt_done_2:

    # TAKEN: INT32_MIN >= INT32_MAX unsigned (0x80000000 >= 0x7FFFFFFF)
    lui  x1, 0x80000        # INT32_MIN = large unsigned
    lui  x2, 0x80000
    addi x2, x2, -1         # INT32_MAX = smaller unsigned
    bgeu x1, x2, bgeu_taken_4
    addi x30, x30, -1
bgeu_taken_4:
    addi x30, x30, 1        # x30 = 40

    # --------------------------------------------------------
    # Phase 7: BLT vs BLTU contrast — sign boundary
    # -1 (0xFFFFFFFF) vs 1:
    #   BLT:  -1 < 1  signed   -> TAKEN
    #   BLTU: -1 < 1  unsigned -> NOT TAKEN (0xFFFFFFFF > 1)
    # --------------------------------------------------------
    addi x1, x0, -1
    addi x2, x0,  1

    blt  x1, x2, blt_sign_taken
    addi x30, x30, -100
blt_sign_taken:
    addi x30, x30, 1        # x30 = 41

    bltu x1, x2, bltu_sign_fail
    addi x30, x30, 1        # x30 = 42
    beq x0, x0, bltu_sign_done
bltu_sign_fail:
    addi x30, x30, -100
bltu_sign_done:

    # INT32_MIN vs 1:
    #   BLT:  INT32_MIN < 1 signed   -> TAKEN
    #   BLTU: INT32_MIN < 1 unsigned -> NOT TAKEN
    lui  x1, 0x80000        # INT32_MIN
    addi x2, x0, 1

    blt  x1, x2, blt_min_taken
    addi x30, x30, -100
blt_min_taken:
    addi x30, x30, 1        # x30 = 43

    bltu x1, x2, bltu_min_fail
    addi x30, x30, 1        # x30 = 44
    beq x0, x0, bltu_min_done
bltu_min_fail:
    addi x30, x30, -100
bltu_min_done:

    # --------------------------------------------------------
    # Phase 8: BGE vs BGEU contrast
    # 0 vs -1:
    #   BGE:  0 >= -1 signed   -> TAKEN
    #   BGEU: 0 >= -1 unsigned -> NOT TAKEN (0 < 0xFFFFFFFF)
    # --------------------------------------------------------
    addi x1, x0,  0
    addi x2, x0, -1

    bge  x1, x2, bge_sign_taken
    addi x30, x30, -100
bge_sign_taken:
    addi x30, x30, 1        # x30 = 45

    bgeu x1, x2, bgeu_sign_fail
    addi x30, x30, 1        # x30 = 46
    beq x0, x0, bgeu_sign_done
bgeu_sign_fail:
    addi x30, x30, -100
bgeu_sign_done:

    # --------------------------------------------------------
    # Phase 9: Branches after ALU/logic/memory operations
    # The branch operands come from previous instructions,
    # exercising forwarding into the branch comparator.
    # --------------------------------------------------------

    # ALU result -> BEQ
    addi x1, x0, 10
    addi x2, x0, 10
    add  x3, x1, x0         # x3 = 10  (forwarded into beq)
    beq  x3, x2, alu_beq_taken
    addi x30, x30, -100
alu_beq_taken:
    addi x30, x30, 1        # x30 = 47

    # Logic result -> BNE
    addi x1, x0, 0x055
    addi x2, x0, 0x0AA
    xor  x3, x1, x2         # x3 = 0xFF, != 0
    bne  x3, x0, logic_bne_taken
    addi x30, x30, -100
logic_bne_taken:
    addi x30, x30, 1        # x30 = 48

    # AND result -> BEQ zero
    and  x3, x1, x2         # 0x55 & 0xAA = 0
    beq  x3, x0, and_beq_taken
    addi x30, x30, -100
and_beq_taken:
    addi x30, x30, 1        # x30 = 49

    # LW result -> BNE
    addi x1, x0, 77
    sw   x1, 0(x31)
    lw   x2, 0(x31)         # load-use then branch
    bne  x2, x0, lw_bne_taken
    addi x30, x30, -100
lw_bne_taken:
    addi x30, x30, 1        # x30 = 50

    # LW result -> BEQ
    beq  x2, x1, lw_beq_taken
    addi x30, x30, -100
lw_beq_taken:
    addi x30, x30, 1        # x30 = 51

    # SLT result -> BNE (slt produces 1, compare to 1)
    addi x1, x0, 3
    addi x2, x0, 5
    slt  x3, x1, x2         # x3 = 1
    addi x4, x0, 1
    bne  x3, x4, slt_bne_fail
    addi x30, x30, 1        # x30 = 52
    beq x0, x0, slt_bne_done
slt_bne_fail:
    addi x30, x30, -100
slt_bne_done:

    # --------------------------------------------------------
    # Phase 10: Loop — forward branch (skip) and backward branch
    # Sum 1+2+...+10 = 55 using a loop.
    # --------------------------------------------------------
    addi x1, x0, 0          # accumulator
    addi x2, x0, 1          # counter
    addi x3, x0, 10         # limit

loop10:
    add  x1, x1, x2         # acc += counter
    addi x2, x2, 1          # counter++
    bge  x3, x2, loop10     # while counter <= 10  (pseudo: bge x3,x2)
                             # use bge x3, x2 -> branch if 10 >= counter

    addi x4, x0, 55
    sub  x5, x1, x4         # 0
    add  x30, x30, x5       # checksum unchanged (adds 0)
    addi x30, x30, 1        # x30 = 53

    # --------------------------------------------------------
    # Phase 11: Countdown loop with BNE
    # --------------------------------------------------------
    addi x1, x0, 8          # counter = 8
    addi x2, x0, 0          # accumulator
countdown:
    add  x2, x2, x1
    addi x1, x1, -1
    bne  x1, x0, countdown  # while x1 != 0

    # sum = 8+7+...+1 = 36
    addi x3, x0, 36
    sub  x4, x2, x3         # 0
    add  x30, x30, x4
    addi x30, x30, 1        # x30 = 54

    # --------------------------------------------------------
    # Phase 12: Nested behavior — branch over branch
    # --------------------------------------------------------
    addi x1, x0, 1
    addi x2, x0, 2
    addi x3, x0, 3

    blt  x1, x2, outer_taken    # 1 < 2 -> taken
    addi x30, x30, -100
outer_taken:
    blt  x2, x3, inner_taken    # 2 < 3 -> taken
    addi x30, x30, -100
inner_taken:
    addi x30, x30, 1        # x30 = 55

    bge  x3, x2, ge_taken   # 3 >= 2 -> taken
    addi x30, x30, -100
ge_taken:
    bge  x2, x1, ge2_taken  # 2 >= 1 -> taken
    addi x30, x30, -100
ge2_taken:
    addi x30, x30, 1        # x30 = 56

    # --------------------------------------------------------
    # Phase 13: Branch with memory ops in the mix
    # --------------------------------------------------------
    addi x1, x0, 100
    addi x2, x0, 200
    sw   x1, 0(x31)
    sw   x2, 4(x31)
    lw   x3, 0(x31)
    lw   x4, 4(x31)

    blt  x3, x4, mem_blt_taken  # 100 < 200 -> taken
    addi x30, x30, -100
mem_blt_taken:
    addi x30, x30, 1        # x30 = 57

    bge  x4, x3, mem_bge_taken  # 200 >= 100 -> taken
    addi x30, x30, -100
mem_bge_taken:
    addi x30, x30, 1        # x30 = 58

    beq  x3, x4, mem_beq_fail   # 100 != 200 -> not taken
    addi x30, x30, 1        # x30 = 59
    beq x0, x0, mem_beq_done
mem_beq_fail:
    addi x30, x30, -100
mem_beq_done:

    # --------------------------------------------------------
    # Phase 14: All six branches on x0 comparisons
    # --------------------------------------------------------
    beq  x0, x0, x0_beq_t
    addi x30, x30, -100
x0_beq_t:
    addi x30, x30, 1        # x30 = 60

    bne  x0, x0, x0_bne_f
    addi x30, x30, 1        # x30 = 61
    beq x0, x0, x0_bne_done
x0_bne_f:
    addi x30, x30, -100
x0_bne_done:

    blt  x0, x0, x0_blt_f
    addi x30, x30, 1        # x30 = 62
    beq x0, x0, x0_blt_done
x0_blt_f:
    addi x30, x30, -100
x0_blt_done:

    bge  x0, x0, x0_bge_t
    addi x30, x30, -100
x0_bge_t:
    addi x30, x30, 1        # x30 = 63

    bltu x0, x0, x0_bltu_f
    addi x30, x30, 1        # x30 = 64
    beq x0, x0, x0_bltu_done
x0_bltu_f:
    addi x30, x30, -100
x0_bltu_done:

    bgeu x0, x0, x0_bgeu_t
    addi x30, x30, -100
x0_bgeu_t:
    addi x30, x30, 1        # x30 = 65

    # --------------------------------------------------------
    # Phase 15: Final checksum verification
    # x30 must equal 65
    # --------------------------------------------------------
    addi x1, x0, 65
    beq  x30, x1, checksum_pass
    addi x30, x30, -1000    # poison if wrong count
checksum_pass:

    # --------------------------------------------------------
    # End
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0

    wfi
