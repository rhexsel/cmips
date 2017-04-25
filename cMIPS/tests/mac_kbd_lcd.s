	.file	1 "mac_kbd_lcd.c"
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
	.frame	$sp,56,$31		# vars= 8, regs= 7/0, args= 16, gp= 0
	.mask	0x803f0000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-56
	sw	$31,52($sp)
	sw	$21,48($sp)
	sw	$20,44($sp)
	sw	$19,40($sp)
	sw	$18,36($sp)
	sw	$17,32($sp)
	jal	LCDinit
	sw	$16,28($sp)

	jal	LCDtopLine
	move	$17,$0

	jal	LCDput
	li	$4,32			# 0x20

	jal	LCDput
	li	$4,72			# 0x48

	jal	LCDput
	li	$4,101			# 0x65

	jal	LCDput
	li	$4,108			# 0x6c

	jal	LCDput
	li	$4,108			# 0x6c

	jal	LCDput
	li	$4,111			# 0x6f

	jal	LCDput
	li	$4,32			# 0x20

	jal	LCDput
	li	$4,119			# 0x77

	jal	LCDput
	li	$4,111			# 0x6f

	jal	LCDput
	li	$4,114			# 0x72

	jal	LCDput
	li	$4,108			# 0x6c

	jal	LCDput
	li	$4,100			# 0x64

	jal	LCDput
	li	$4,33			# 0x21

	jal	LCDbotLine
	li	$16,-1			# 0xffffffffffffffff

	li	$18,11			# 0xb
	li	$21,35			# 0x23
	li	$19,15			# 0xf
	b	$L2
	li	$20,48			# 0x30

$L4:
$L6:
	jal	LCDput
	addiu	$17,$17,1

	jal	LCDput
	li	$4,32			# 0x20

	li	$2,5			# 0x5
	beq	$17,$2,$L13
	move	$5,$0

$L7:
	jal	delay_ms
	li	$4,500			# 0x1f4

$L2:
	jal	KBDget
	nop

	sw	$2,16($sp)
	beq	$2,$16,$L2
	nop

	lw	$2,16($sp)
	nop
	beq	$2,$18,$L4
	move	$4,$21

	beq	$2,$19,$L5
	li	$3,10			# 0xa

	beq	$2,$3,$L14
	nop

	lw	$4,16($sp)
	b	$L6
	addiu	$4,$4,48

$L5:
	b	$L6
	move	$4,$20

$L14:
	b	$L6
	li	$4,42			# 0x2a

$L13:
	jal	LCDgotoxy
	li	$4,1			# 0x1

	b	$L7
	move	$17,$0

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.ident	"GCC: (GNU) 6.3.0"
