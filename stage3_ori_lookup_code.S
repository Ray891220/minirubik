.text
.globl main

main:
    li   a0, 0

    la   t0, ori_R
    slli t1, a0, 1
    add  t0, t0, t1

    lhu  a0, 0(t0)

done:
    j done
