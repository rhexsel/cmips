	.file	1 "mac_chrono.c"
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
	.frame	$sp,72,$31		# vars= 8, regs= 10/0, args= 24, gp= 0
	.mask	0xc0ff0000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-72
	sw	$31,68($sp)
	sw	$fp,64($sp)
	sw	$23,60($sp)
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
	li	$4,99			# 0x63

	jal	LCDput
	li	$4,77			# 0x4d

	jal	LCDput
	li	$4,73			# 0x49

	jal	LCDput
	li	$4,80			# 0x50

	jal	LCDput
	li	$4,83			# 0x53

	jal	LCDput
	li	$4,32			# 0x20

	jal	LCDput
	li	$4,116			# 0x74

	jal	LCDput
	li	$4,105			# 0x69

	jal	LCDput
	li	$4,109			# 0x6d

	jal	LCDput
	li	$4,101			# 0x65

	jal	LCDput
	li	$4,32			# 0x20

	jal	LCDput
	li	$4,91			# 0x5b

	jal	LCDput
	li	$4,104			# 0x68

	jal	LCDput
	li	$4,101			# 0x65

	jal	LCDput
	li	$4,120			# 0x78

	jal	LCDput
	li	$4,93			# 0x5d

	jal	LCDbotLine
	nop

	lui	$2,%hi(_counter_val)
	sw	$0,%lo(_counter_val)($2)
	sw	$0,24($sp)
	li	$5,1			# 0x1
	li	$4,12451840			# 0xbe0000
	jal	startCounter
	ori	$4,$4,0xbc20

	jal	SWget
	nop

	bne	$2,$0,$L27
	nop

	move	$19,$0
	move	$17,$0
	move	$18,$0
$L33:
	move	$16,$0
	lui	$23,%hi(_counter_val)
	li	$20,1			# 0x1
	li	$21,60			# 0x3c
	b	$L3
	li	$fp,11			# 0xb

$L27:
	jal	print_status
	move	$19,$0

	jal	LCDint
	move	$4,$2

	jal	delay_ms
	li	$4,2000			# 0x7d0

	jal	print_cause
	move	$17,$0

	jal	LCDint
	move	$4,$2

	jal	delay_ms
	li	$4,2000			# 0x7d0

	b	$L33
	move	$18,$0

$L4:
	jal	delay_us
	move	$4,$20

	b	$L3
	nop

$L6:
	move	$22,$fp
$L8:
	addiu	$16,$16,1
	sll	$2,$16,2
	sw	$2,16($sp)
	move	$7,$0
	move	$6,$0
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	li	$5,2			# 0x2
	jal	LCDgotoxy
	move	$4,$20

	jal	LCDput
	move	$4,$22

	beq	$18,$21,$L28
	nop

$L9:
	beq	$17,$21,$L29
	nop

$L10:
	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,4			# 0x4

	sra	$4,$19,4
	andi	$4,$4,0xf
	slt	$2,$4,10
	beq	$2,$0,$L11
	nop

	addiu	$4,$4,48
$L12:
	jal	LCDput
	nop

	andi	$4,$19,0xf
	slt	$2,$4,10
	beq	$2,$0,$L13
	nop

	addiu	$4,$4,48
$L14:
	jal	LCDput
	nop

	jal	LCDput
	li	$4,58			# 0x3a

	sra	$4,$17,4
	andi	$4,$4,0xf
	slt	$2,$4,10
	beq	$2,$0,$L15
	nop

	addiu	$4,$4,48
$L16:
	jal	LCDput
	nop

	andi	$4,$17,0xf
	slt	$2,$4,10
	beq	$2,$0,$L17
	nop

	addiu	$4,$4,48
$L18:
	jal	LCDput
	nop

	jal	LCDput
	li	$4,58			# 0x3a

	sra	$4,$18,4
	andi	$4,$4,0xf
	slt	$2,$4,10
	beq	$2,$0,$L19
	nop

	addiu	$4,$4,48
$L20:
	jal	LCDput
	nop

	andi	$4,$18,0xf
	slt	$2,$4,10
	beq	$2,$0,$L21
	nop

	addiu	$4,$4,48
$L22:
	jal	LCDput
	nop

$L3:
	lw	$3,24($sp)
	lw	$2,%lo(_counter_val)($23)
	nop
	beq	$3,$2,$L4
	nop

	sw	$2,24($sp)
	beq	$16,$20,$L6
	li	$2,2			# 0x2

	beq	$16,$2,$L7
	nop

	beq	$16,$0,$L30
	nop

	addiu	$18,$18,1
	li	$22,10			# 0xa
	b	$L8
	li	$16,-1			# 0xffffffffffffffff

$L7:
	b	$L8
	li	$22,12			# 0xc

$L30:
	b	$L8
	li	$22,9			# 0x9

$L28:
	addiu	$17,$17,1
	b	$L9
	move	$18,$0

$L29:
	addiu	$19,$19,1
	b	$L10
	move	$17,$0

$L11:
	b	$L12
	addiu	$4,$4,87

$L13:
	b	$L14
	addiu	$4,$4,87

$L15:
	b	$L16
	addiu	$4,$4,87

$L17:
	b	$L18
	addiu	$4,$4,87

$L19:
	b	$L20
	addiu	$4,$4,87

$L21:
	b	$L22
	addiu	$4,$4,87

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.ident	"GCC: (GNU) 6.3.0"
