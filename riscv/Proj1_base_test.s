.text
.globl _start
 
_start:
 
    # --- ADD / ADDI ---
    addi x1, x0, 10          # x1 = 10
    addi x2, x0, 20          # x2 = 20
    add  x3, x1, x2          # x3 = 30
 
    # --- SUB ---
    sub  x4, x2, x1          # x4 = 10
 
    # --- AND / ANDI ---
    addi x5, x0, 0xFF        # x5 = 255
    andi x6, x5, 0x0F        # x6 = 15
    and  x7, x5, x6          # x7 = 15
 
    # --- OR / ORI ---
    addi x8, x0, 0xF0        # x8 = 240
    ori  x9, x8, 0x0F        # x9 = 255
    or   x10, x8, x6         # x10 = 255
 
    # --- XOR / XORI ---
    xori x11, x5, 0xFF       # x11 = 0  (255 XOR 255)
    xor  x12, x5, x8         # x12 = 15
 
    # --- SLL / SLLI ---
    addi x13, x0, 1          # x13 = 1
    slli x14, x13, 4         # x14 = 16
    sll  x15, x13, x1        # x15 = 1 << 10 = 1024
 
    # --- SRL / SRLI ---
    addi x16, x0, 0x40       # x16 = 64
    srli x17, x16, 2         # x17 = 16
    srl  x18, x16, x13       # x18 = 32  (64 >> 1)
 
    # --- SRA / SRAI ---
    lui  x19, 0x80000        # x19 = 0x80000000 (negative)
    srai x20, x19, 1         # x20 = 0xC0000000 (sign extended)
    addi x21, x0, 2          # x21 = 2
    sra  x22, x19, x21       # x22 = 0xE0000000 (sign extended)
 
    # --- SLT / SLTI ---
    addi x23, x0, 5          # x23 = 5
    addi x24, x0, 10         # x24 = 10
    slt  x25, x23, x24       # x25 = 1  (5 < 10)
    slt  x26, x24, x23       # x26 = 0  (10 < 5 is false)
    slti x27, x23, 3         # x27 = 0  (5 < 3 is false)
    slti x28, x23, 20        # x28 = 1  (5 < 20)
 
    # --- SLTU / SLTIU ---
    addi x29, x0, 1          # x29 = 1
    sltu x30, x29, x24       # x30 = 1  (1 <u 10)
    sltiu x31, x29, 5        # x31 = 1  (1 <u 5)
 
    # chain results together to confirm data forwarding / sequential execution
    add  x1, x1, x3          # x1 = 10 + 30 = 40
    add  x2, x2, x1          # x2 = 20 + 40 = 60
    sub  x3, x2, x4          # x3 = 60 - 10 = 50
    and  x4, x3, x9          # x4 = 50 & 255 = 50
    or   x5, x4, x11         # x5 = 50 | 0  = 50
    xor  x6, x5, x12         # x6 = 50 XOR 15 = 61
    sll  x7, x6, x29         # x7 = 61 << 1 = 122
    srl  x8, x7, x29         # x8 = 122 >> 1 = 61
    sra  x9, x19, x29        # x9 = arithmetic shift of negative
    slt  x10, x9, x0         # x10 = 1 (negative < 0)
 
    wfi                       # halt
 

