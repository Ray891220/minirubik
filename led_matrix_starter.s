# CA2026 Assignment 1 - LED Matrix starter (RV32I)
# Ripes GUI: instantiate LED Matrix 0, Width=35, Height=25 BEFORE assembling.
# Facelet layout in this standalone test: U, L, F, R, B, D (4 facelets each).
# Pixel format: 0x00RRGGBB; byte offset = 4 * (y*35 + x).
# This version draws a SOLVED cube. Next step: update facelets[] for a scramble.

.data
.align 2
# 0=U(white), 1=L(orange), 2=F(green), 3=R(red), 4=B(blue), 5=D(yellow)
facelets:
    .byte 0, 0, 0, 0
    .byte 1, 1, 1, 1
    .byte 2, 2, 2, 2
    .byte 3, 3, 3, 3
    .byte 4, 4, 4, 4
    .byte 5, 5, 5, 5
.align 2
palette:
    .word 0x00FFFFFF   # U white
    .word 0x00FF8000   # L orange
    .word 0x0000FF00   # F green
    .word 0x00FF0000   # R red
    .word 0x000000FF   # B blue
    .word 0x00FFFF00   # D yellow
face_origin_x:
    .word 9, 0, 9, 18, 27, 9
face_origin_y:
    .word 2, 9, 9, 9, 9, 16

.text
.globl main
main:
    lui s0, 0xF0000
    la s1, facelets
    la s2, palette
    la s3, face_origin_x
    la s4, face_origin_y
    li s5, 0                # face index: 0..5

face_loop:
    li t0, 6
    bge s5, t0, done
    slli t0, s5, 2          # word offset = face*4
    add t1, s3, t0
    lw s8, 0(t1)            # x origin
    add t1, s4, t0
    lw s9, 0(t1)            # y origin
    li s6, 0                # sticker index: 0..3

sticker_loop:
    li t0, 4
    bge s6, t0, next_face

    # color = palette[facelets[face*4 + sticker]]
    slli t0, s5, 2
    add t0, t0, s6
    add t1, s1, t0
    lbu t2, 0(t1)
    slli t2, t2, 2
    add t3, s2, t2
    lw a2, 0(t3)            # a2 = 24-bit RGB color

    # sticker top-left x = origin_x + (sticker%2)*4
    andi t0, s6, 1
    slli t0, t0, 2
    add a0, s8, t0

    # sticker top-left y = origin_y + (sticker/2)*3
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

done:
    li a7, 10               # Ripes exit syscall
    ecall

# draw_sticker(a0=x, a1=y, a2=color)
# Draws a 4-pixel-wide x 3-pixel-high rectangle.
# Clobbers t0..t6; preserves a0..a2 and s-registers.
draw_sticker:
    li t0, 0                # row = 0
row_loop:
    li t1, 0                # col = 0
col_loop:
    add t2, a1, t0          # y + row
    # (y+row)*35 = ((y+row)<<5) + ((y+row)<<1) + (y+row)
    slli t3, t2, 5
    slli t4, t2, 1
    add t3, t3, t4
    add t3, t3, t2
    add t3, t3, a0          # + x
    add t3, t3, t1          # + col
    slli t3, t3, 2          # *4 bytes per LED
    add t3, s0, t3
    sw a2, 0(t3)
    addi t1, t1, 1
    li t5, 4
    blt t1, t5, col_loop
    addi t0, t0, 1
    li t5, 3
    blt t0, t5, row_loop
    ret
