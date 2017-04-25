	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: nop
	la   $15,x_DATA_BASE_ADDR
        la   $16,x_IO_BASE_ADDR
	li   $3,1
	li   $4,2
	li   $22,40
incr:	mult $3,$4
	mflo $5
	addiu $15,$15,4
	sw   $5, 0($15) # ram[0]=2,4,6,8,...,x20,x22,x24,x26,x28
	addi $3,$3,1
	sw   $5, 0($16)
	lw   $7,0($15)
	bne  $22,$7,incr 
	nop
	nop
	nop
	nop
	wait
	.end _start

