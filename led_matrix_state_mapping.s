# CA2026 -- state_to_facelets() verification before Stage 4 solver integration.
# RV32I, Ripes LED Matrix 0: 35x25, MMIO base 0xF0000000.
# NO new move engine: both test states are known states from minirubik.
# Source state representation: p[7] cubie IDs 0..6, o[7] twists 0..2.
# p[i] and o[i] represent moving physical corner position (i+1).
# Corner 0 (front-upper-left) is fixed and implicitly has cubie 0, twist 0.
# Facelets: U,L,F,R,B,D, 4 per face, exterior face net, row-major.
# In Ripes, break at solved_ready, inspect display; then run to R_ready.
# Both test flags must be 1; on normal exit a0 = 1 means both pass.

.data
.align 2
# p / o are INTERNAL numeric values, not ASCII input digits.
solved_p: .byte 0,1,2,3,4,5,6
solved_o: .byte 0,0,0,0,0,0,0
# Official one-move R(solved), p=1420356, o=1202100.
R_p:      .byte 1,4,2,0,3,5,6
R_o:      .byte 1,2,0,2,1,0,0
.align 2
facelets: .zero 24
solved_ok: .word 0
R_ok:      .word 0

# Physical corner positions 0..7, 3 facelet indices per position.
# See upstream report.md, "Unfolded Face Net", in exterior view.
position_facelets:
    .byte  2, 8, 5     # 0 FUL = fixed
    .byte  3,12, 9     # 1 FUR
    .byte 21,11,14     # 2 FDR
    .byte 20, 7,10     # 3 FDL
    .byte  1,16,13     # 4 BUR
    .byte 23,15,18     # 5 BDR
    .byte 22,19, 6     # 6 BDL
    .byte  0, 4,17     # 7 BUL

# Three sticker colors of each cubie in the matching cyclic order.
# 0 U=white, 1 L=orange, 2 F=green, 3 R=red, 4 B=blue, 5 D=yellow.
corner_colors:
    .byte 0,2,1  # 0 FUL
    .byte 0,3,2  # 1 FUR
    .byte 5,2,3  # 2 FDR
    .byte 5,1,2  # 3 FDL
    .byte 0,4,3  # 4 BUR
    .byte 5,3,4  # 5 BDR
    .byte 5,4,1  # 6 BDL
    .byte 0,1,4  # 7 BUL

# Expected facelets for solved cube.
expected_solved:
    .byte 0,0,0,0, 1,1,1,1, 2,2,2,2
    .byte 3,3,3,3, 4,4,4,4, 5,5,5,5
# Expected facelets for R(solved), independently checked by rotating
# the R-face stickers geometrically around the physical x-axis.
expected_R:
    .byte 0,2,0,2, 1,1,1,1, 2,5,2,5
    .byte 3,3,3,3, 0,4,0,4, 5,4,5,4

.align 2
palette:
    .word 0x00FFFFFF, 0x00FF8000, 0x0000FF00
    .word 0x00FF0000, 0x000000FF, 0x00FFFF00
face_origin_x: .word 9,0,9,18,27,9
face_origin_y: .word 2,9,9,9,9,16

.text
.globl main
.globl state_to_facelets
main:
    lui s0, 0xF0000       # Ripes LED Matrix 0 base, 0xF0000000
    la s1, facelets
    la s2, palette
    la s3, face_origin_x
    la s4, face_origin_y

    # Test 1: solved p/o -> all monochrome faces.
    la a0, solved_p
    la a1, solved_o
    la a2, facelets
    jal ra, state_to_facelets
    la a0, facelets
    la a1, expected_solved
    jal ra, compare_facelets
    la t0, solved_ok
    sw a0, 0(t0)
    jal ra, draw_cube
solved_ready:
    nop                  # Breakpoint: inspect solved frame here.

    # Test 2: known one-move R state (no R move code is executed).
    la a0, R_p
    la a1, R_o
    la a2, facelets
    jal ra, state_to_facelets
    la a0, facelets
    la a1, expected_R
    jal ra, compare_facelets
    la t0, R_ok
    sw a0, 0(t0)
    jal ra, draw_cube
R_ready:
    nop                  # Breakpoint: inspect one-move frame here.

    la t0, solved_ok
    lw t1, 0(t0)
    la t0, R_ok
    lw t2, 0(t0)
    and a0, t1, t2      # a0 = 1 iff both test vectors passed
    li a7, 10
    ecall

# state_to_facelets(a0=p[7], a1=o[7], a2=facelets[24]).
# p and o contain internal 0-based numeric values (not ASCII digits).
# Reconstruct all 24 stickers; does NOT modify p/o or perform moves.
# Clobbers t0..t6, a3..a6. Leaf; a0..a2 and ra remain unchanged.
state_to_facelets:
    la t4, position_facelets
    la t5, corner_colors
    li t0, 0                    # physical position 0..7
stf_position:
    li t1, 8
    bge t0, t1, stf_end
    beqz t0, stf_fixed
    addi t1, t0, -1             # index into solver p/o arrays
    add t2, a0, t1
    lbu t2, 0(t2)               # internal cubie 0..6
    addi t2, t2, 1              # physical cubie 1..7
    add t3, a1, t1
    lbu t3, 0(t3)               # orientation 0..2
    j stf_position_ready
stf_fixed:
    li t2, 0                    # fixed physical cubie 0
    li t3, 0                    # fixed orientation 0
stf_position_ready:
    slli t1, t0, 1
    add t1, t1, t0              # pos * 3
    add a3, t4, t1              # facelet indices for this position
    slli t1, t2, 1
    add t1, t1, t2              # cubie * 3
    add a4, t5, t1              # colors for this cubie
    li t6, 0                    # sticker slot 0..2
stf_sticker:
    li t1, 3
    bge t6, t1, stf_next_position
    add a5, a3, t6
    lbu a5, 0(a5)               # destination facelet index
    add a5, a2, a5
    add a6, t6, t3              # (slot + orientation) modulo 3
    li t1, 3
    blt a6, t1, stf_color_ready
    addi a6, a6, -3            # max 4, so subtract once
stf_color_ready:
    add a6, a4, a6
    lbu a6, 0(a6)               # color ID
    sb a6, 0(a5)
    addi t6, t6, 1
    j stf_sticker
stf_next_position:
    addi t0, t0, 1
    j stf_position
stf_end:
    ret

# compare_facelets(a0=actual, a1=expected) -> a0=1 if identical.
compare_facelets:
    li t0, 0
cf_loop:
    li t1, 24
    bge t0, t1, cf_pass
    add t1, a0, t0
    lbu t1, 0(t1)
    add t2, a1, t0
    lbu t2, 0(t2)
    bne t1, t2, cf_fail
    addi t0, t0, 1
    j cf_loop
cf_pass:
    li a0, 1
    ret
cf_fail:
    li a0, 0
    ret

# Draw the 24 facelets. Callee-saved registers restored.
draw_cube:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s5, 24(sp)
    sw s6, 20(sp)
    sw s8, 16(sp)
    sw s9, 12(sp)
    li s5, 0
face_loop:
    li t0, 6
    bge s5, t0, draw_done
    slli t0, s5, 2
    add t1, s3, t0
    lw s8, 0(t1)
    add t1, s4, t0
    lw s9, 0(t1)
    li s6, 0
sticker_loop:
    li t0, 4
    bge s6, t0, next_face
    slli t0, s5, 2
    add t0, t0, s6
    add t1, s1, t0
    lbu t2, 0(t1)
    slli t2, t2, 2
    add t3, s2, t2
    lw a2, 0(t3)
    andi t0, s6, 1
    slli t0, t0, 2
    add a0, s8, t0
    srli t0, s6, 1
    slli t1, t0, 1
    add t0, t0, t1
    add a1, s9, t0
    jal ra, draw_sticker
    addi s6, s6, 1
    j sticker_loop
next_face:
    addi s5, s5, 1
    j face_loop
draw_done:
    lw ra, 28(sp)
    lw s5, 24(sp)
    lw s6, 20(sp)
    lw s8, 16(sp)
    lw s9, 12(sp)
    addi sp, sp, 32
    ret

# draw_sticker(a0=x,a1=y,a2=color), 4x3 LED pixels, MMIO word writes.
draw_sticker:
    li t0, 0
row_loop:
    li t1, 0
col_loop:
    add t2, a1, t0
    slli t3, t2, 5
    slli t4, t2, 1
    add t3, t3, t4
    add t3, t3, t2              # y*35
    add t3, t3, a0
    add t3, t3, t1
    slli t3, t3, 2              # 4 bytes per LED
    add t3, s0, t3
    sw a2, 0(t3)
    addi t1, t1, 1
    li t5, 4
    blt t1, t5, col_loop
    addi t0, t0, 1
    li t5, 3
    blt t0, t5, row_loop
    ret
