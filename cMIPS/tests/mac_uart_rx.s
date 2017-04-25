	.file	1 "mac_uart_rx.c"
	.section .mdebug.abi32
	.previous
	.nan	legacy
	.module	fp=32
	.module	nooddspreg
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.set	nomips16
	.set	nomicromips
	.ent	main
	.type	main, @function
main:
	.frame	$sp,56,$31		# vars= 8, regs= 6/0, args= 24, gp= 0
	.mask	0x801f0000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-56
	sw	$31,52($sp)
	sw	$19,44($sp)
	sw	$16,32($sp)
	sw	$20,48($sp)
	sw	$18,40($sp)
	jal	LCDinit
	sw	$17,36($sp)

	jal	LCDtopLine
	nop

	jal	LCDput
	li	$4,99			# 0x63

	jal	LCDput
	li	$4,77			# 0x4d

	jal	LCDput
	li	$4,73			# 0x49

	jal	LCDput
	li	$4,80			# 0x50

	jal	LCDput
	li	$4,83			# 0x53

	li	$2,1006632960			# 0x3c000000
	li	$3,135			# 0x87
	sw	$3,224($2)
	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,1			# 0x1

	li	$16,1006632960			# 0x3c000000
	li	$19,15			# 0xf
	li	$18,1			# 0x1
$L2:
$L17:
	jal	delay_us
	li	$4,1			# 0x1

	lw	$2,224($16)
	nop
	sw	$2,24($sp)
	lw	$2,24($sp)
	nop
	srl	$2,$2,5
	andi	$2,$2,0x1
	beq	$2,$0,$L2
	nop

	lw	$20,228($16)
	lw	$17,24($sp)
	lw	$5,24($sp)
	lw	$3,24($sp)
	lw	$2,24($sp)
	lw	$4,24($sp)
	andi	$5,$5,0x40
	andi	$17,$17,0x80
	andi	$4,$4,0x1
	or	$17,$17,$5
	andi	$3,$3,0x20
	or	$17,$17,$4
	or	$17,$17,$3
	andi	$2,$2,0x2
	li	$5,1			# 0x1
	or	$17,$17,$2
	jal	LCDgotoxy
	li	$4,8			# 0x8

	jal	LCDput
	move	$4,$17

	lw	$2,24($sp)
	sll	$20,$20,24
	srl	$2,$2,1
	andi	$2,$2,0x1
	sra	$20,$20,24
	li	$5,1			# 0x1
	bne	$2,$0,$L3
	li	$4,11			# 0xb

	lw	$2,24($sp)
	nop
	andi	$2,$2,0x1
	beq	$2,$0,$L4
	nop

$L3:
	jal	LCDgotoxy
	nop

	jal	LCDput
	move	$4,$17

	lw	$4,24($sp)
	lw	$5,24($sp)
	lw	$6,24($sp)
	lw	$7,24($sp)
	srl	$4,$4,6
	srl	$5,$5,1
	srl	$6,$6,5
	andi	$7,$7,0x1
	andi	$6,$6,0x1
	andi	$5,$5,0x1
	andi	$4,$4,0x1
	jal	DSP7SEGput
	sw	$0,16($sp)

$L4:
	move	$4,$18
	jal	LCDgotoxy
	li	$5,2			# 0x2

	addiu	$18,$18,1
	jal	LCDputc
	move	$4,$20

	bne	$18,$19,$L2
	nop

	jal	delay_ms
	li	$4,1000			# 0x3e8

	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,1			# 0x1

	li	$17,14			# 0xe
	addiu	$17,$17,-1
$L18:
	jal	LCDputc
	li	$4,32			# 0x20

	bne	$17,$0,$L18
	addiu	$17,$17,-1

	addiu	$17,$17,1
	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,1			# 0x1

	b	$L17
	li	$18,1			# 0x1

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.ident	"GCC: (GNU) 6.3.0"
