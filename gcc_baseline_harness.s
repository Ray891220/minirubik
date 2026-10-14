.data
.align 2

state:
    .byte 1, 0, 2, 3, 4, 5, 6
    .byte 0, 0, 0, 0, 0, 0, 0

solution_length:
    .byte 0

.text
.globl _start

_start:
    la   a0, state
    la   a1, solution_length

    call solve_stage3

    la   t0, solution_length
    lbu  a1, 0(t0)

    li   a7, 10
    ecall
