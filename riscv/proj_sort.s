# Sorting Algorithm Template in RISC-V Assembly - Tyler Bibus
# Mergesort implementation

.data
    array_size: .word 12
    array: .word 65, 12, 10, 89, 11, 70, 67, 5, 9, 45, 90, 7
    temp_buffer: .space 2048   # Temporary buffer for merging (512 * 4 bytes)

.text
.globl main

main:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la a0, array
    lw a1, array_size
    jal ra, sort

    lw ra, 0(sp)
    addi sp, sp, 4
    
    wfi

# void sort(int* array, int size)
.globl sort

sort:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    mv s0, a0           # s0 = array pointer
    mv s1, a1           # s1 = size

    # Base case: if size <= 1, return
    li t0, 1
    ble s1, t0, sort_return

    # Calculate mid = size / 2
    srli s2, s1, 1      # s2 = mid

    # Sort left half: mergesort(array, mid)
    mv a0, s0
    mv a1, s2
    jal ra, sort

    # Sort right half: mergesort(array + mid*4, size - mid)
    slli t0, s2, 2      # t0 = mid * 4 (byte offset)
    add a0, s0, t0      # a0 = array + mid*4
    sub a1, s1, s2      # a1 = size - mid
    jal ra, sort

    # Merge the two halves
    mv a0, s0           # array
    mv a1, s2           # left size (mid)
    sub a2, s1, s2      # right size (size - mid)
    jal ra, merge

sort_return:
    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 16
    ret


# void merge(int* array, int left_size, int right_size)
# Merges two adjacent sorted subarrays in-place using temp_buffer
# Left subarray:  array[0..left_size-1]
# Right subarray: array[left_size..left_size+right_size-1]
merge:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)
    sw s5, 4(sp)
    sw s6, 0(sp)

    mv s0, a0           # s0 = array
    mv s1, a1           # s1 = left_size
    mv s2, a2           # s2 = right_size

    # Load address of temp_buffer
    la s3, temp_buffer

    # Copy entire array (left + right) into temp_buffer
    add t2, s1, s2      # total = left_size + right_size
    mv t0, s0           # src = array
    mv t1, s3           # dst = temp_buffer
    li t3, 0            # i = 0
copy_loop:
    bge t3, t2, copy_done
    lw t4, 0(t0)
    sw t4, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t3, t3, 1
    j copy_loop
copy_done:

    # i = index into left half of temp_buffer (starts at 0)
    li s4, 0
    # j = index into right half of temp_buffer (starts at left_size)
    mv s5, s1
    # k = index into output array
    li s6, 0

merge_loop:
    # while i < left_size && j < (left_size + right_size)
    bge s4, s1, merge_flush_right   # if i >= left_size, drain right
    add t0, s1, s2
    bge s5, t0, merge_flush_left    # if j >= total, drain left

    # Load temp_buffer[i] and temp_buffer[j]
    slli t1, s4, 2
    add t1, s3, t1
    lw t1, 0(t1)        # left element

    slli t2, s5, 2
    add t2, s3, t2
    lw t2, 0(t2)        # right element

    # if left <= right, pick left
    bgt t1, t2, pick_right

pick_left:
    slli t3, s6, 2
    add t3, s0, t3
    sw t1, 0(t3)
    addi s4, s4, 1
    addi s6, s6, 1
    j merge_loop

pick_right:
    slli t3, s6, 2
    add t3, s0, t3
    sw t2, 0(t3)
    addi s5, s5, 1
    addi s6, s6, 1
    j merge_loop

merge_flush_left:
    bge s4, s1, merge_done
    slli t1, s4, 2
    add t1, s3, t1
    lw t1, 0(t1)
    slli t3, s6, 2
    add t3, s0, t3
    sw t1, 0(t3)
    addi s4, s4, 1
    addi s6, s6, 1
    j merge_flush_left

merge_flush_right:
    add t0, s1, s2
    bge s5, t0, merge_done
    slli t2, s5, 2
    add t2, s3, t2
    lw t2, 0(t2)
    slli t3, s6, 2
    add t3, s0, t3
    sw t2, 0(t3)
    addi s5, s5, 1
    addi s6, s6, 1
    j merge_flush_right

merge_done:
    lw ra, 28(sp)
    lw s0, 24(sp)
    lw s1, 20(sp)
    lw s2, 16(sp)
    lw s3, 12(sp)
    lw s4, 8(sp)
    lw s5, 4(sp)
    lw s6, 0(sp)
    addi sp, sp, 32
    ret
