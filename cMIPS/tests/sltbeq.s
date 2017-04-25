	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: la $15,(x_IO_BASE_ADDR+0x10)
	addi $9,$0,6
	addi $3,$0,1
	move $4,$zero
	nop
snd:	add  $4,$4,$3   # $4 + 1      $4 <- 1,2,3,4,5,6
	sw   $4, -16($15)
	nop
	slt $1,$4,$9
	bne $0,$1,snd
	nop
	nop
	nop
	nop
	wait
	.end _start
