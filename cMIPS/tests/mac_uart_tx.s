	.file	1 "mac_uart_tx.c"
	.section .mdebug.abi32
	.previous
	.nan	legacy
	.module	fp=32
	.module	nooddspreg
	.text
	.align	2
	.globl	main
	.set	nomips16
	.set	nomicromips
	.ent	main
	.type	main, @function
main:
	.frame	$sp,64,$31		# vars= 8, regs= 8/0, args= 24, gp= 0
	.mask	0x807f0000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-64
	sw	$31,60($sp)
	sw	$22,56($sp)
	sw	$21,52($sp)
	sw	$20,48($sp)
	sw	$19,44($sp)
	sw	$18,40($sp)
	sw	$17,36($sp)
	jal	LCDinit
	sw	$16,32($sp)

	jal	LCDtopLine
	nop

	jal	LCDput
	li	$4,32			# 0x20

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
	li	$19,100			# 0x64
	li	$17,48			# 0x30
	move	$18,$0
	li	$16,1006632960			# 0x3c000000
	move	$20,$0
	li	$21,10			# 0xa
	b	$L2
	li	$22,48			# 0x30

$L24:
	lw	$2,228($16)
	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,11			# 0xb

	jal	LCDputc
	move	$4,$17

	b	$L3
	nop

$L5:
	sw	$21,228($16)
	jal	delay_us
	li	$4,2500			# 0x9c4

	move	$17,$22
	move	$18,$0
$L4:
	addiu	$19,$19,-1
	beq	$19,$0,$L23
	nop

$L2:
	jal	delay_us
	li	$4,1			# 0x1

	lw	$2,224($16)
	nop
	sw	$2,24($sp)
	lw	$2,24($sp)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	beq	$2,$0,$L2
	nop

	sw	$17,228($16)
	lw	$4,24($sp)
	nop
	srl	$4,$4,6
	lw	$6,24($sp)
	nop
	srl	$6,$6,5
	sw	$0,16($sp)
	move	$7,$0
	andi	$6,$6,0x1
	move	$5,$0
	jal	DSP7SEGput
	andi	$4,$4,0x1

	li	$5,1			# 0x1
	jal	LCDgotoxy
	li	$4,8			# 0x8

	jal	LCDbyte
	move	$4,$20

	li	$5,1			# 0x1
	jal	LCDgotoxy
	li	$4,11			# 0xb

	jal	LCDputc
	move	$4,$17

	addiu	$18,$18,1
	addiu	$17,$17,1
	sll	$17,$17,24
	sra	$17,$17,24
	jal	delay_us
	li	$4,2500			# 0x9c4

	lw	$2,24($sp)
	nop
	srl	$2,$2,5
	andi	$2,$2,0x1
	bne	$2,$0,$L24
	nop

$L3:
	bne	$18,$21,$L4
	nop

	lw	$2,224($16)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	bne	$2,$0,$L5
	nop

$L15:
	jal	delay_us
	li	$4,1			# 0x1

	lw	$2,224($16)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	beq	$2,$0,$L15
	nop

	b	$L5
	nop

$L23:
	li	$19,100			# 0x64
	li	$17,97			# 0x61
	move	$18,$0
	li	$16,1006632960			# 0x3c000000
	li	$21,10			# 0xa
	b	$L8
	li	$22,97			# 0x61

$L26:
	lw	$2,228($16)
	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,11			# 0xb

	jal	LCDputc
	move	$4,$17

	b	$L9
	nop

$L11:
	sw	$21,228($16)
	jal	delay_us
	li	$4,5			# 0x5

	move	$17,$22
	move	$18,$0
$L10:
	addiu	$19,$19,-1
	beq	$19,$0,$L25
	nop

$L8:
	jal	delay_us
	li	$4,1			# 0x1

	lw	$2,224($16)
	nop
	sw	$2,24($sp)
	lw	$2,24($sp)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	beq	$2,$0,$L8
	nop

	sw	$17,228($16)
	lw	$4,24($sp)
	nop
	srl	$4,$4,6
	lw	$6,24($sp)
	nop
	srl	$6,$6,5
	sw	$0,16($sp)
	move	$7,$0
	andi	$6,$6,0x1
	move	$5,$0
	jal	DSP7SEGput
	andi	$4,$4,0x1

	li	$5,1			# 0x1
	jal	LCDgotoxy
	li	$4,8			# 0x8

	jal	LCDbyte
	move	$4,$20

	li	$5,1			# 0x1
	jal	LCDgotoxy
	li	$4,11			# 0xb

	jal	LCDputc
	move	$4,$17

	addiu	$18,$18,1
	addiu	$17,$17,1
	sll	$17,$17,24
	sra	$17,$17,24
	jal	delay_us
	li	$4,5			# 0x5

	lw	$2,24($sp)
	nop
	srl	$2,$2,5
	andi	$2,$2,0x1
	bne	$2,$0,$L26
	nop

$L9:
	bne	$18,$21,$L10
	nop

	lw	$2,224($16)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	bne	$2,$0,$L11
	nop

$L14:
	jal	delay_us
	li	$4,1			# 0x1

	lw	$2,224($16)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	beq	$2,$0,$L14
	nop

	b	$L11
	nop

$L25:
	jal	exit
	move	$4,$0

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.ident	"GCC: (GNU) 6.3.0"
