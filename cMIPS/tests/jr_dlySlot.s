	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: la $16, x_IO_BASE_ADDR
	la $20, (dsv+4)
	li $3,1
	li $5,10
	li $6,5
snd:	sw    $5, 0($16)
	addiu $5,$5, -1
dsv:	beq   $5,$6, L1
	j     snd
	nop
L1:	addiu $6,$6,-1
	li    $5,10
	beq   $6,$zero,end
	jr   $20
	#j     (dsv+4)
	nop
end:	nop
	nop
	wait
	nop
	.end _start
