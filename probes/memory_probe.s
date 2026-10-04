.equ REGION_SIZE, 262144

.data
buffer:
	.zero REGION_SIZE

.text
.global main

main:
	la t0, buffer
	li t1, REGION_SIZE
	li t2, 1

write_loop:
    sb      t2, 0(t0)
    addi    t0, t0, 1
    addi    t1, t1, -1
    bnez    t1, write_loop

    li      a7, 10
    ecall
