.data
state:
    .byte 1, 0, 2, 3, 4, 5, 6      # p[0..6]
    .byte 0, 0, 0, 0, 0, 0, 0      # o[0..6]

.text
.globl main

main:
    la   a0, state
    jal  ra, rank_permutation

done:
    j done


rank_permutation:
    li   t0, 0          # rank = 0
    li   t1, 0          # i = 0
    li   a1, 7          # CUBIES = 7

perm_outer:
    # p[i]
    add  t5, a0, t1
    lbu  t3, 0(t5)

    li   t2, 0          # smaller = 0
    addi t4, t1, 1      # j = i + 1

perm_inner:
    bge  t4, a1, perm_inner_done

    add  t5, a0, t4
    lbu  t6, 0(t5)      # p[j]

    # if (p[j] < p[i]) smaller++
    bge  t6, t3, perm_no_inc
    addi t2, t2, 1

perm_no_inc:
    addi t4, t4, 1
    j    perm_inner

perm_inner_done:
    # factor = 7 - i
    sub  a2, a1, t1

    # rank * factor
    # RV32I 沒有 mul，所以用 repeated addition
    mv   t5, t0
    li   t6, 0

perm_mul:
    beqz a2, perm_mul_done
    add  t6, t6, t5
    addi a2, a2, -1
    j    perm_mul

perm_mul_done:
    add  t0, t6, t2     # rank = rank * (7-i) + smaller

    addi t1, t1, 1
    blt  t1, a1, perm_outer

    mv   a0, t0
    ret
