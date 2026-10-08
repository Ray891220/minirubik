.text
.globl main

main:
    li   a0, 0
    la   t0, perm_distance

    add  t0, t0, a0
    lbu  a0, 0(t0)

done:
    j done
