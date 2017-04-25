	.file	1 "mac_sdcard.c"
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
	.frame	$sp,56,$31		# vars= 0, regs= 7/0, args= 24, gp= 0
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
	sw	$16,28($sp)
	li	$16,16			# 0x10
	li	$17,1006632960			# 0x3c000000
	sw	$16,392($17)
	jal	delay_cycle
	move	$4,$0

	jal	LCDinit
	nop

	jal	LCDtopLine
	nop

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
	nop

	jal	delay_ms
	li	$4,1000			# 0x3e8

	lw	$4,396($17)
	jal	LCDint
	nop

	jal	delay_ms
	li	$4,1000			# 0x3e8

	jal	delay_ms
	li	$4,1000			# 0x3e8

	lw	$2,396($17)
	nop
	bgez	$2,$L27
	li	$2,1006632960			# 0x3c000000

	li	$17,2			# 0x2
	li	$19,1006632960			# 0x3c000000
$L18:
	jal	delay_cycle
	move	$4,$0

	sw	$17,16($sp)
	li	$7,4			# 0x4
	move	$6,$0
	li	$5,4			# 0x4
	jal	DSP7SEGput
	move	$4,$0

	move	$5,$17
	jal	LCDgotoxy
	li	$4,1			# 0x1

	jal	LCDput
	li	$4,114			# 0x72

	jal	LCDput
	li	$4,115			# 0x73

	jal	LCDput
	li	$4,116			# 0x74

	jal	LCDput
	li	$4,58			# 0x3a

	jal	LCDput
	li	$4,32			# 0x20

	lw	$4,396($19)
	jal	LCDint
	nop

	jal	delay_ms
	li	$4,1000			# 0x3e8

	sw	$0,16($sp)
	li	$7,4			# 0x4
	move	$6,$0
	li	$5,4			# 0x4
	jal	DSP7SEGput
	move	$4,$0

	jal	delay_ms
	li	$4,250			# 0xfa

	lw	$2,396($19)
	nop
	bltz	$2,$L18
	li	$2,1006632960			# 0x3c000000

$L27:
	addiu	$2,$2,384
	lw	$2,12($2)
	nop
	bgez	$2,$L4
	li	$2,1006632960			# 0x3c000000

	addiu	$2,$2,384
	lw	$2,12($2)
	nop
	bgez	$2,$L6
	nop

	li	$17,4			# 0x4
	li	$21,1006632960			# 0x3c000000
	li	$20,-3			# 0xfffffffffffffffd
	li	$19,-2			# 0xfffffffffffffffe
$L17:
	sw	$17,16($sp)
	move	$7,$17
	move	$6,$0
	move	$5,$17
	jal	DSP7SEGput
	move	$4,$0

	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,1			# 0x1

	jal	LCDput
	li	$4,101			# 0x65

	jal	LCDput
	li	$4,114			# 0x72

	jal	LCDput
	li	$4,114			# 0x72

	jal	LCDput
	li	$4,58			# 0x3a

	jal	LCDput
	li	$4,32			# 0x20

	lw	$4,396($21)
	jal	LCDint
	ori	$16,$16,0x10

	jal	delay_ms
	li	$4,1000			# 0x3e8

	and	$16,$16,$20
	and	$16,$16,$19
	sw	$16,392($21)
	jal	delay_cycle
	move	$4,$0

	sw	$0,16($sp)
	move	$7,$17
	move	$6,$0
	move	$5,$17
	jal	DSP7SEGput
	move	$4,$0

	jal	delay_ms
	li	$4,1000			# 0x3e8

	jal	delay_ms
	li	$4,1000			# 0x3e8

	lw	$2,396($21)
	nop
	bltz	$2,$L17
	nop

$L6:
	sw	$0,16($sp)
	li	$7,4			# 0x4
	move	$6,$0
	li	$5,4			# 0x4
	jal	DSP7SEGput
	move	$4,$0

	li	$16,1006632960			# 0x3c000000
$L14:
	jal	delay_ms
	li	$4,1000			# 0x3e8

	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,8			# 0x8

	lw	$4,396($16)
	jal	LCDint
	nop

	b	$L14
	nop

$L4:
	addiu	$17,$2,384
	sw	$0,384($2)
	li	$2,-17			# 0xffffffffffffffef
	and	$16,$16,$2
	ori	$16,$16,0x2
	li	$2,-2			# 0xfffffffffffffffe
	and	$16,$16,$2
	sw	$16,8($17)
	jal	delay_cycle
	li	$4,1			# 0x1

	lw	$2,12($17)
	nop
	bltz	$2,$L28
	move	$16,$0

	li	$16,1006632960			# 0x3c000000
$L16:
	jal	delay_cycle
	li	$4,1			# 0x1

	lw	$2,396($16)
	nop
	bgez	$2,$L16
	nop

	move	$16,$0
$L28:
	li	$19,1006632960			# 0x3c000000
	b	$L12
	li	$18,512			# 0x200

$L9:
	lw	$4,388($19)
	jal	LCDbyte
	andi	$4,$4,0x00ff

	lw	$2,396($19)
	nop
	bgez	$2,$L25
	addiu	$16,$16,1

	beq	$16,$18,$L26
	li	$2,1			# 0x1

$L12:
	andi	$2,$16,0xf
	bne	$2,$0,$L9
	li	$5,1			# 0x1

	jal	LCDgotoxy
	li	$4,1			# 0x1

	b	$L9
	nop

$L25:
	li	$2,2			# 0x2
	sw	$2,16($sp)
	li	$7,12			# 0xc
	move	$6,$0
	li	$5,12			# 0xc
	jal	DSP7SEGput
	move	$4,$0

	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,1			# 0x1

	jal	LCDput
	li	$4,101			# 0x65

	jal	LCDput
	li	$4,114			# 0x72

	jal	LCDput
	li	$4,114			# 0x72

	jal	LCDput
	li	$4,58			# 0x3a

	jal	LCDput
	li	$4,32			# 0x20

	li	$2,1006632960			# 0x3c000000
	lw	$4,396($2)
	jal	LCDint
	nop

$L11:
	jal	delay_ms
	li	$4,1000			# 0x3e8

	b	$L11
	nop

$L26:
	sw	$2,16($sp)
	move	$7,$0
	move	$6,$0
	move	$5,$0
	jal	DSP7SEGput
	move	$4,$0

	li	$5,2			# 0x2
	jal	LCDgotoxy
	li	$4,1			# 0x1

	jal	LCDput
	li	$4,79			# 0x4f

	jal	LCDput
	li	$4,75			# 0x4b

	jal	LCDput
	li	$4,58			# 0x3a

	jal	LCDput
	li	$4,32			# 0x20

	li	$2,1006632960			# 0x3c000000
	lw	$4,396($2)
	jal	LCDint
	nop

$L15:
	jal	delay_ms
	li	$4,1000			# 0x3e8

	b	$L15
	nop

	.set	macro
	.set	reorder
	.end	main
	.size	main, .-main
	.ident	"GCC: (GNU) 6.3.0"
