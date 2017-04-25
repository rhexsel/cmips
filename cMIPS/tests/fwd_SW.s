	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: nop
	la   $15,x_IO_BASE_ADDR
	addi $3,$0,1
	addi $9,$0,20
	move $4,$zero
	nop
snd:	nop
	add  $4,$4,$3
	nop
	nop
	nop
	sw   $0, 0($15)
	nop
	nop
	slt $8,$4,$9
	bne $8,$0,snd
	nop
	wait
	nop
	.end _start
