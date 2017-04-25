	.file	1 "pt_walk.c"
	.section .mdebug.abi32
	.previous
	.nan	legacy
	.module	fp=32
	.module	nooddspreg
	.text
	.align	2
	.set	nomips16
	.set	nomicromips
	.ent	print_str
	.type	print_str, @function
print_str:
	.frame	$sp,24,$31		# vars= 0, regs= 2/0, args= 16, gp= 0
	.mask	0x80010000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-24
	sw	$31,20($sp)
	sw	$16,16($sp)
	move	$16,$4
	lb	$4,0($4)
	nop
	beq	$4,$0,$L1
	addiu	$16,$16,1

$L3:
	jal	to_stdout
	addiu	$16,$16,1

	lb	$4,-1($16)
	nop
	bne	$4,$0,$L3
	nop

$L1:
	lw	$31,20($sp)
	lw	$16,16($sp)
	j	$31
	addiu	$sp,$sp,24

	.set	macro
	.set	reorder
	.end	print_str
	.size	print_str, .-print_str
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
$LC0:
	.ascii	"\012\011walked\012\000"
	.align	2
$LC1:
	.ascii	"\012\011TLB entry purged\012\012\000"
	.align	2
$LC2:
	.ascii	"\012\011TLB miss\012\012\000"
	.align	2
$LC3:
	.ascii	"\012\011Mod ok\012\000"
	.align	2
$LC4:
	.ascii	"\011addr purged from TLB\012\000"
	.align	2
$LC5:
	.ascii	"\011TLB miss\012\000"
	.align	2
$LC6:
	.ascii	"\011PT purged from TLB\012\000"
	.align	2
$LC7:
	.ascii	"\011wtf?\012\000"
	.align	2
$LC8:
	.ascii	"\011double ok\012\000"
	.align	2
$LC9:
	.ascii	"\011purged\012\000"
	.align	2
$LC10:
	.ascii	"\011seg fault not ok\012\000"
	.text
	.align	2
	.globl	main
	.set	nomips16
	.set	nomicromips
	.ent	main
	.type	main, @function
main:
	.frame	$sp,32,$31		# vars= 0, regs= 3/0, args= 16, gp= 0
	.mask	0x80030000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	li	$3,262144			# 0x40000
	addiu	$3,$3,1024
	move	$2,$0
	li	$4,16			# 0x10
$L7:
	sw	$2,0($3)
	addiu	$2,$2,1
	bne	$2,$4,$L7
	addiu	$3,$3,4096

	addiu	$sp,$sp,-32
	sw	$31,28($sp)
	sw	$17,24($sp)
	sw	$16,20($sp)
	li	$16,262144			# 0x40000
	addiu	$16,$16,1024
	li	$17,327680			# 0x50000
	addiu	$17,$17,1024
$L8:
	lw	$4,0($16)
	jal	print
	addiu	$16,$16,4096

	bne	$16,$17,$L8
	lui	$4,%hi($LC0)

	jal	print_str
	addiu	$4,$4,%lo($LC0)

	li	$4,262144			# 0x40000
	jal	TLB_purge
	ori	$4,$4,0xa000

	bne	$2,$0,$L9
	nop

	lui	$4,%hi($LC1)
	jal	print_str
	addiu	$4,$4,%lo($LC1)

	b	$L20
	li	$6,4739			# 0x1283

$L9:
	lui	$4,%hi($LC2)
	jal	print_str
	addiu	$4,$4,%lo($LC2)

	li	$6,4739			# 0x1283
$L20:
	move	$5,$0
	li	$16,262144			# 0x40000
	jal	PT_update
	ori	$4,$16,0xa000

	li	$6,9			# 0x9
	li	$5,1			# 0x1
	jal	PT_update
	ori	$4,$16,0xa000

	ori	$2,$16,0xa000
	li	$3,153			# 0x99
	sw	$3,0($2)
	jal	print
	li	$4,153			# 0x99

	lui	$4,%hi($LC3)
	jal	print_str
	addiu	$4,$4,%lo($LC3)

	jal	TLB_purge
	ori	$4,$16,0xa400

	bne	$2,$0,$L11
	nop

	lui	$4,%hi($LC4)
	jal	print_str
	addiu	$4,$4,%lo($LC4)

	b	$L12
	nop

$L11:
	lui	$4,%hi($LC5)
	jal	print_str
	addiu	$4,$4,%lo($LC5)

$L12:
	jal	TLB_purge
	li	$4,327680			# 0x50000

	bne	$2,$0,$L13
	nop

	lui	$4,%hi($LC6)
	jal	print_str
	addiu	$4,$4,%lo($LC6)

	b	$L21
	li	$3,136			# 0x88

$L13:
	lui	$4,%hi($LC7)
	jal	print_str
	addiu	$4,$4,%lo($LC7)

	li	$3,136			# 0x88
$L21:
	li	$2,262144			# 0x40000
	ori	$2,$2,0xa400
	sw	$3,0($2)
	jal	print
	li	$4,136			# 0x88

	lui	$4,%hi($LC8)
	jal	print_str
	addiu	$4,$4,%lo($LC8)

	li	$4,327680			# 0x50000
	jal	TLB_purge
	addiu	$4,$4,16384

	bne	$2,$0,$L15
	nop

	lui	$4,%hi($LC9)
	jal	print_str
	addiu	$4,$4,%lo($LC9)

	b	$L22
	li	$6,5379			# 0x1503

$L15:
	lui	$4,%hi($LC5)
	jal	print_str
	addiu	$4,$4,%lo($LC5)

	li	$6,5379			# 0x1503
$L22:
	move	$5,$0
	li	$16,327680			# 0x50000
	jal	PT_update
	addiu	$4,$16,16384

	move	$6,$0
	li	$5,1			# 0x1
	jal	PT_update
	ori	$4,$16,0x4000

	li	$6,5443			# 0x1543
	li	$5,2			# 0x2
	jal	PT_update
	ori	$4,$16,0x4000

	move	$6,$0
	li	$5,3			# 0x3
	jal	PT_update
	ori	$4,$16,0x4000

	ori	$16,$16,0x4000
	li	$2,102			# 0x66
	sw	$2,0($16)
	jal	print
	li	$4,102			# 0x66

	lui	$4,%hi($LC10)
	jal	print_str
	addiu	$4,$4,%lo($LC10)

	jal	to_stdout
	li	$4,10			# 0xa

	lw	$31,28($sp)
	lw	$17,24($sp)
	lw	$16,20($sp)
	j	$31
	addiu	$sp,$sp,32

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.ident	"GCC: (GNU) 5.1.0"
