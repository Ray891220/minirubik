.data
state:
    .byte 0, 1, 2, 3, 4, 5, 6
    .byte 0, 1, 2, 0, 1, 2, 0

.text
.globl main

main:
    la   a0, state
    jal  ra, rank_orientation

done:
    j done


rank_orientation:
    li   t0, 0          # rank = 0
    addi t3, a0, 7      # t3 = &state->o[0]
    li   t4, 0          # i = 0
    li   t5, 6          # only o[0]~o[5]

rank_ori_loop:
    lbu  t2, 0(t3)      # t2 = o[i]

    # rank = rank * 3
    slli t1, t0, 1      # rank * 2
    add  t0, t1, t0     # rank * 3

    # rank += o[i]
    add  t0, t0, t2

    addi t3, t3, 1      # point to next o[i]
    addi t4, t4, 1      # i++

    blt  t4, t5, rank_ori_loop

    mv   a0, t0         # return rank
    ret
