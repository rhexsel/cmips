	.file	1 "mac_uart_lb.c"
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
	.frame	$sp,48,$31		# vars= 0, regs= 6/0, args= 24, gp= 0
	.mask	0x801f0000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-48
	sw	$31,44($sp)
	sw	$20,40($sp)
	sw	$19,36($sp)
	sw	$18,32($sp)
	sw	$17,28($sp)
	jal	LCDinit
	sw	$16,24($sp)

	jal	LCDclr
	nop

	li	$2,1			# 0x1
	sw	$2,16($sp)
	move	$7,$0
	move	$6,$0
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	jal	delay_ms
	li	$4,2000			# 0x7d0

	jal	LCDtopLine
	nop

	jal	LCDput
	li	$4,32			# 0x20

	jal	LCDput
	li	$4,108			# 0x6c

	jal	LCDput
	li	$4,111			# 0x6f

	jal	LCDput
	li	$4,111			# 0x6f

	jal	LCDput
	li	$4,112			# 0x70

	jal	LCDput
	li	$4,45			# 0x2d

	jal	LCDput
	li	$4,98			# 0x62

	jal	LCDput
	li	$4,97			# 0x61

	jal	LCDput
	li	$4,99			# 0x63

	jal	LCDput
	li	$4,107			# 0x6b

	jal	LCDput
	li	$4,63			# 0x3f

	jal	LCDput
	li	$4,32			# 0x20

	li	$2,1006632960			# 0x3c000000
	li	$3,7			# 0x7
	sw	$3,224($2)
	lw	$16,224($2)
	nop
	srl	$16,$16,5
	andi	$16,$16,0x1
	li	$5,1			# 0x1
	jal	LCDgotoxy
	li	$4,14			# 0xe

	jal	LCDbyte
	move	$4,$16

	li	$2,4			# 0x4
	sw	$2,16($sp)
	move	$7,$0
	move	$6,$16
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	li	$17,48			# 0x30
	li	$16,1006632960			# 0x3c000000
	li	$19,48			# 0x30
	b	$L13
	li	$18,58			# 0x3a

$L17:
	jal	LCDgotoxy
	li	$4,1			# 0x1

	lw	$2,224($16)
	nop
	srl	$2,$2,5
	andi	$2,$2,0x1
	bne	$2,$0,$L15
	move	$20,$0

$L20:
	addiu	$20,$20,1
$L18:
	andi	$2,$20,0x7
	sw	$2,16($sp)
	move	$7,$0
	move	$6,$0
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	lw	$2,224($16)
	nop
	srl	$2,$2,5
	andi	$2,$2,0x1
	beq	$2,$0,$L18
	addiu	$20,$20,1

$L7:
	lw	$20,228($16)
	nop
	sll	$4,$20,24
	jal	LCDputc
	sra	$4,$4,24

	andi	$20,$20,0x7
	sw	$20,16($sp)
	move	$7,$0
	li	$6,1			# 0x1
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	addiu	$17,$17,1
	beq	$17,$18,$L16
	li	$2,1006632960			# 0x3c000000

$L13:
	lw	$2,224($16)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	bne	$2,$0,$L2
	nop

	move	$20,$0
	addiu	$20,$20,1
$L19:
	li	$5,1			# 0x1
	jal	LCDgotoxy
	li	$4,14			# 0xe

	jal	LCDbyte
	move	$4,$0

	andi	$2,$20,0x7
	sw	$2,16($sp)
	move	$7,$0
	move	$6,$0
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	lw	$2,224($16)
	nop
	srl	$2,$2,6
	andi	$2,$2,0x1
	beq	$2,$0,$L19
	addiu	$20,$20,1

	addiu	$20,$20,-1
$L2:
	sw	$17,228($16)
	beq	$17,$19,$L17
	li	$5,2			# 0x2

	lw	$2,224($16)
	nop
	srl	$2,$2,5
	andi	$2,$2,0x1
	beq	$2,$0,$L20
	move	$20,$0

	b	$L7
	nop

$L16:
	lw	$4,224($2)
	li	$2,2			# 0x2
	sw	$2,16($sp)
	move	$7,$0
	andi	$6,$4,0xf
	move	$5,$0
	jal	DSP7SEGput
	sra	$4,$4,4

$L10:
	jal	delay_us
	li	$4,1			# 0x1

	b	$L10
	nop

$L15:
	lw	$20,228($16)
	nop
	sll	$4,$20,24
	jal	LCDputc
	sra	$4,$4,24

	andi	$20,$20,0x7
	sw	$20,16($sp)
	move	$7,$0
	li	$6,1			# 0x1
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	b	$L13
	addiu	$17,$17,1

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.ident	"GCC: (GNU) 6.3.0"
