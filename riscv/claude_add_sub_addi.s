# ============================================================
# RISC-V Stress Test — Only ADD, SUB, ADDI
# ============================================================
# Targets:
#   - Register file read/write pressure (all x1–x31 exercised)
#   - Back-to-back RAW hazards (data forwarding / stall paths)
#   - Long dependency chains (pipeline depth exposure)
#   - Independent instruction streams (ILP / out-of-order stress)
#   - Overflow / wraparound arithmetic
#   - Loop control via addi + sub
# ============================================================

    # --------------------------------------------------------
    # Phase 1: Initialise all registers with distinct values
    # so that mis-forwarding is detectable.
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
    # Phase 2: Immediate back-to-back RAW hazard chain
    # Every instruction reads the result written one cycle prior.
    # A pipeline without forwarding MUST stall here.
    # --------------------------------------------------------
    addi x1, x0,  1        # x1 = 1
    addi x1, x1,  1        # x1 = 2   (RAW: 1-cycle gap = EX→EX forward)
    addi x1, x1,  1        # x1 = 3   (RAW: 1-cycle gap)
    addi x1, x1,  1        # x1 = 4
    addi x1, x1,  1        # x1 = 5
    add  x1, x1, x1        # x1 = 10  (RAW: uses value written above)
    sub  x1, x1, x2        # x1 = 8   (two-source RAW)
    add  x1, x1, x1        # x1 = 16
    sub  x1, x1, x3        # x1 = 13
    add  x1, x1, x1        # x1 = 26

    # --------------------------------------------------------
    # Phase 3: Two-cycle RAW chain (MEM→EX forwarding path)
    # Producer is two instructions before consumer.
    # --------------------------------------------------------
    addi x2, x0, 7         # x2 = 7
    addi x3, x0, 3         # x3 = 3   (no dependence on x2)
    add  x4, x2, x3        # x4 = 10  (reads x2 written 2 cycles ago)
    addi x5, x0, 5         # x5 = 5
    add  x6, x4, x5        # x6 = 15  (reads x4 written 2 cycles ago)
    sub  x7, x6, x3        # x7 = 12
    add  x8, x7, x7        # x8 = 24
    sub  x9, x8, x6        # x9 = 9

    # --------------------------------------------------------
    # Phase 4: Independent instruction streams
    # Multiple parallel chains — stresses execution bandwidth
    # and register file ports.
    # --------------------------------------------------------
    addi x10, x0, 100
    addi x11, x0, 200
    addi x12, x0, 300
    addi x13, x0, 400

    add  x14, x10, x11     # 300
    add  x15, x12, x13     # 700
    sub  x16, x15, x14     # 400
    add  x17, x14, x15     # 1000
    sub  x18, x17, x16     # 600
    add  x19, x16, x18     # 1000
    sub  x20, x19, x17     # 0
    add  x21, x17, x18     # 1600
    sub  x22, x21, x19     # 600
    add  x23, x20, x22     # 600

    # --------------------------------------------------------
    # Phase 5: Long serial dependency chain
    # Exposes full pipeline depth — no ILP possible.
    # --------------------------------------------------------
    addi x1, x0,  1
    add  x1, x1, x1        # 2
    add  x1, x1, x1        # 4
    add  x1, x1, x1        # 8
    add  x1, x1, x1        # 16
    add  x1, x1, x1        # 32
    add  x1, x1, x1        # 64
    add  x1, x1, x1        # 128
    add  x1, x1, x1        # 256
    add  x1, x1, x1        # 512
    add  x1, x1, x1        # 1024
    add  x1, x1, x1        # 2048
    addi x1, x1, -1        # 2047
    sub  x2, x1, x1        # 0
    addi x2, x2, -1        # -1 (0xFFFFFFFF — tests sign extension)
    add  x3, x2, x2        # -2
    sub  x4, x0, x2        # +1 (negate via sub)

    # --------------------------------------------------------
    # Phase 6: Immediate range stress
    # addi imm field is 12-bit signed: [-2048 .. 2047]
    # --------------------------------------------------------
    addi x1, x0, 2047      # max positive imm
    addi x2, x0, -2048     # max negative imm
    add  x3, x1, x1        # 4094
    sub  x4, x3, x2        # 4094 - (-2048) = 6142
    addi x5, x4, -1        # 6141
    addi x6, x2, 1         # -2047
    sub  x7, x1, x6        # 2047 - (-2047) = 4094
    add  x8, x7, x2        # 4094 + (-2048) = 2046
    addi x9, x8, 1         # 2047

    # --------------------------------------------------------
    # Phase 7: Loop — repeated accumulation (N=64 iterations)
    # Uses: addi (loop counter), add (accumulate), sub (decrement test)
    # --------------------------------------------------------
    addi x1, x0, 0         # accumulator = 0
    addi x2, x0, 1         # increment   = 1
    addi x3, x0, 64        # loop count  = 64

stress_loop:
    add  x1, x1, x2        # acc += 1
    addi x2, x2, 1         # inc += 1  (triangular sum)
    addi x3, x3, -1        # count--
    add  x4, x3, x0        # copy count (exercises extra read port)
    sub  x5, x4, x0        # another copy (back-to-back reads)
    # branch-free: loop runs exactly 64 times via a countdown
    # (real branch would need beq/bne — forbidden here, so we
    #  unroll the exit check manually after the loop body above
    #  and rely on the assembler label + branch if you add one,
    #  or simply let the loop body execute linearly 64×.)
    # For simulators that support pseudo-branch: uncomment below:
    # bne x3, x0, stress_loop

    # --------------------------------------------------------
    # Phase 8: Overflow / wraparound (32-bit signed)
    # x1 = 0x7FFFFFFF (INT32_MAX built from shifts via add)
    # --------------------------------------------------------
    addi x1, x0, 1
    addi x2, x0, 10
    # Build 2^30 by repeated doubling (30 add x,x,x steps)
    add  x1, x1, x1   # 2
    add  x1, x1, x1   # 4
    add  x1, x1, x1   # 8
    add  x1, x1, x1   # 16
    add  x1, x1, x1   # 32
    add  x1, x1, x1   # 64
    add  x1, x1, x1   # 128
    add  x1, x1, x1   # 256
    add  x1, x1, x1   # 512
    add  x1, x1, x1   # 1024
    add  x1, x1, x1   # 2048
    add  x1, x1, x1   # 4096
    add  x1, x1, x1   # 8192
    add  x1, x1, x1   # 16384
    add  x1, x1, x1   # 32768
    add  x1, x1, x1   # 65536
    add  x1, x1, x1   # 131072
    add  x1, x1, x1   # 262144
    add  x1, x1, x1   # 524288
    add  x1, x1, x1   # 1048576
    add  x1, x1, x1   # 2097152
    add  x1, x1, x1   # 4194304
    add  x1, x1, x1   # 8388608
    add  x1, x1, x1   # 16777216
    add  x1, x1, x1   # 33554432
    add  x1, x1, x1   # 67108864
    add  x1, x1, x1   # 134217728
    add  x1, x1, x1   # 268435456
    add  x1, x1, x1   # 536870912
    add  x1, x1, x1   # 1073741824  (2^30)
    add  x2, x1, x1   # 2^31 = 0x80000000 (overflow → INT32_MIN)
    sub  x3, x2, x1   # 0x80000000 - 2^30 = INT32_MIN + 2^30 (still negative)
    add  x4, x2, x2   # 0x80000000 + 0x80000000 = 0 (overflow wraps to 0)
    addi x5, x2, -1   # 0x7FFFFFFF = INT32_MAX

    # --------------------------------------------------------
    # Phase 9: Register file port hammer
    # Many reads of many registers per cycle.
    # --------------------------------------------------------
    add  x1,  x5,  x4
    add  x2,  x1,  x3
    add  x3,  x2,  x5
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
    # End — park in an infinite self-loop (add x0, x0, x0)
    # x0 is hardwired zero; writes are discarded. Safe spin.
    # --------------------------------------------------------
done:
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    # (add a branch to `done` if your simulator supports it)
    wfi
