


.text
.global _start
_start:
    # Store a known value into memory using lui + sw
    lui  x1, 0x10000       # x1 = base address (e.g., 0x10000000)
    
    addi x2, x0, 0x7F      # x2 = 0x7F (positive byte)
    sw   x2, 0(x1)         # mem[0x10000000] = 0x0000007F

    lb   x3, 0(x1)         # x3 should = 0x0000007F (positive, no sign ext change)

    # Test sign extension: store 0x80 (negative as signed byte)
    addi x4, x0, -1        # x4 = 0xFFFFFFFF
    sw   x4, 4(x1)         # mem[...+4] = 0xFFFFFFFF

    lb   x5, 4(x1)         # x5 should = 0xFFFFFFFF (sign-extended 0xFF)
    
    wfi
