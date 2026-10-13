	.file	"solver_stage3_core.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	solve_stage3
	.type	solve_stage3, @function
solve_stage3:
	addi	sp,sp,-176
	lui	t1,%hi(.L6)
	sw	s1,168(sp)
	sw	s0,172(sp)
	sw	s2,164(sp)
	sw	s3,160(sp)
	sw	s4,156(sp)
	sw	s5,152(sp)
	mv	s1,a1
	li	a7,1
	li	t2,0
	li	a6,7
	li	t4,8
	li	t3,4
	addi	t1,t1,%lo(.L6)
.L12:
	add	a5,a0,a7
	lbu	a1,-1(a5)
	andi	a2,a7,0xff
	mv	a5,a7
	li	a4,0
.L3:
	add	a3,a0,a5
	lbu	a3,0(a3)
	bgeu	a3,a1,.L2
	addi	a4,a4,1
	andi	a4,a4,0xff
.L2:
	addi	a5,a5,1
	andi	a3,a5,0xff
	bne	a3,a6,.L3
	sub	a5,t4,a2
	addi	a5,a5,-3
	andi	a5,a5,0xff
	bgtu	a5,t3,.L4
	slli	a5,a5,2
	add	a5,a5,t1
	lw	a5,0(a5)
	jr	a5
	.section	.rodata
	.align	2
	.align	2
.L6:
	.word	.L10
	.word	.L9
	.word	.L8
	.word	.L7
	.word	.L5
	.text
.L8:
	slli	a5,t2,2
	add	a5,t2,a5
	slli	a5,a5,16
	srli	a5,a5,16
.L11:
	add	a4,a4,a5
	slli	t2,a4,16
	addi	a7,a7,1
	srli	t2,t2,16
	bne	a7,a6,.L12
	addi	a3,a0,7
	addi	a5,a0,13
	li	a4,0
.L13:
	lbu	a2,0(a3)
	slli	a1,a4,1
	add	a4,a4,a1
	add	a4,a4,a2
	slli	a4,a4,16
	addi	a3,a3,1
	srli	a4,a4,16
	bne	a5,a3,.L13
	lui	t3,%hi(perm_distance)
	lui	t4,%hi(ori_distance)
	addi	t3,t3,%lo(perm_distance)
	addi	t4,t4,%lo(ori_distance)
	add	a5,t3,t2
	add	a3,t4,a4
	lbu	a5,0(a5)
	lbu	a3,0(a3)
	slli	a4,a4,16
	or	t2,t2,a4
	andi	a6,a5,0xff
	bgeu	a5,a3,.L14
	andi	a6,a3,0xff
.L14:
	li	a5,11
	bgtu	a6,a5,.L33
	lui	t0,%hi(.LANCHOR0)
	li	t6,65536
	li	a1,-1
	li	a7,2
	li	t5,3
	addi	t0,t0,%lo(.LANCHOR0)
	addi	t6,t6,-1
	li	t1,1
	li	s0,12
.L15:
	sw	t2,0(sp)
	sb	a1,8(sp)
	sb	zero,11(sp)
	li	a4,0
	li	a5,0
	li	a2,0
	beq	a4,zero,.L30
.L17:
	add	a4,a2,a5
	slli	a4,a4,2
	addi	a4,a4,144
	add	a4,a4,sp
	lbu	a4,-135(a4)
	bgtu	a4,a7,.L21
.L23:
	add	a3,a2,a5
	slli	a3,a3,2
	addi	a3,a3,144
	add	a3,a3,sp
	lbu	s2,-136(a3)
.L24:
	beq	s2,a4,.L42
	lbu	a0,-134(a3)
	bleu	a0,a7,.L27
	addi	a4,a4,1
	andi	a4,a4,0xff
.L26:
	sb	a4,-135(a3)
	sb	zero,-134(a3)
	bne	a4,t5,.L24
.L21:
	beq	a5,zero,.L31
	addi	a5,a5,-1
	andi	a5,a5,0xff
	slli	a2,a5,1
	add	a4,a2,a5
	slli	a4,a4,2
	addi	a4,a4,144
	add	a4,a4,sp
	lbu	a4,-133(a4)
	bne	a4,zero,.L17
.L30:
	add	a4,a2,a5
	slli	a4,a4,2
	addi	a4,a4,144
	add	a4,a4,sp
	lhu	a3,-144(a4)
	sb	t1,-133(a4)
	lhu	a4,-142(a4)
	bne	a3,zero,.L19
	beq	a4,zero,.L20
.L19:
	add	a4,t4,a4
	add	a3,t3,a3
	lbu	a3,0(a3)
	lbu	a0,0(a4)
	mv	a4,a3
	bgeu	a3,a0,.L22
	mv	a4,a0
.L22:
	add	a4,a5,a4
	andi	a4,a4,0xff
	bgtu	a4,a6,.L21
	beq	a6,a5,.L21
	add	a4,a2,a5
	slli	a4,a4,2
	addi	a4,a4,144
	add	a4,a4,sp
	sb	zero,-135(a4)
	sb	zero,-134(a4)
	li	a4,0
	j	.L23
.L9:
	slli	a5,t2,2
	slli	a5,a5,16
	srli	a5,a5,16
	j	.L11
.L10:
	slli	a5,t2,1
	add	a5,t2,a5
	slli	a5,a5,16
	srli	a5,a5,16
	j	.L11
.L7:
	slli	a5,t2,1
	add	a5,t2,a5
	slli	a5,a5,1
	slli	a5,a5,16
	srli	a5,a5,16
	j	.L11
.L5:
	slli	a5,t2,3
	sub	a5,a5,t2
	slli	a5,a5,16
	srli	a5,a5,16
	j	.L11
.L27:
	beq	a0,zero,.L28
	lhu	s3,-138(a3)
.L29:
	add	a3,a2,a5
	slli	a3,a3,2
	addi	a2,a3,144
	add	s4,a2,sp
	slli	a2,a4,2
	lhu	s5,-140(s4)
	add	a2,t0,a2
	lw	s2,0(a2)
	lw	a2,12(a2)
	slli	s3,s3,1
	slli	s5,s5,1
	add	a2,a2,s3
	add	s2,s2,s5
	lhu	s3,0(a2)
	lhu	s2,0(s2)
	addi	a5,a5,1
	andi	a5,a5,0xff
	slli	s3,s3,16
	and	s2,s2,t6
	slli	a2,a5,1
	or	s2,s2,s3
	add	s3,sp,a3
	add	a3,a2,a5
	sw	s2,4(s3)
	slli	a3,a3,2
	addi	a0,a0,1
	sb	a0,-134(s4)
	add	a0,sp,a3
	addi	a3,a3,144
	sw	s2,0(a0)
	add	a3,a3,sp
	sb	a4,-136(a3)
	sb	zero,-133(a3)
	j	.L30
.L42:
	addi	a4,s2,1
	andi	a4,a4,0xff
	j	.L26
.L28:
	lhu	s2,-144(a3)
	lhu	s3,-142(a3)
	sh	s2,-140(a3)
	j	.L29
.L31:
	addi	a6,a6,1
	andi	a6,a6,0xff
	bne	a6,s0,.L15
.L33:
	lw	s0,172(sp)
	lw	s1,168(sp)
	lw	s2,164(sp)
	lw	s3,160(sp)
	lw	s4,156(sp)
	lw	s5,152(sp)
	li	a0,0
	addi	sp,sp,176
	jr	ra
.L4:
	slli	a5,t2,1
	slli	a5,a5,16
	srli	a5,a5,16
	j	.L11
.L20:
	sb	a6,0(s1)
	lw	s0,172(sp)
	lw	s1,168(sp)
	lw	s2,164(sp)
	lw	s3,160(sp)
	lw	s4,156(sp)
	lw	s5,152(sp)
	li	a0,1
	addi	sp,sp,176
	jr	ra
	.size	solve_stage3, .-solve_stage3
	.section	.rodata
	.align	2
	.set	.LANCHOR0,. + 0
	.type	permutation, @object
	.size	permutation, 12
permutation:
	.word	perm_R
	.word	perm_B
	.word	perm_D
	.type	orientation, @object
	.size	orientation, 12
orientation:
	.word	ori_R
	.word	ori_B
	.word	ori_D
	.ident	"GCC: (13.2.0-11ubuntu1+12) 13.2.0"
