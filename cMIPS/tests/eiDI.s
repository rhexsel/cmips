	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: li  $5, 3
	la  $15, x_IO_BASE_ADDR
	nop
lasso:	ei   $8
	sw   $8, 0($15)  # display old STATUS's value
	nop
	di   $8
	sw   $8, 4($15)  # display old STATUS's value
	addiu $5,$5,-1
	bne $5,$0,lasso
	nop
        nop
	nop
        wait
        nop
	nop
	nop
	.end _start
