.data

# --------------------------------------------------
# Test state:
# solved cube after one R turn
# expected optimal solution: R'
# move code: 2
# --------------------------------------------------
state:
    .byte 1, 4, 2, 0, 3, 5, 6
    .byte 1, 2, 0, 2, 1, 0, 0

# Maximum solution depth = 11
# allocate 12 bytes
path:
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0


.text
.globl main


# ==================================================
# main
# ==================================================
main:
    la   a0, state
    jal  ra, solve

    # After solve:
    # a0 = 1 if found
    # a1 = solution length

    # Put path[0] into a2 for easy inspection
    la   t0, path
    lbu  a2, 0(t0)

done:
    j done


# ==================================================
# rank_orientation
#
# input:
#   a0 = &state
#
# output:
#   a0 = orientation rank (0..728)
# ==================================================
rank_orientation:
    li   t0, 0              # rank = 0
    addi t3, a0, 7          # t3 = &state->o[0]
    li   t4, 0              # i = 0
    li   t5, 6              # use o[0] ... o[5]

rank_ori_loop:
    lbu  t2, 0(t3)          # t2 = o[i]

    # rank = rank * 3
    slli t1, t0, 1          # rank * 2
    add  t0, t1, t0         # rank * 3

    # rank += o[i]
    add  t0, t0, t2

    addi t3, t3, 1          # next orientation byte
    addi t4, t4, 1          # i++

    blt  t4, t5, rank_ori_loop

    mv   a0, t0
    ret


# ==================================================
# rank_permutation
#
# input:
#   a0 = &state
#
# output:
#   a0 = permutation rank (0..5039)
# ==================================================
rank_permutation:
    li   t0, 0              # rank = 0
    li   t1, 0              # i = 0
    li   a1, 7              # CUBIES = 7

perm_outer:
    # t3 = p[i]
    add  t5, a0, t1
    lbu  t3, 0(t5)

    li   t2, 0              # smaller = 0
    addi t4, t1, 1          # j = i + 1

perm_inner:
    bge  t4, a1, perm_inner_done

    # t6 = p[j]
    add  t5, a0, t4
    lbu  t6, 0(t5)

    # if (p[j] < p[i])
    #     smaller++
    bge  t6, t3, perm_no_inc
    addi t2, t2, 1

perm_no_inc:
    addi t4, t4, 1
    j    perm_inner

perm_inner_done:
    # factor = 7 - i
    sub  a2, a1, t1

    # ------------------------------------------------
    # rank * factor
    #
    # RV32I has no MUL, so repeated addition is used.
    # factor is only 1..7.
    # ------------------------------------------------
    mv   t5, t0
    li   t6, 0

perm_mul:
    beqz a2, perm_mul_done

    add  t6, t6, t5
    addi a2, a2, -1
    j    perm_mul

perm_mul_done:
    # rank = rank * (7-i) + smaller
    add  t0, t6, t2

    addi t1, t1, 1
    blt  t1, a1, perm_outer

    mv   a0, t0
    ret


# ==================================================
# solve
#
# input:
#   a0 = &state
#
# output:
#   a0 = 1 -> solution found
#        0 -> not found
#
#   a1 = solution length
# ==================================================
solve:
    addi sp, sp, -32

    sw   ra, 28(sp)
    sw   s0, 24(sp)
    sw   s1, 20(sp)
    sw   s2, 16(sp)
    sw   s3, 12(sp)

    mv   s0, a0             # s0 = &state


    # ------------------------------------------------
    # p = rank_permutation(state)
    # ------------------------------------------------
    mv   a0, s0
    jal  ra, rank_permutation
    mv   s1, a0             # s1 = p


    # ------------------------------------------------
    # o = rank_orientation(state)
    # ------------------------------------------------
    mv   a0, s0
    jal  ra, rank_orientation
    mv   s2, a0             # s2 = o


    # ------------------------------------------------
    # hp = perm_distance[p]
    # ------------------------------------------------
    la   t0, perm_distance
    add  t0, t0, s1
    lbu  t1, 0(t0)          # t1 = hp


    # ------------------------------------------------
    # ho = ori_distance[o]
    # ------------------------------------------------
    la   t0, ori_distance
    add  t0, t0, s2
    lbu  t2, 0(t0)          # t2 = ho


    # ------------------------------------------------
    # start_limit = max(hp, ho)
    # ------------------------------------------------
    mv   s3, t1

    bge  t1, t2, solve_loop
    mv   s3, t2


# --------------------------------------------------
# Iterative deepening
# --------------------------------------------------
solve_loop:
    mv   a0, s1             # p
    mv   a1, s2             # o

    li   a2, 0              # depth = 0
    mv   a3, s3             # limit

    li   a4, 3              # previous_face = NONE

    jal  ra, dfs

    bnez a0, solve_found

    addi s3, s3, 1          # limit++

    li   t0, 11
    bge  t0, s3, solve_loop


    # not found up to depth 11
    li   a0, 0
    li   a1, 0
    j    solve_return


solve_found:
    li   a0, 1
    mv   a1, s3             # solution length


solve_return:
    lw   s3, 12(sp)
    lw   s2, 16(sp)
    lw   s1, 20(sp)
    lw   s0, 24(sp)
    lw   ra, 28(sp)

    addi sp, sp, 32
    ret


# ==================================================
# dfs
#
# input:
#   a0 = permutation rank p
#   a1 = orientation rank o
#   a2 = depth
#   a3 = limit
#   a4 = previous_face
#
# face:
#   0 = R
#   1 = B
#   2 = D
#   3 = NONE
#
# return:
#   a0 = 1 found
#   a0 = 0 not found
# ==================================================
dfs:
    addi sp, sp, -48

    sw   ra, 44(sp)
    sw   s0, 40(sp)
    sw   s1, 36(sp)
    sw   s2, 32(sp)
    sw   s3, 28(sp)
    sw   s4, 24(sp)
    sw   s5, 20(sp)
    sw   s6, 16(sp)
    sw   s7, 12(sp)
    sw   s8, 8(sp)


    mv   s0, a0             # p
    mv   s1, a1             # o
    mv   s2, a2             # depth
    mv   s3, a3             # limit
    mv   s4, a4             # previous_face


    # ------------------------------------------------
    # if (p == 0 && o == 0)
    #     return 1;
    # ------------------------------------------------
    or   t0, s0, s1
    beqz t0, dfs_success


    # ------------------------------------------------
    # hp = perm_distance[p]
    # ------------------------------------------------
    la   t0, perm_distance
    add  t0, t0, s0
    lbu  t1, 0(t0)


    # ------------------------------------------------
    # ho = ori_distance[o]
    # ------------------------------------------------
    la   t0, ori_distance
    add  t0, t0, s1
    lbu  t2, 0(t0)


    # ------------------------------------------------
    # h = max(hp, ho)
    # ------------------------------------------------
    bge  t1, t2, dfs_have_h
    mv   t1, t2


dfs_have_h:

    # ------------------------------------------------
    # if (depth + h > limit)
    #     prune
    # ------------------------------------------------
    add  t0, s2, t1

    # limit < depth+h
    blt  s3, t0, dfs_fail


    # ------------------------------------------------
    # if (depth == limit)
    #     return 0;
    # ------------------------------------------------
    beq  s2, s3, dfs_fail


    # ------------------------------------------------
    # face = 0
    # ------------------------------------------------
    li   s5, 0


# ==================================================
# for face = R, B, D
# ==================================================
dfs_face_loop:

    li   t0, 3
    bge  s5, t0, dfs_fail


    # ------------------------------------------------
    # Do not use same face twice consecutively
    # ------------------------------------------------
    beq  s5, s4, dfs_next_face


    # next_p = p
    # next_o = o
    mv   s6, s0
    mv   s7, s1


    # turn = 0
    # 0 = quarter turn
    # 1 = half turn
    # 2 = inverse quarter turn
    li   s8, 0


# ==================================================
# for turn = 0..2
# ==================================================
dfs_turn_loop:

    # ------------------------------------------------
    # Choose transition tables based on face
    # ------------------------------------------------
    beqz s5, dfs_table_R

    li   t0, 1
    beq  s5, t0, dfs_table_B


# -----------------------
# face = D
# -----------------------
dfs_table_D:
    la   t3, perm_D
    la   t4, ori_D
    j    dfs_have_tables


# -----------------------
# face = R
# -----------------------
dfs_table_R:
    la   t3, perm_R
    la   t4, ori_R
    j    dfs_have_tables


# -----------------------
# face = B
# -----------------------
dfs_table_B:
    la   t3, perm_B
    la   t4, ori_B


dfs_have_tables:

    # ------------------------------------------------
    # next_p = permutation[face][next_p]
    #
    # uint16_t -> index * 2
    # ------------------------------------------------
    slli t0, s6, 1
    add  t0, t3, t0
    lhu  s6, 0(t0)


    # ------------------------------------------------
    # next_o = orientation[face][next_o]
    # ------------------------------------------------
    slli t0, s7, 1
    add  t0, t4, t0
    lhu  s7, 0(t0)


    # ------------------------------------------------
    # move = face * 3 + turn
    # ------------------------------------------------
    slli t0, s5, 1          # face * 2
    add  t0, t0, s5         # face * 3
    add  t0, t0, s8         # + turn


    # ------------------------------------------------
    # path[depth] = move
    # ------------------------------------------------
    la   t1, path
    add  t1, t1, s2
    sb   t0, 0(t1)


    # ------------------------------------------------
    # dfs(next_p,
    #     next_o,
    #     depth + 1,
    #     limit,
    #     face)
    # ------------------------------------------------
    mv   a0, s6
    mv   a1, s7
    addi a2, s2, 1
    mv   a3, s3
    mv   a4, s5

    jal  ra, dfs


    # child found solution
    bnez a0, dfs_success


    # ------------------------------------------------
    # turn++
    # ------------------------------------------------
    addi s8, s8, 1

    li   t0, 3
    blt  s8, t0, dfs_turn_loop


# --------------------------------------------------
# next face
# --------------------------------------------------
dfs_next_face:
    addi s5, s5, 1
    j    dfs_face_loop


# ==================================================
# return success
# ==================================================
dfs_success:
    li   a0, 1
    j    dfs_return


# ==================================================
# return failure
# ==================================================
dfs_fail:
    li   a0, 0


# ==================================================
# restore stack frame
# ==================================================
dfs_return:
    lw   s8, 8(sp)
    lw   s7, 12(sp)
    lw   s6, 16(sp)
    lw   s5, 20(sp)
    lw   s4, 24(sp)
    lw   s3, 28(sp)
    lw   s2, 32(sp)
    lw   s1, 36(sp)
    lw   s0, 40(sp)
    lw   ra, 44(sp)

    addi sp, sp, 48
    ret
